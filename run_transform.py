# run_transform.py
# Purpose:
# Execute all SQL transformation files in order against the submission DuckDB.
# This rebuilds all views (telemetry_wide -> flight_summary) reproducibly.

import duckdb
import glob
import os

# Path to the submission database (copied from the original)
DB_PATH = os.path.expanduser("~/Desktop/beta_submission.duckdb")

# Directory containing ordered SQL files
SQL_DIR = "sql"

def main():
    if not os.path.exists(DB_PATH):
        raise FileNotFoundError(f"Database not found at {DB_PATH}")

    sql_files = sorted(glob.glob(os.path.join(SQL_DIR, "*.sql")))
    if not sql_files:
        raise RuntimeError(f"No SQL files found in {SQL_DIR}/")

    con = duckdb.connect(DB_PATH)

    for path in sql_files:
        print(f"Running {path}...")
        with open(path, "r") as f:
            con.execute(f.read())

    con.close()
    print("All SQL files executed successfully.")

if __name__ == "__main__":
    main()
