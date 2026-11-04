# CRMDatabase

A SQL Database Project (SDK-style `Microsoft.Build.Sql`) modeling the top 3 CRM relational data models based on their official public documentation:

1. **Salesforce (Sales Cloud & Platform Data Model)** (`[Salesforce]` schema)
2. **HubSpot (CRM Object & Association Model)** (`[HubSpot]` schema)
3. **Microsoft Dynamics 365 (Dataverse / Common Data Model)** (`[Dynamics365]` schema)

---

## 1. Salesforce Data Model (`Salesforce`)

Modeled after the [Salesforce Object Reference for Salesforce and Lightning Platform](https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_concepts.htm). Uses standard 18-character alphanumeric identifier keys (`NVARCHAR(18)`), audit fields (`CreatedDate`, `CreatedById`, `LastModifiedDate`, `LastModifiedById`), and soft-delete flags (`IsDeleted`).

### Tables & Key Entities
- **`User`**: Internal system users, owners, and creators.
- **`Account`**: Companies, organizations, and accounts with parent hierarchy (`ParentId`) and billing/shipping addresses.
- **`Contact`**: Individuals associated with Accounts with organizational hierarchy (`ReportsToId`).
- **`AccountContactRelation`**: Many-to-many relationship supporting roles between Accounts and Contacts.
- **`Lead`**: Unqualified prospects with lead conversion tracking (`ConvertedAccountId`, `ConvertedContactId`, `ConvertedOpportunityId`).
- **`Campaign` & `CampaignMember`**: Marketing initiatives and member tracking across Leads and Contacts.
- **`Opportunity`**: Sales deals with stages (`StageName`), probability calculations, expected revenue, and forecast categories.
- **`Product2`**: Product catalog items with product families and active flags.
- **`Pricebook2` & `PricebookEntry`**: Standard and custom price books with currency unit pricing.
- **`OpportunityLineItem`**: Product line items associated with an Opportunity and PricebookEntry.
- **`Case`**: Customer service and support requests with escalation tracking and parent-case hierarchies.
- **`Task` & `Event`**: CRM activities, scheduled follow-ups, and calendar events.

---

## 2. HubSpot CRM Data Model (`HubSpot`)

