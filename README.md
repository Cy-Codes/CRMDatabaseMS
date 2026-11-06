# CRMDatabaseMS: Microsoft SQL Server State-Based CRM Database

A production-grade Microsoft SQL Server / Azure SQL database project (`Microsoft.Build.Sql` SDK-style `.sqlproj`) modeling the top 3 enterprise CRM relational data architectures:

1. **Salesforce (Sales Cloud & Platform Data Model)** (`[Salesforce]` schema — 15 Tables)
2. **HubSpot (CRM Object & Association Model)** (`[HubSpot]` schema — 11 Tables)
3. **Microsoft Dynamics 365 (Dataverse / Common Data Model)** (`[Dynamics365]` schema — 11 Tables)

This project utilizes a **declarative, state-based database deployment model** powered by SQL Server Data Tools (SSDT), the `Microsoft.Build.Sql` SDK, and DACPAC artifacts.

For coding conventions, T-SQL guidelines, and set-based design rules, consult the **[CRMDatabaseMS Coding Standards](file:///Users/cy/codes/localstack-reference-architecture/CRMDatabaseMS/CODING_STANDARDS.md)** and workspace **[Coding Standards](file:///Users/cy/codes/localstack-reference-architecture/CODING_STANDARDS.md)**.

---

## 🏛️ Architecture Overview

The database manages 37 CRM entity tables partitioned across three dedicated schemas:

```
CRMDatabaseMS (Microsoft SQL Server)
├── [Salesforce] Schema (15 Tables)
│   ├── User, Account, Contact, AccountContactRelation, Lead
│   ├── Campaign, CampaignMember, Opportunity, Product2, Pricebook2
│   ├── PricebookEntry, OpportunityLineItem, Case, Task, Event
├── [HubSpot] Schema (11 Tables)
│   ├── Owner, Company, Contact, Pipeline, DealStage, Deal
│   ├── Ticket, Product, LineItem, Engagement, ObjectAssociation
└── [Dynamics365] Schema (11 Tables)
    ├── BusinessUnit, SystemUser, Account, Contact, Lead
    ├── PriceLevel, Product, Opportunity, OpportunityProduct
    ├── Incident, ActivityPointer
```

---

## 🔄 State-Based Migration Strategy (DACPAC Lifecycle)

### Core Paradigm: Declarative Desired State

Unlike imperative/migration-based tools (such as Flyway or Liquibase used in **CRMDatabasePG**), this project uses a **declarative state-based approach** established by Microsoft's Data-Tier Application Framework (DACFx):

* **Source of Truth**: The individual `.sql` DDL files in source control represent the **desired end state** of every database object (`CREATE TABLE [Salesforce].[Account]`, etc.).
* **No Versioned Migration Scripts**: Developers do not write transition scripts (`V1__...`, `V2__...`). Instead, you edit the table definition directly in its `.sql` file.
* **Compilation**: The .NET SDK builds the `.sqlproj` project into a compiled Data-Tier Application binary package (**`CRMDatabaseMS.dacpac`**).
* **Automated Differential Deployment**: At release time, the deployment engine (**`SqlPackage.exe`** / DACFx) connects to the target database, inspects the current live catalog, computes a dependency graph diff between the `.dacpac` model and the live database, and generates an ephemeral transactional DDL synchronization script.

```
┌────────────────────────────────────────────────────────┐
│               Source Control (Git)                     │
│  Salesforce/Tables/Account.sql (Declarative DDL)       │
└───────────────────────────┬────────────────────────────┘
                            │  dotnet build
                            ▼
┌────────────────────────────────────────────────────────┐
│                CRMDatabaseMS.dacpac                    │
│         (Compiled Database Model Artifact)             │
└───────────────────────────┬────────────────────────────┘
                            │  SqlPackage /Action:Publish
                            ▼
┌────────────────────────────────────────────────────────┐
│            SqlPackage Deployment Engine                │
│  1. Read Target DB Schema Catalog                      │
│  2. Compute Topological Graph Diff (Model vs Live)     │
│  3. Generate Dynamic ALTER / CREATE / DROP Script      │
│  4. Execute Script inside Database Transaction         │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│               Live Target Database                     │
│          (Schema Harmonized to Model State)            │
└────────────────────────────────────────────────────────┘
```

---

### Key Advantages of State-Based Deployments

1. **Schema Drift Detection & Self-Healing**: If an out-of-band change occurs in a staging or production database, `SqlPackage` automatically detects the discrepancy and reconciles the target database back to match the source code model.
2. **Simplified Developer Experience for Programmable Code**: Stored procedures, views, user-defined functions, and security roles are edited in-place with standard Git diffs, without managing dozens of incremental migration files.
3. **Automated Dependency Resolution**: Tables, views, foreign keys, and indexes are created in topological dependency order without manual sequencing.
4. **Compile-Time Static Analysis**: Building the `.sqlproj` validates syntax, column references, data types, and unresolved foreign keys before reaching any live database.

---

### Handling Complex Schema & Data Transformations

While `SqlPackage` automatically handles additive and non-breaking changes (adding columns, creating indexes, modifying stored procedures), structural refactorings (such as column splits, merges, or renames) require safety mechanisms:

#### 1. Pre-Deployment and Post-Deployment Scripts
You can include scripts that execute before or after the declarative model synchronization:
* **`PreDeployment.sql`**: Execute data preservation steps or safety checks prior to schema alterations.
* **`PostDeployment.sql`**: Backfill default data, refresh lookup tables, or populate new columns from legacy fields.

#### 2. Publish Profiles (`.publish.xml`)
Fine-tune deployment safety rules using publish parameters:
* `BlockOnPossibleDataLoss=True`: Prevents deployments that would drop columns containing live data.
* `DropObjectsNotInSource=False`: Preserves operational objects (e.g. temporary staging tables, external indexes) not tracked in the project.
* `GenerateSmartDefaults=True`: Automatically provides defaults when adding `NOT NULL` columns to populated tables.

---

### Architectural & Industry References

For foundational reading on state-based lifecycle tools and declarative database development:

1. **Microsoft Learn: SqlPackage & DACFx Architecture**
   * Detailed overview of the Data-Tier Application Framework, schema comparison engine, and command-line publishing flags.
   * Read at: [learn.microsoft.com - SqlPackage Overview](https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage)

2. **Microsoft Learn: SQL Database Projects & Microsoft.Build.Sql SDK**
   * Official documentation on cross-platform SDK-style `.sqlproj` development on Linux, macOS, and Windows.
   * Read at: [learn.microsoft.com - SQL Projects Overview](https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-projects-overview)

3. **Redgate Simple Talk: State-Based vs. Migration-Based Database Development**
   * In-depth comparison of declarative state reconciliation versus incremental delta scripts across enterprise teams.
   * Read at: [red-gate.com - State-Based vs Migration-Based Development](https://www.red-gate.com/simple-talk/devops/database-devops/state-based-vs-migration-based-database-development/)

4. **Evolutionary Database Design (Pramod Sadalage & Martin Fowler)**
   * Foundational patterns for version-controlled database schemas and continuous integration.
   * Read at: [martinfowler.com - Evolutionary Database Design](https://martinfowler.com/articles/evodb.html)

For an in-depth architectural breakdown comparing **State-Based (CRMDatabaseMS / DACPAC)** against **Migration-Based (CRMDatabasePG / Flyway)** across 15+ evaluation criteria:

👉 [MIGRATION_STRATEGY_COMPARISON.md](./MIGRATION_STRATEGY_COMPARISON.md)

---

## 🧪 Testing Strategy: Architectural Division of Responsibilities

### Architectural Rationale: API-First Testing vs. Database Invariants

Modern software architecture and testing consensus strongly advocate for **placing domain validation, business rules, and comprehensive automated test suites in the API / Application layer**, while reserving the database layer for **relational structural guarantees, ACID persistence, and schema integrity**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        API / Application Layer                         │
│  - Domain models, state machines, business workflows, validation rules │
│  - Rich test pyramids (unit, component, contract, integration tests)   │
│  - Horizontal, inexpensive, stateless scaling (containers / pods)     │
│  - Rich developer tooling: IDEs, linters, debuggers, profilers, CI/CD  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ SQL Queries / ORM
┌───────────────────────────────────▼────────────────────────────────────┐
│                         Database / Storage Layer                       │
│  - Persistence, ACID transactions, data consistency invariants         │
│  - Relational constraints (FKs, unique keys, nullability, check types) │
│  - Indexes, physical layout, performance optimization                  │
│  - Lightweight structural & smoke verification                         │
└────────────────────────────────────────────────────────────────────────┘
```

#### Why Industry Best Practices Favor API Layer Testing:

1. **Scaling Economics & Compute Cost**:
   * API servers are stateless and scale horizontally across commodity compute instances or Kubernetes pods at low cost.
   * Relational database instances scale vertically; database CPU cycles, IOPS, and connection pools are among the most expensive and contention-prone resources in an infrastructure stack (see [aws.amazon.com - Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)).

2. **Test Pyramid Velocity & Feedback Cycles**:
   * According to Martin Fowler's *The Practical Test Pyramid* ([martinfowler.com - Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)) and *Microservice Testing* ([martinfowler.com - Microservice Testing](https://martinfowler.com/articles/microservice-testing/)), fast feedback loops depend on lightweight, in-memory unit tests executing in milliseconds.
   * Testing complex business workflows exclusively in database stored procedures requires standing up isolated database instances, managing transactional state resets, and enduring disk I/O latency, which slows down CI/CD pipelines.

3. **Smart Endpoints and Dumb Pipes**:
   * A core tenet of modern microservice and web architecture is keeping domain logic in cohesive application services while treating infrastructure and transport mechanisms as decoupled backing services (see [martinfowler.com - Smart Endpoints and Dumb Pipes](https://martinfowler.com/articles/microservices.html#SmartEndpointsAndDumbPipes) and [12factor.net - Stateless Processes & Backing Services](https://12factor.net/)).

4. **Clean Architecture & Domain Decoupling**:
   * Placing business logic in the API allows databases to be treated as swappable persistence plugins (as outlined in Microsoft's [learn.microsoft.com - Common Web Application Architectures](https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures)), preventing vendor lock-in to proprietary database dialects (T-SQL, PL/pgSQL).

---

### What Belongs at the Database Level

The database layer remains responsible for enforcing hard structural invariants that protect data consistency regardless of which client or process connects to the database:

1. **Schema & Namespace Verification**: Confirming all 3 CRM schemas (`Salesforce`, `HubSpot`, `Dynamics365`) and 37 entity tables exist.
2. **Key Constraints & Referential Integrity**: Ensuring primary keys and foreign key constraints are registered and prevent orphaned records.
3. **Engine-Level Invariant Enforcement (Negative Tests)**: Verifying the database engine rejects foreign key violations, `NOT NULL` violations, and duplicate unique keys.
4. **Data Seeding & Migration Idempotency**: Ensuring cleanup scripts (`sp_CleanupAllCRMData`) and standard seed scripts (`sp_SeedStandardData` inserting 1,850 rows) execute reliably without deadlocks.

---

### Automated Database Test Suites

The repository includes automated database verification suites in `tests/` (and packaged in `Scripts/03_Run_Schema_And_Integrity_Tests.sql`):

1. **`tests/01_schema_structure_tests.sql`**:
   - Asserts existence of `[Salesforce]`, `[HubSpot]`, and `[Dynamics365]` schemas.
   - Verifies exact table counts (15 Salesforce + 11 HubSpot + 11 Dynamics 365 = **37 Tables total**).
   - Validates that foreign key constraints are registered in `sys.foreign_keys`.
   - Validates existence of all stored procedures in `dbo`.

2. **`tests/02_data_integrity_and_seed_tests.sql`**:
   - Tests `[dbo].[sp_CleanupAllCRMData]` wipes all 37 tables cleanly (0 rows remaining).
   - Tests `[dbo].[sp_SeedStandardData]` seeds exactly 50 records per entity (**1,850 total rows**).
   - Tests referential integrity (0 orphaned Contacts/Opportunities in Salesforce, 0 orphaned LineItems in HubSpot, 0 orphaned Contacts in Dynamics 365).

3. **`tests/03_constraint_enforcement_tests.sql`**:
   - Negative / Invariant tests asserting that invalid FK inserts (error 547), `NOT NULL` violations (error 515), and duplicate unique keys (error 2627) are rejected by the database engine.
   - Asserts computed column evaluation (`Salesforce.User.Name` and `Salesforce.Opportunity.ExpectedRevenue`).

4. **`tests/03_run_all_tests.sql`**:
   - Master transactional runner executing all 3 suites with structured `[PASS]` / `[FAIL]` reporting.

---

### Running the Database Tests

#### Option 1: Via Docker Container
```bash
# Execute master test suite inside the running container
docker exec -i crm-database-ms /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'CrmDev2026!Secure#Pass' -C -d CRMDatabaseMS -i /app/tests/03_run_all_tests.sql
```

#### Option 2: Via Shell Test Runner (`tests/run_tests.sh`)
```bash
export DB_SERVER=localhost
export DB_PORT=1433
export DB_NAME=CRMDatabaseMS
export SA_PASSWORD=CrmDev2026!Secure#Pass

./tests/run_tests.sh
```

#### Option 3: Via Python Test Runner (`tests/run_tests.py`)
```bash
python3 tests/run_tests.py
```

---

## 🚀 Quick Start with Docker

A complete multi-stage `Dockerfile` and `docker-compose.yml` are provided. The container builds the project, runs SQL Server 2022, deploys the `.dacpac`, and pre-seeds initial test data.

### 1. Environment Configuration (`.env`)
```bash
cp .env.example .env
```

Default configuration in `.env`:
```dotenv
ACCEPT_EULA=Y
SA_PASSWORD=CrmDev2026!Secure#Pass
DB_NAME=CRMDatabaseMS
DB_PORT=1433
SEED_DATA=standard
SEED_SCALE_FACTOR=100
```

### 2. Start the Container
```bash
docker compose up -d
```

### 3. Check Initialization Logs
```bash
docker compose logs -f
```

### 4. Connect via `sqlcmd`
```bash
docker exec -it crm-database-ms /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'CrmDev2026!Secure#Pass' -C -d CRMDatabaseMS -Q "SELECT TABLE_SCHEMA, COUNT(*) AS TableCount FROM INFORMATION_SCHEMA.TABLES GROUP BY TABLE_SCHEMA ORDER BY TABLE_SCHEMA;"
```

---

## 📊 Data Seeding & ETL Benchmarking

### 1. Standard Dataset (1,850 Records)
Populates 50 realistic rows per table with consistent foreign key associations across all 37 tables:
```sql
EXEC [dbo].[sp_SeedStandardData] @CleanExisting = 1;
```

### 2. High-Volume ETL Simulation (~88,000+ Records)
Simulates high-throughput production CRM bulk imports:
```sql
-- Scale Factor 100 generates ~88,000 records
EXEC [dbo].[sp_SimulateHeavyETLLoad] @ScaleFactor = 100, @CleanExisting = 1;
```

### 3. Full Data Truncation
Safely empties all 37 tables in topological dependency order:
```sql
EXEC [dbo].[sp_CleanupAllCRMData];
```
