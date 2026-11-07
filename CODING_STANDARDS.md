# CRMDatabaseMS Coding Standards & Best Practices

This document is the complete, self-contained specification of both the **Universal Coding Standards** and the **Microsoft SQL Server 2022, SSDT (`Microsoft.Build.Sql`), DACPAC, T-SQL, Python, and Bash Standards** for the **CRMDatabaseMS** repository.

---

# Part I: Universal Coding Standards

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Universal Standards Pillars                     │
├───────────────────┬───────────────────┬────────────────────────────────┤
│  Functional First │ Immutable Always  │ Explicit Side Effects          │
│  Maps over Loops  │ Records & Freezes │ Command/Query Segregation     │
├───────────────────┴──────┬────────────┴────────────────────────────────┤
│  Helper & Extension Fns  │ Zero Magic Numbers & Anti-Pattern Tolerance │
└──────────────────────────┴─────────────────────────────────────────────┘
```

## 1. Core Universal Principles

1. **Functional & Set-Based Logic Over Imperative Loops**:
   - Choose declarative set-based transformations (`SELECT ... FROM ... JOIN`, Tally CTEs, window functions, Python comprehensions/`map()`/`next()`) over state-mutating imperative loops (`CURSOR`, `WHILE`, mutable `for` accumulators).
   - **Acceptable Exceptions for Loops**: Chunked database batch maintenance (e.g. deleting 5,000 rows per iteration to prevent transaction log expansion) or bounded process-readiness polling in container entrypoints. Every exception loop must include an inline comment explaining why a declarative construct was not used.
2. **Immutability by Default**:
   - Database tables enforce immutable historical audit metadata (`CreatedDate`, `CreatedById`, `IsDeleted` soft-deletes).
   - Python test harness configurations use `@dataclass(frozen=True)` and `tuple` constants rather than mutable lists or dicts.
3. **Explicit Demarcation of Side Effects (Command-Query Segregation)**:
   - **Queries (Pure / Read-Only)**: Views, inline Table-Valued Functions (iTVFs), and pure Python config/argument builders (`resolve_config`, `build_sqlcmd_command`).
   - **Commands (Side-Effecting)**: Stored procedures (`sp_SeedStandardData`, `sp_SimulateHeavyETLLoad`, `sp_CleanupAllCRMData`) and process runners (`execute_test_suite`, `run_sqlcmd_file`).
4. **Zero Magic Numbers & String Literals**:
   - Declare semantic variables/constants for all batch sizes, scale factors, ports, and retry bounds (`DECLARE @BatchSize INT = 5000;`, `DEFAULT_DB_PORT = "1433"`).
5. **Eliminate Redundancy via Helper Functions**:
   - Consolidate repeated `sqlcmd` binary discovery and execution logic into reusable helper functions (`find_sqlcmd`, `run_sqlcmd_file`, `run_sqlcmd_query`).

---

# Part II: SQL Server / SSDT / T-SQL Specific Standards

## 2. Declarative State-Based Paradigm

### 2.1 Declarative Source of Truth
- Every table, view, index, and constraint is defined in its own `.sql` file representing the **desired end state** (`CREATE TABLE [Salesforce].[Account] ...`).
- Never write ad-hoc imperative transition scripts (`ALTER TABLE`) in source control. The compilation of `.sqlproj` into `CRMDatabaseMS.dacpac` and the deployment engine (`SqlPackage`) automatically generates differential deployment scripts.

### 2.2 Schema Organization
Each CRM data model belongs to its own schema namespace:
- `[Salesforce]`: 15 tables modeling Sales Cloud entities.
- `[HubSpot]`: 11 tables modeling HubSpot CRM object entities.
- `[Dynamics365]`: 11 tables modeling Dataverse Common Data Model entities.

### 2.3 File & Folder Naming
Follow the SSDT project convention (PascalCase), with each language's own default for tooling files:
- **Object files** are named after the object they define and live in a PascalCase folder per schema and object type (`Salesforce/Tables/Account.sql`, `StoredProcedures/sp_SeedStandardData.sql`).
- **Operational and test SQL scripts** use a two-digit run-order prefix followed by `Pascal_Case` words (`Scripts/01_Seed_Standard_50Records.sql`, `Tests/04_Run_All_Tests.sql`).
- **Python and Bash files** keep their language defaults: `snake_case` for Python modules (PEP 8) and lowercase for shell scripts (`Tests/run_tests.py`, `entrypoint.sh`).
- **One copy per script**: seed and cleanup scripts live only in the root `Scripts/` folder. `CRMDatabaseMS.sqlproj` lists them as `None` items (`..\Scripts\**\*.sql`) so they show in the project without being compiled into the DACPAC.

---

## 3. Set-Based Logic Over Procedural Loops

### 3.1 Set-Based Transformations & Tally CTEs Over Cursors
Never use `CURSOR` or iterative `WHILE` loops to transform or insert data. Utilize set-based statements (`INSERT ... SELECT`, `UPDATE ... FROM`), Common Table Expressions (CTEs), window functions (`ROW_NUMBER() OVER (...)`), and `CROSS APPLY`.

```sql
-- ❌ ANTI-PATTERN: Cursor / RBAR (Row-By-Agonizing-Row) processing
DECLARE @AccountId NVARCHAR(18), @AnnualRevenue DECIMAL(18,2);
DECLARE cur CURSOR FOR SELECT Id, AnnualRevenue FROM Salesforce.Account;
-- ... FETCH NEXT ... WHILE @@FETCH_STATUS = 0 ...