Modeled after the [HubSpot CRM API & Objects Documentation](https://developers.hubspot.com/docs/api/crm/understanding-the-crm). Uses standard numeric object IDs (`BIGINT`), lifecycle stages, custom pipeline/stage definitions, and HubSpot's polymorphic association engine.

### Tables & Key Entities
- **`Owner`**: HubSpot CRM owners and users assigned to records.
- **`Company`**: Organizations with domain tracking, annual revenue, and lifecycle stages (`lifecyclestage`).
- **`Contact`**: Contact records with email, job title, company association, and lead status (`leadStatus`).
- **`Pipeline` & `DealStage`**: Configurable multi-pipeline sales and ticket stages with probability weighting and closed-won status.
- **`Deal`**: Sales opportunities progressing through pipeline stages with amounts and close dates.
- **`Ticket`**: Service tickets tied to pipelines, statuses, and priority levels.
- **`Product` & `LineItem`**: Product master and deal line items with recurring billing frequencies and discounts.
- **`Engagement`**: Interactions including Calls, Emails, Meetings, Notes, and Tasks.
- **`ObjectAssociation`**: HubSpot-style polymorphic association layer linking any CRM object pair with defined association type IDs.

---

## 3. Microsoft Dynamics 365 Data Model (`Dynamics365`)

Modeled after [Microsoft Dataverse & Dynamics 365 Sales Entity Reference / Common Data Model (CDM)](https://learn.microsoft.com/en-us/dynamics365/customer-engagement/web-api/about). Uses globally unique identifiers (`UNIQUEIDENTIFIER` / GUIDs), business units for multi-tenant / departmental security, and standard state/status codes (`statecode`, `statuscode`).

### Tables & Key Entities
- **`BusinessUnit`**: Hierarchical organizational and security units.
- **`SystemUser`**: Dynamics 365 users associated with BusinessUnits and ownership roles.
- **`Account`**: Business customers with account numbers, ownership, parent accounts, and address fields.
- **`Contact`**: Individual customer contacts linked to parent accounts (`parentcustomerid`).
- **`Lead`**: Sales prospects with quality ratings (Hot/Warm/Cold), conversion references, and estimated amounts.
- **`PriceLevel`**: Price lists with effective date ranges.
- **`Product`**: Catalog products with standard and current costs and quantity on hand.
- **`Opportunity`**: Sales opportunities linked to accounts, contacts, originating leads, and price lists.
- **`OpportunityProduct`**: Line items tied to Opportunities, Products, and unit pricing.
- **`Incident`**: Customer service cases with ticket numbers, priorities, severity codes, and resolution states.
- **`ActivityPointer`**: Base activity entity storing tasks, phone calls, emails, and appointments regarding accounts, contacts, opportunities, or cases.

---

## Build & Verify

### Local .NET SDK Build

Build the database project and generate the `.dacpac` artifact using the .NET SDK:

```bash
dotnet build
```

---

## Docker & Containerization

A complete multi-stage `Dockerfile` and `docker-compose.yml` are provided. The container builds the project, runs SQL Server 2022, and automatically deploys the `.dacpac` so the CRM database schemas are immediately ready for queries.

### Environment Configuration

Configure passwords and container settings in `.env` (a `.env.example` template is provided):

```bash
# Copy template to .env (if creating fresh)
cp .env.example .env
```

Default configuration in `.env`:
```dotenv
ACCEPT_EULA=Y
SA_PASSWORD=CrmDev2026!Secure#Pass
DB_NAME=CRMDatabase
DB_PORT=1433
```

### Run with Docker Compose (Recommended)

Start the database container (loads credentials automatically from `.env`):

```bash
docker compose up -d
```

Check logs to verify the database and schemas are initialized:

```bash
docker compose logs -f
```

Stop the container:

```bash
docker compose down
```

### Run with Docker CLI

1. **Build the image**:
   ```bash
   docker build -t crmdatabase .
   ```

2. **Run the container**:
   ```bash
   docker run -d --name crm-database -p 1433:1433 --env-file .env crmdatabase
   ```

3. **Connect and verify via container CLI**:
   ```bash
   docker exec -it crm-database /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'CrmDev2026!Secure#Pass' -C -d CRMDatabase -Q "SELECT TABLE_SCHEMA, COUNT(*) AS TableCount FROM INFORMATION_SCHEMA.TABLES GROUP BY TABLE_SCHEMA ORDER BY TABLE_SCHEMA;"
   ```

---

## Connection & Login Troubleshooting

### Default Connection Parameters

| Parameter | Value |
| :--- | :--- |
| **Server / Host** | `localhost` or `127.0.0.1` |
| **Port** | `1433` (or `${DB_PORT}`) |
| **Database** | `CRMDatabase` (or `master`) |
| **Authentication** | SQL Server Authentication |
| **Username** | `sa` |
| **Password** | `CrmDev2026!Secure#Pass` (from `.env`) |
| **Trust Server Certificate** | `True` / `Yes` |

### Common Login Issues & Solutions

1. **"The certificate chain was issued by an authority that is not trusted" (SSL/TLS Error)**:
   - **Cause**: SQL Server 2022 enforces encrypted connections by default, and local Docker containers use self-signed TLS certificates.
   - **Solution**: Enable **Trust Server Certificate** (`TrustServerCertificate=True` or `-C` flag) or set **Encrypt** to optional/disabled in your database client.

2. **"Login failed for user 'sa'" / Password rejected on startup**:
   - **Cause**: SQL Server requires strong passwords (at least 8 characters containing uppercase, lowercase, numbers, and symbols). Special shell characters like `$` or `!` need proper quoting or should be defined inside `.env`.
   - **Solution**: Set the password in `.env` and let Docker Compose pass it safely.

3. **Connecting from Host Tools**:

   - **VS Code / Azure Data Studio / JetBrains DataGrip**:
     - Server: `localhost,1433`
     - Database: `CRMDatabase`
     - Authentication: `SQL Login`
     - User name: `sa`
     - Password: `CrmDev2026!Secure#Pass`
     - Advanced: Set **Trust Server Certificate** to `True` / check "Trust server certificate".

   - **SQL Server Management Studio (SSMS 19+)**:
     - Server name: `localhost,1433`
     - Authentication: `SQL Server Authentication`
     - Login: `sa`
     - Password: `CrmDev2026!Secure#Pass`
     - Options > Connection Properties: Check **Trust server certificate** and **Encrypt connection: Optional**.

   - **DBeaver**:
     - Host: `localhost` \| Port: `1433` \| Database: `CRMDatabase`
     - Username: `sa` \| Password: `CrmDev2026!Secure#Pass`
     - Driver properties: `trustServerCertificate=true`

   - **ADO.NET / C# Connection String**:
     ```text
     Server=localhost,1433;Database=CRMDatabase;User Id=sa;Password=CrmDev2026!Secure#Pass;TrustServerCertificate=True;
     ```

   - **Node.js (mssql / tedious)**:
     ```javascript
     const config = {
       user: 'sa',
       password: process.env.SA_PASSWORD || 'CrmDev2026!Secure#Pass',
       server: 'localhost',
       port: 1433,
       database: 'CRMDatabase',
       options: {
         encrypt: true,
         trustServerCertificate: true
       }
     };
     ```

   - **Python (pyodbc)**:
     ```python
     conn = pyodbc.connect(
         'DRIVER={ODBC Driver 18 for SQL Server};'
         'SERVER=localhost,1433;'
         'DATABASE=CRMDatabase;'
         'UID=sa;'
         'PWD=CrmDev2026!Secure#Pass;'
         'TrustServerCertificate=yes;'
     )
     ```
