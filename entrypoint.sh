#!/usr/bin/env bash
set -e

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo "Starting SQL Server (PID: $SQL_PID)..."

DB_NAME="${DB_NAME:-CRMDatabaseMS}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${SA_PASSWORD:-${MSSQL_SA_PASSWORD:-CrmDev2026!Secure#Pass}}"

# Locate sqlcmd
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
if [ ! -f "$SQLCMD" ]; then
    SQLCMD="/opt/mssql-tools/bin/sqlcmd"
fi

# Wait for SQL Server to become available
echo "Waiting for SQL Server to become ready..."
for i in {1..60}; do
    if "$SQLCMD" -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1; then
        echo "SQL Server is ready."
        break
    fi
    sleep 2
done

# Publish the DACPAC using SqlPackage
if [ -f "/app/CRMDatabaseMS.dacpac" ]; then
    echo "Deploying CRMDatabaseMS.dacpac to target database '$DB_NAME'..."
    /opt/sqlpackage/sqlpackage \
        /Action:Publish \
        /SourceFile:/app/CRMDatabaseMS.dacpac \
        /TargetServerName:localhost \
        /TargetDatabaseName:"$DB_NAME" \
        /TargetUser:"$DB_USER" \
        /TargetPassword:"$DB_PASSWORD" \
        /TargetTrustServerCertificate:True
    echo "CRM Database schemas (Salesforce, HubSpot, Dynamics 365) successfully deployed and ready for connections!"

    # Seed initial data if SEED_DATA environment variable is set
    SEED_DATA="${SEED_DATA:-standard}"
    if [ "$SEED_DATA" = "standard" ] || [ "$SEED_DATA" = "50" ]; then
        echo "Seeding standard CRM data (50 records per entity)..."
        "$SQLCMD" -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -C -d "$DB_NAME" -Q "EXEC [dbo].[sp_SeedStandardData] @CleanExisting = 1;"
        echo "Standard CRM data seeded successfully (50 records per entity)."
    elif [ "$SEED_DATA" = "heavy" ] || [ "$SEED_DATA" = "etl" ]; then
        SCALE_FACTOR="${SEED_SCALE_FACTOR:-100}"
        echo "Simulating heavy ETL data load (Scale Factor: $SCALE_FACTOR)..."
        "$SQLCMD" -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -C -d "$DB_NAME" -Q "EXEC [dbo].[sp_SimulateHeavyETLLoad] @ScaleFactor = $SCALE_FACTOR, @CleanExisting = 1;"
        echo "Heavy ETL data load simulation completed successfully."
    elif [ "$SEED_DATA" = "none" ] || [ "$SEED_DATA" = "0" ] || [ "$SEED_DATA" = "false" ]; then
        echo "SEED_DATA is set to '$SEED_DATA', skipping seed data generation."
    else
        echo "SEED_DATA is set to '$SEED_DATA', skipping seed data generation."
    fi
else
    echo "Warning: /app/CRMDatabaseMS.dacpac not found, skipping dacpac publish."
fi

# Keep container running by waiting for the background SQL Server process
wait $SQL_PID
