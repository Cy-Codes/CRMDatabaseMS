#!/usr/bin/env bash
# ============================================================================
# CRMDatabaseMS Automated Test Runner Script
# Executes schema structure, foreign key integrity, and seed data test suites.
# ============================================================================
set -euo pipefail

readonly DEFAULT_DB_SERVER="localhost"
readonly DEFAULT_DB_PORT="1433"
readonly DEFAULT_DB_NAME="CRMDatabaseMS"
readonly DEFAULT_DB_USER="sa"
readonly DEFAULT_DB_PASSWORD="CrmDev2026!Secure#Pass"
readonly MASTER_TEST_SUITE_FILE="04_Run_All_Tests.sql"

DB_SERVER="${DB_SERVER:-${DEFAULT_DB_SERVER}}"
DB_PORT="${DB_PORT:-${DEFAULT_DB_PORT}}"
DB_NAME="${DB_NAME:-${DEFAULT_DB_NAME}}"
DB_USER="${DB_USER:-${DEFAULT_DB_USER}}"
DB_PASSWORD="${SA_PASSWORD:-${MSSQL_SA_PASSWORD:-${DEFAULT_DB_PASSWORD}}}"

find_sqlcmd() {
    if command -v sqlcmd >/dev/null 2>&1; then
        echo "sqlcmd"
    elif [ -f "/opt/mssql-tools18/bin/sqlcmd" ]; then
        echo "/opt/mssql-tools18/bin/sqlcmd"
    elif [ -f "/opt/mssql-tools/bin/sqlcmd" ]; then
        echo "/opt/mssql-tools/bin/sqlcmd"
    else
        echo "Error: sqlcmd utility not found in PATH or standard directories." >&2
        return 1
    fi
}

run_sqlcmd_file() {
    local sqlcmd_bin="$1"
    local sql_file="$2"
    "${sqlcmd_bin}" \
        -S "${DB_SERVER},${DB_PORT}" \
        -U "${DB_USER}" \
        -P "${DB_PASSWORD}" \
        -C \
        -d "${DB_NAME}" \
        -b \
        -i "${sql_file}"
}

SQLCMD_BIN="$(find_sqlcmd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="${SCRIPT_DIR}/${MASTER_TEST_SUITE_FILE}"

echo "==> Running CRMDatabaseMS Test Suite against ${DB_SERVER}:${DB_PORT}/${DB_NAME}..."
run_sqlcmd_file "${SQLCMD_BIN}" "${TEST_FILE}"
echo "==> Test execution finished successfully."
