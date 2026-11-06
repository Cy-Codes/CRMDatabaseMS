#!/usr/bin/env bash
set -euo pipefail

readonly DEFAULT_DB_NAME="CRMDatabaseMS"
readonly DEFAULT_DB_USER="sa"
readonly DEFAULT_DB_PASSWORD="CrmDev2026!Secure#Pass"
readonly DEFAULT_SEED_MODE="standard"
readonly DEFAULT_SCALE_FACTOR="100"
readonly MAX_READINESS_ATTEMPTS=60
readonly READINESS_SLEEP_SECONDS=2
readonly DACPAC_PATH="/app/CRMDatabaseMS.dacpac"

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo "Starting SQL Server (PID: ${SQL_PID})..."

DB_NAME="${DB_NAME:-${DEFAULT_DB_NAME}}"
DB_USER="${DB_USER:-${DEFAULT_DB_USER}}"
DB_PASSWORD="${SA_PASSWORD:-${MSSQL_SA_PASSWORD:-${DEFAULT_DB_PASSWORD}}}"

find_sqlcmd() {
    if [ -f "/opt/mssql-tools18/bin/sqlcmd" ]; then
        echo "/opt/mssql-tools18/bin/sqlcmd"
    else
        echo "/opt/mssql-tools/bin/sqlcmd"
    fi
}

run_sqlcmd_query() {
    local query="$1"
    local target_db="${2:-master}"
    "${SQLCMD}" -S localhost -U "${DB_USER}" -P "${DB_PASSWORD}" -C -d "${target_db}" -Q "${query}"
}

SQLCMD="$(find_sqlcmd)"

# Wait for SQL Server to become available (bounded polling loop for process readiness)
echo "Waiting for SQL Server to become ready..."
for _ in $(seq 1 "${MAX_READINESS_ATTEMPTS}"); do
    if run_sqlcmd_query "SELECT 1" >/dev/null 2>&1; then
        echo "SQL Server is ready."
        break
    fi
    sleep "${READINESS_SLEEP_SECONDS}"
done

# Publish the DACPAC using SqlPackage
if [ -f "${DACPAC_PATH}" ]; then
    echo "Deploying CRMDatabaseMS.dacpac to target database '${DB_NAME}'..."
    /opt/sqlpackage/sqlpackage \
        /Action:Publish \
        /SourceFile:"${DACPAC_PATH}" \
        /TargetServerName:localhost \
        /TargetDatabaseName:"${DB_NAME}" \
        /TargetUser:"${DB_USER}" \
        /TargetPassword:"${DB_PASSWORD}" \
        /TargetTrustServerCertificate:True
    echo "CRM Database schemas (Salesforce, HubSpot, Dynamics 365) successfully deployed and ready for connections!"

    SEED_DATA="${SEED_DATA:-${DEFAULT_SEED_MODE}}"
    if [ "${SEED_DATA}" = "standard" ] || [ "${SEED_DATA}" = "50" ]; then
        echo "Seeding standard CRM data (50 records per entity)..."
        run_sqlcmd_query "EXEC [dbo].[sp_SeedStandardData] @CleanExisting = 1;" "${DB_NAME}"
        echo "Standard CRM data seeded successfully (50 records per entity)."
    elif [ "${SEED_DATA}" = "heavy" ] || [ "${SEED_DATA}" = "etl" ]; then
        SCALE_FACTOR="${SEED_SCALE_FACTOR:-${DEFAULT_SCALE_FACTOR}}"
        echo "Simulating heavy ETL data load (Scale Factor: ${SCALE_FACTOR})..."
        run_sqlcmd_query "EXEC [dbo].[sp_SimulateHeavyETLLoad] @ScaleFactor = ${SCALE_FACTOR}, @CleanExisting = 1;" "${DB_NAME}"
        echo "Heavy ETL data load simulation completed successfully."
    else
        echo "SEED_DATA is set to '${SEED_DATA}', skipping seed data generation."
    fi
else
    echo "Warning: ${DACPAC_PATH} not found, skipping dacpac publish."
fi

# Keep container running by waiting for the background SQL Server process
wait "${SQL_PID}"
