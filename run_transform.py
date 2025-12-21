# run_transform.py
# Purpose:
# Execute all SQL transformation files in order against a DuckDB database file.
# This rebuilds all views (telemetry_wide -> flight_summary) reproducibly.

import argparse
import duckdb
import glob
import os

# Directory containing ordered SQL files
SQL_DIR = "sql"

def main():
    """
    Execute all SQL transformations in a fixed order.

    Failure behavior:
    - Fails fast if the database or SQL directory is missing
    - Stops immediately on the first SQL error
    """

    parser = argparse.ArgumentParser(
        description="Run SQL transformations to build views (e.g., flight_summary) in a DuckDB database."
    )
    parser.add_argument(
        "--db",
        default=os.environ.get("BETA_DB_PATH", "beta_submission.duckdb"),
        help="Path to DuckDB database file (default: ./beta_submission.duckdb or env var BETA_DB_PATH)."
    )
    args = parser.parse_args()

    # Expand and normalize path
    db_path = os.path.expanduser(args.db)

    # Validate database existence early to avoid silent creation of a new DB at an unexpected path.
    if not os.path.exists(db_path):
        raise FileNotFoundError(f"Database not found at: {db_path}")

    # Discover SQL files and enforce execution order.
    sql_files = sorted(glob.glob(os.path.join(SQL_DIR, "*.sql")))
    if not sql_files:
        raise RuntimeError(f"No SQL files found in {SQL_DIR}/")

    # Open a single DuckDB connection for the full run
    con = duckdb.connect(db_path)

    for path in sql_files:
        print(f"Running {path}...")
        # SQL is read and executed as a full unit to preserve statement order
        with open(path, "r") as f:
            con.execute(f.read())

    # Ensure the database file is cleanly closed
    con.close()
    print("All SQL files executed successfully.")

if __name__ == "__main__":
    main()
