-- 07_distance.sql
-- Purpose:
-- Compute total flight distance by summing point-to-point distances along the trajectory.
-- For each point, compute segment distance to the previous lat/lon using the Haversine formula.
-- Sum segment distances per flight.
--
-- Distance units:
-- - Earth radius ~ 6,371,000 meters
-- - Convert meters -> nautical miles by dividing by 1852.

CREATE OR REPLACE VIEW telemetry_with_segments AS
WITH base AS (
  SELECT
    flight_number,
    CAST(time AS TIMESTAMPTZ) AS ts,
    latitude,
    longitude
  FROM telemetry_clean
),
lagged AS (
  SELECT
    *,
    LAG(latitude)  OVER (PARTITION BY flight_number ORDER BY ts) AS prev_lat,
    LAG(longitude) OVER (PARTITION BY flight_number ORDER BY ts) AS prev_lon
  FROM base
)
SELECT
  flight_number,
  ts,
  latitude,
  longitude,
  CASE
    -- First point has no segment distance
    WHEN prev_lat IS NULL OR prev_lon IS NULL THEN 0.0
    ELSE
      2.0 * 6371000.0 * ASIN(
        SQRT(
          POWER(SIN(RADIANS(latitude - prev_lat) / 2.0), 2)
          + COS(RADIANS(prev_lat)) * COS(RADIANS(latitude))
          * POWER(SIN(RADIANS(longitude - prev_lon) / 2.0), 2)
        )
      ) / 1852.0
  END AS segment_distance_nm
FROM lagged;

CREATE OR REPLACE VIEW flight_distance AS
SELECT
  flight_number,
  SUM(segment_distance_nm) AS distance_nm
FROM telemetry_with_segments
GROUP BY flight_number;