-- ✅ BEST PRACTICE: Declarative set-based statement
UPDATE Salesforce.Account
SET AnnualRevenue = AnnualRevenue * 1.10
WHERE AnnualRevenue IS NOT NULL AND IsDeleted = 0;
```

### 3.2 Acceptable Exception: Chunked Batch Maintenance
Iterative `WHILE` loops are acceptable **only** for chunked batch maintenance where a single massive transaction would overflow the transaction log:
```sql
DECLARE @RowsAffected INT = 1;
DECLARE @BatchSize INT = 5000;

WHILE @RowsAffected > 0
BEGIN
    DELETE TOP (@BatchSize) FROM Salesforce.Task
    WHERE IsDeleted = 1 AND CreatedDate < DATEADD(YEAR, -5, SYSUTCDATETIME());
    SET @RowsAffected = @@ROWCOUNT;
END;
```

---

## 4. Immutability, Determinism & Audit Trails

### 4.1 Audit Trails and Soft-Delete Immutability
All enterprise tables enforce audit tracking:
```sql
[CreatedDate]      DATETIME2(7)  NOT NULL CONSTRAINT [DF_Table_CreatedDate] DEFAULT (SYSUTCDATETIME()),
[CreatedById]      NVARCHAR(20)  NOT NULL,
[LastModifiedDate] DATETIME2(7)  NOT NULL CONSTRAINT [DF_Table_LastModifiedDate] DEFAULT (SYSUTCDATETIME()),
[LastModifiedById] NVARCHAR(20)  NOT NULL,
[IsDeleted]        BIT           NOT NULL CONSTRAINT [DF_Table_IsDeleted] DEFAULT (0)
```

### 4.2 Schema-Bound Deterministic Functions
User-defined scalar and inline table-valued functions must declare `WITH SCHEMABINDING` to guarantee deterministic evaluation and allow query optimizer inlining.

---

## 5. Explicit Demarcation of Side Effects & Transaction Safety

### 5.1 Stored Procedures vs. Views / Functions
- **Read-Only Data Access**: Must use `VIEW` or inline Table-Valued Functions (iTVFs).
- **Side-Effecting Operations**: Data seeding, bulk ETL simulation, and cleanup must be encapsulated in Stored Procedures (`[dbo].[sp_SeedStandardData]`, `[dbo].[sp_SimulateHeavyETLLoad]`, `[dbo].[sp_CleanupAllCRMData]`).

### 5.2 Explicit Transaction Management (`XACT_ABORT` & `THROW`)
All mutating stored procedures must declare `SET NOCOUNT ON;`, `SET XACT_ABORT ON;`, explicit transactions, and modern `THROW;` inside `BEGIN CATCH`:
```sql
CREATE PROCEDURE [dbo].[sp_CleanupAllCRMData]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Roll back immediately on run-time or timeout error

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Side-effecting operations here
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW; -- Preserves original error number and line
    END CATCH
