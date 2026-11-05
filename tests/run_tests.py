#!/usr/bin/env python3
"""
CRMDatabaseMS Python Test Runner.
Executes test assertions against SQL Server with structured console output.
"""
import os
import sys
import subprocess

DB_SERVER = os.environ.get("DB_SERVER", "localhost")
DB_PORT = os.environ.get("DB_PORT", "1433")
DB_NAME = os.environ.get("DB_NAME", "CRMDatabaseMS")
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("SA_PASSWORD", os.environ.get("MSSQL_SA_PASSWORD", "CrmDev2026!Secure#Pass"))

def find_sqlcmd():
    for candidate in ["sqlcmd", "/opt/mssql-tools18/bin/sqlcmd", "/opt/mssql-tools/bin/sqlcmd"]:
        if os.path.exists(candidate) or subprocess.run(["which", candidate], capture_output=True).returncode == 0:
            return candidate
    return None

def main():
    sqlcmd = find_sqlcmd()
    if not sqlcmd:
        print("Error: 'sqlcmd' utility not found. Please install mssql-tools.", file=sys.stderr)
        sys.exit(1)

    base_dir = os.path.dirname(os.path.abspath(__file__))
    test_sql = os.path.join(base_dir, "03_run_all_tests.sql")

    print(f"==> Connecting to {DB_SERVER}:{DB_PORT}/{DB_NAME} as {DB_USER}...")
    cmd = [
        sqlcmd,
        "-S", f"{DB_SERVER},{DB_PORT}",
        "-U", DB_USER,
        "-P", DB_PASSWORD,
        "-C",
        "-d", DB_NAME,
        "-b",
        "-i", test_sql
    ]

    res = subprocess.run(cmd)
    if res.returncode != 0:
        print(f"\n❌ Test Suite Failed with exit code {res.returncode}", file=sys.stderr)
        sys.exit(res.returncode)
    else:
        print("\n✅ All Database Tests Passed Successfully!")

if __name__ == "__main__":
    main()
