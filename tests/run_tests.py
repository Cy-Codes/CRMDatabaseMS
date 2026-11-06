#!/usr/bin/env python3
"""
CRMDatabaseMS Python Test Runner.
Executes test assertions against SQL Server with structured console output.
"""
from __future__ import annotations

from dataclasses import dataclass
import os
import shutil
import subprocess
import sys

DEFAULT_DB_SERVER: str = "localhost"
DEFAULT_DB_PORT: str = "1433"
DEFAULT_DB_NAME: str = "CRMDatabaseMS"
DEFAULT_DB_USER: str = "sa"
DEFAULT_DB_PASSWORD: str = "CrmDev2026!Secure#Pass"
MASTER_TEST_SUITE_FILENAME: str = "03_run_all_tests.sql"

SQLCMD_CANDIDATES: tuple[str, ...] = (
    "sqlcmd",
    "/opt/mssql-tools18/bin/sqlcmd",
    "/opt/mssql-tools/bin/sqlcmd",
)


@dataclass(frozen=True)
class MsSqlConfig:
    """Immutable connection configuration for SQL Server test execution."""
    server: str
    port: str
    database: str
    user: str
    password: str


def resolve_config() -> MsSqlConfig:
    """Pure query reading SQL Server connection parameters from environment variables."""
    return MsSqlConfig(
        server=os.environ.get("DB_SERVER", DEFAULT_DB_SERVER),
        port=os.environ.get("DB_PORT", DEFAULT_DB_PORT),
        database=os.environ.get("DB_NAME", DEFAULT_DB_NAME),
        user=os.environ.get("DB_USER", DEFAULT_DB_USER),
        password=os.environ.get(
            "SA_PASSWORD",
            os.environ.get("MSSQL_SA_PASSWORD", DEFAULT_DB_PASSWORD),
        ),
    )


def is_available_binary(binary_path: str) -> bool:
    """Pure check verifying whether a CLI binary exists on disk or in PATH."""
    return os.path.exists(binary_path) or shutil.which(binary_path) is not None


def find_sqlcmd() -> str | None:
    """Functional lookup returning the first available sqlcmd binary."""
    return next((candidate for candidate in SQLCMD_CANDIDATES if is_available_binary(candidate)), None)


def build_sqlcmd_command(sqlcmd_bin: str, config: MsSqlConfig, sql_file_path: str) -> tuple[str, ...]:
    """Pure builder assembling the sqlcmd CLI argument tuple."""
    return (
        sqlcmd_bin,
        "-S", f"{config.server},{config.port}",
        "-U", config.user,
        "-P", config.password,
        "-C",
        "-d", config.database,
        "-b",
        "-i", sql_file_path,
    )


def execute_test_suite(command: tuple[str, ...]) -> int:
    """Explicit side-effecting process execution running the SQL Server test suite."""
    result = subprocess.run(command, check=False)
    return result.returncode


def main() -> None:
    sqlcmd = find_sqlcmd()
    if not sqlcmd:
        print("Error: 'sqlcmd' utility not found. Please install mssql-tools.", file=sys.stderr)
        sys.exit(1)

    config = resolve_config()
    base_dir = os.path.dirname(os.path.abspath(__file__))
    test_sql = os.path.join(base_dir, MASTER_TEST_SUITE_FILENAME)

    print(f"==> Connecting to {config.server}:{config.port}/{config.database} as {config.user}...")
    command = build_sqlcmd_command(sqlcmd, config, test_sql)
    exit_code = execute_test_suite(command)

    if exit_code != 0:
        print(f"\n❌ Test Suite Failed with exit code {exit_code}", file=sys.stderr)
        sys.exit(exit_code)

    print("\n✅ All Database Tests Passed Successfully!")


if __name__ == "__main__":
    main()
