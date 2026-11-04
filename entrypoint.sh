#!/usr/bin/env bash
set -e

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo "Starting SQL Server (PID: $SQL_PID)..."

DB_NAME="${DB_NAME:-CRMDatabase}"
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
if [ -f "/app/CRMDatabase.dacpac" ]; then
    echo "Deploying CRMDatabase.dacpac to target database '$DB_NAME'..."
    /opt/sqlpackage/sqlpackage \
        /Action:Publish \
        /SourceFile:/app/CRMDatabase.dacpac \
        /TargetServerName:localhost \
        /TargetDatabaseName:"$DB_NAME" \
        /TargetUser:"$DB_USER" \
        /TargetPassword:"$DB_PASSWORD" \
        /TargetTrustServerCertificate:True
    echo "CRM Database schemas (Salesforce, HubSpot, Dynamics 365) successfully deployed and ready for connections!"
else
    echo "Warning: /app/CRMDatabase.dacpac not found, skipping dacpac publish."
fi

# Keep container running by waiting for the background SQL Server process
wait $SQL_PID
