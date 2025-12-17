-- 06_climb_rate.sql
-- Purpose:
-- Compute climb rate (ft/min) from altitude changes over time.
-- For each flight, I look at altitude at time t and the previous altitude at t-1
-- using LAG(). Then:
-- climb_rate_ft_min = (delta altitude in ft) / (delta time in minutes)
-- Finally, max_climb_rate is the maximum climb_rate during that flight.

CREATE OR REPLACE VIEW telemetry_with_climb AS
WITH base AS (
  SELECT
    flight_number,
    CAST(time AS TIMESTAMPTZ) AS ts,
    altitude * 3.28084 AS altitude_ft
  FROM telemetry_clean
),
lagged AS (
  SELECT
    *,
    LAG(altitude_ft) OVER (PARTITION BY flight_number ORDER BY ts) AS prev_altitude_ft,
    LAG(ts)          OVER (PARTITION BY flight_number ORDER BY ts) AS prev_ts
  FROM base
)
SELECT
  flight_number,
  ts,
  altitude_ft,
  CASE
    -- First point in a flight has no previous point
    WHEN prev_altitude_ft IS NULL THEN NULL
    -- Guard against duplicate timestamps or bad ordering
    WHEN DATE_DIFF('second', prev_ts, ts) <= 0 THEN NULL
    ELSE (altitude_ft - prev_altitude_ft)
         / (DATE_DIFF('second', prev_ts, ts) / 60.0)
  END AS climb_rate_ft_min
FROM lagged;

CREATE OR REPLACE VIEW flight_climb AS
SELECT
  flight_number,
  MAX(climb_rate_ft_min) AS max_climb_rate_ft_min
FROM telemetry_with_climb
GROUP BY flight_number;