END;
```

---

## 6. Elimination of Magic Numbers & Explicit Data Types

- Always declare named semantic variables for limits, scale factors, and timeouts (`DECLARE @DefaultPageSize INT = 50;`).
- Never define data types without explicit lengths or scales:
  - ❌ `VARCHAR`, `NVARCHAR`, `DECIMAL`
  - ✅ `NVARCHAR(100)`, `VARCHAR(255)`, `DECIMAL(18, 2)`

---

## 7. Anti-Pattern & Common Mistakes Catalog for SQL Server

1. **`SELECT *` in Production Code**: Breaks when schemas evolve and prevents covering index usage. Always specify explicit column lists.
2. **Non-SARGable Query Predicates**: Wrapping indexed columns in functions in `WHERE` clauses (`WHERE YEAR(CreatedDate) = 2026`) forces full table scans. Use range predicates (`WHERE CreatedDate >= '2026-01-01' AND CreatedDate < '2027-01-01'`).
3. **Indiscriminate Use of `WITH (NOLOCK)`**: Causes dirty reads and allocation scan errors. Use `READ COMMITTED` or `READ_COMMITTED_SNAPSHOT`.
4. **Missing Indexes on Foreign Keys**: Causes table locks and full scans during parent updates/deletes. Index all referencing foreign key columns.
5. **Legacy `RAISERROR` Instead of `THROW` & Missing `XACT_ABORT`**: `RAISERROR` masks original error numbers as `50000`; omitting `SET XACT_ABORT ON` risks orphaned transactions on timeouts.

---

## 8. Python & Shell Test Harness & Pre-Commit Standards

- **Python (`Tests/run_tests.py`)**: Zero-dependency, `from __future__ import annotations`, `@dataclass(frozen=True)` (`MsSqlConfig`), `tuple` constants, pure `build_sqlcmd_command`, and functional `next(...)` binary resolution.
- **Bash (`Tests/run_tests.sh`, `entrypoint.sh`)**: Enforces `set -euo pipefail`, `readonly` constants, and reusable `find_sqlcmd` / `run_sqlcmd_file` / `run_sqlcmd_query` helper functions.
- **Pre-Commit Auto-Formatting**: On every `git commit`, the installed pre-commit hook automatically formats staged files, removes unused Python imports, validates `py_compile` and `bash -n` syntax, and re-stages changes.

---

## 9. Container Image & Cloud-Agnostic Schema Migrator

The repository image doubles as a one-shot schema migrator that `crm-infra/` points at any SQL Server endpoint (local container, Amazon RDS for SQL Server, Azure SQL Database). See [crm-infra/CODING_STANDARDS.md](file:///Users/cy/codes/localstack-reference-architecture/crm-infra/CODING_STANDARDS.md) and ADR 4 in [docs/architecture-decisions.md](file:///Users/cy/codes/localstack-reference-architecture/docs/architecture-decisions.md). For the migration strategy rationale, see [MIGRATION_STRATEGY_COMPARISON.md](file:///Users/cy/codes/localstack-reference-architecture/CRMDatabaseMS/MIGRATION_STRATEGY_COMPARISON.md).

- **Single Publish Path**: [`publish.sh`](file:///Users/cy/codes/localstack-reference-architecture/CRMDatabaseMS/publish.sh) is the only DACPAC publish + seed implementation; `entrypoint.sh` delegates to it for the local container, and `crm-infra/terraform/modules/shared/database-schema` invokes it via `--entrypoint /app/publish.sh`. Never duplicate publish logic elsewhere.
- **Environment-Only Inputs**: Targets are supplied via `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `SEED_DATA`, and `ALLOW_INCOMPATIBLE_PLATFORM`, each with a `readonly DEFAULT_*` fallback. Credentials are never passed as positional arguments.
- **Idempotent & Readiness-Gated**: The runner waits for the endpoint (`MAX_READINESS_ATTEMPTS` × `READINESS_SLEEP_SECONDS`), and DACPAC publish converges to the declared state, so re-running against an up-to-date database is safe.
- **Platform**: The SQL Server base image is `linux/amd64`-only; keep `platform: linux/amd64` in `crm-infra/compose.yaml` and `migrator_platform` in `crm-infra/terraform/modules/shared/crm-catalog` in sync with the `Dockerfile` base image.
- **Secrets Hygiene**: Default development passwords live only in `.env.example` and script defaults for local use; real environments always inject credentials at runtime.
