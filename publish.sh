#!/usr/bin/env bash
# ============================================================================
# DACPAC Publish & Seed Runner for SQL Server
# Targets any reachable SQL Server endpoint (the local container, Amazon RDS
# for SQL Server, or Azure SQL Database), so the same image doubles as a
# cloud-agnostic schema migrator:
#   docker run --rm --entrypoint /app/publish.sh -e DB_HOST=... crm-database-ms
# ============================================================================
set -euo pipefail

readonly DEFAULT_DB_HOST="localhost"
readonly DEFAULT_DB_PORT="1433"
readonly DEFAULT_DB_NAME="CRMDatabaseMS"
readonly DEFAULT_DB_USER="sa"
readonly DEFAULT_DB_PASSWORD="CrmDev2026!Secure#Pass"
readonly DEFAULT_SEED_MODE="standard"
readonly DEFAULT_SCALE_FACTOR="100"
readonly DEFAULT_ALLOW_INCOMPATIBLE_PLATFORM="False"
readonly MAX_READINESS_ATTEMPTS=60
readonly READINESS_SLEEP_SECONDS=2
readonly DACPAC_PATH="/app/CRMDatabaseMS.dacpac"

DB_HOST="${DB_HOST:-${DEFAULT_DB_HOST}}"
DB_PORT="${DB_PORT:-${DEFAULT_DB_PORT}}"
DB_NAME="${DB_NAME:-${DEFAULT_DB_NAME}}"
DB_USER="${DB_USER:-${DEFAULT_DB_USER}}"
DB_PASSWORD="${DB_PASSWORD:-${SA_PASSWORD:-${MSSQL_SA_PASSWORD:-${DEFAULT_DB_PASSWORD}}}}"
ALLOW_INCOMPATIBLE_PLATFORM="${ALLOW_INCOMPATIBLE_PLATFORM:-${DEFAULT_ALLOW_INCOMPATIBLE_PLATFORM}}"
readonly TARGET_SERVER="${DB_HOST},${DB_PORT}"

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
    "${SQLCMD}" -S "${TARGET_SERVER}" -U "${DB_USER}" -P "${DB_PASSWORD}" -C -d "${target_db}" -Q "${query}"
}

wait_for_sql_server() {
    echo "Waiting for SQL Server at ${TARGET_SERVER} to become ready..."
    for _ in $(seq 1 "${MAX_READINESS_ATTEMPTS}"); do
        if run_sqlcmd_query "SELECT 1" >/dev/null 2>&1; then
            echo "SQL Server is ready."
            return 0
        fi
        sleep "${READINESS_SLEEP_SECONDS}"
    done
    echo "Error: SQL Server at ${TARGET_SERVER} did not become ready in time." >&2
    return 1
}

SQLCMD="$(find_sqlcmd)"

wait_for_sql_server

# Publish the DACPAC using SqlPackage
if [ -f "${DACPAC_PATH}" ]; then
    echo "Deploying CRMDatabaseMS.dacpac to target database '${DB_NAME}' on ${TARGET_SERVER}..."
    /opt/sqlpackage/sqlpackage \
        /Action:Publish \
        /SourceFile:"${DACPAC_PATH}" \
        /TargetServerName:"${TARGET_SERVER}" \
        /TargetDatabaseName:"${DB_NAME}" \
        /TargetUser:"${DB_USER}" \
        /TargetPassword:"${DB_PASSWORD}" \
        /TargetTrustServerCertificate:True \
        /p:AllowIncompatiblePlatform="${ALLOW_INCOMPATIBLE_PLATFORM}"
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
