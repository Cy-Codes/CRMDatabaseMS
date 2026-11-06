#!/usr/bin/env bash
set -euo pipefail

readonly LOCAL_DB_HOST="localhost"
readonly PUBLISH_SCRIPT_PATH="/app/publish.sh"

# Start SQL Server in the background
/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo "Starting SQL Server (PID: ${SQL_PID})..."

# Wait for readiness, publish the DACPAC and seed data against the in-container engine.
# The same script is reused as a remote migrator for Amazon RDS and Azure SQL Database.
DB_HOST="${LOCAL_DB_HOST}" "${PUBLISH_SCRIPT_PATH}"

# Keep container running by waiting for the background SQL Server process
wait "${SQL_PID}"
