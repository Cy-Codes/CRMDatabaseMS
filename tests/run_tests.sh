#!/usr/bin/env bash
# ============================================================================
# CRMDatabaseMS Automated Test Runner Script
# Executes schema structure, foreign key integrity, and seed data test suites.
# ============================================================================
set -euo pipefail

DB_SERVER="${DB_SERVER:-localhost}"
DB_PORT="${DB_PORT:-1433}"
DB_NAME="${DB_NAME:-CRMDatabase}"
DB_USER="${DB_USER:-sa}"
DB_PASSWORD="${SA_PASSWORD:-${MSSQL_SA_PASSWORD:-CrmDev2026!Secure#Pass}}"

# Locate sqlcmd
SQLCMD=""
if command -v sqlcmd >/dev/null 2>&1; then
    SQLCMD="sqlcmd"
elif [ -f "/opt/mssql-tools18/bin/sqlcmd" ]; then
    SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
elif [ -f "/opt/mssql-tools/bin/sqlcmd" ]; then
    SQLCMD="/opt/mssql-tools/bin/sqlcmd"
else
    echo "Error: sqlcmd utility not found in PATH or standard directories."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="${SCRIPT_DIR}/03_run_all_tests.sql"

echo "==> Running CRMDatabaseMS Test Suite against ${DB_SERVER}:${DB_PORT}/${DB_NAME}..."

"$SQLCMD" -S "${DB_SERVER},${DB_PORT}"           -U "${DB_USER}"           -P "${DB_PASSWORD}"           -C           -d "${DB_NAME}"           -b           -i "${TEST_FILE}"

echo "==> Test execution finished successfully."
