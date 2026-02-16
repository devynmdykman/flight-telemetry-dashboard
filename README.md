# Flight Telemetry Dashboard
Author: Devyn Dykman
Project: Flight Telemetry Transformation & Dashboard
Tools: DuckDB, SQL, Python, Streamlit, Plotly

-- Overview --

This project transforms raw CX300 flight telemetry data into a flight-level analytical view and provides an interactive dashboard for exploring individual flights.

The primary goal is to make common flight-level questions easy to answer without requiring users to reason directly over raw telemetry signals.

Examples:
- When did each flight start and end?
- How far did it fly?
- What were the max altitude, airspeed, and climb rate?
- Where did the flight originate and land?

All core transformations are implemented as SQL views inside DuckDB, ensuring transparency, reproducibility, and ease of review.

-- Data Provided --

Tables:

Telemetry
---------
Column	|   Type	 |   Description
----------------------------------------------------
time	|  string	 |   Timestamp of measurement
signal	|  varchar	 |   One of latitude, longitude, altitude, airspeed
value	|  double	 |   Signal value

Airports
---------
Column	    |   Type	 |   Description
-----------------------------------------
code	    |   varchar	 |   Airport code
name	    |   varchar	 |   Airport name
country	    |   varchar	 |   Country
latitude    |	double	 |   Degrees
longitude   |	double	 |   Degrees


-- Transformation Approach (Part 1) -- 

Key Design Choices:

- SQL-first transformations using DuckDB views
- Stepwise pipeline for inspectability
- Conservative handling of noisy or missing telemetry
- Explicit handling of units and time

Pipeline Summary:

1. Pivot telemetry to wide format
    - One row per timestamp with latitude, longitude, altitude, airspeed
    - Missing signals become NULLs

2. Detect in-flight segments
    - in_flight = TRUE when altitude OR airspeed exceeds conservative thresholds

3. Segment flights
    - Use transitions from in_flight = FALSE → TRUE to identify new flights
    - Assign monotonically increasing flight_number

4. Filter noise
    - Remove segments shorter than 2 minutes to eliminate sensor spikes and artifacts

5. Compute flight-level metrics
    - Distance (nautical miles) using Haversine formula
    - Max altitude (ft)
    - Max airspeed (knots)
    - Max climb rate (ft/min) using LAG-based differencing

6. Infer origin and destination
    - Nearest airport to first and last telemetry point per flight

Final Output:

flight_summary
---------------
Column               |      Description
--------------------------------------------------
flight_number	     |      Sequential flight ID
start_time	     |      Flight start timestamp
end_time	     |      Flight end timestamp
distance	     |      Nautical miles
max_airspeed	     |      Knots
max_altitude	     |      Feet
max_climb_rate	     |      Feet per minute
origin_airport	     |      Airport code
destination_airport  |      Airport code

This view enables quick, reliable answers to flight-level questions without re-processing raw telemetry.

-- Dashboard (Part 2) --

The Streamlit dashboard provides a single-screen overview of a selected flight.

Features
- Flight selector (dropdown)
- KPI summary from flight_summary
- Time-series plots:
    - Altitude vs time
    - Airspeed vs time
- Flight path visualization (latitude vs longitude)
- Flight Health Checks:
    - Missing altitude or airspeed samples
    - Negative airspeed values
    - Extreme climb/descent rates
- Units toggle (SI ↔ aviation units)

Purpose:
The dashboard is designed not only to visualize data, but also to surface data quality considerations, which are critical in real-world telemetry analytics.

Handling Missing Data:
- Missing altitude or airspeed samples are expected due to independent sensor sampling
- NULLs are preserved and surfaced, not silently dropped or imputed
- Aggregations ignore NULLs by default (safe for max metrics)
- Climb rate is computed only where consecutive valid samples exist
- Data quality indicators are displayed in the dashboard

-- How to Run --

Requirements:

Python 3.10+

Provided DuckDB file: analytics-engineering-challenge.db
-- Make sure to cd to project root: cd /path/to/analytics-engineering-challenge --

1. Create a virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install duckdb pandas streamlit plotly

2. Create the working database
cp analytics-engineering-challenge.db beta_submission.duckdb

3. Run transformations
python3 run_transform.py

This executes all SQL files and builds the flight_summary view.

4. Launch the dashboard
streamlit run dashboard/app.py

-- Open the URL printed by Streamlit --
