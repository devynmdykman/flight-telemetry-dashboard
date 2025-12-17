-- 01_telemetry_wide.sql
-- Purpose:
-- The raw telemetry table is in "long" format: one row per (time, signal).
-- For flight analytics, it's easier to work in "wide" format: one row per time
-- with latitude/longitude/altitude/airspeed as columns.

CREATE OR REPLACE VIEW telemetry_wide AS
SELECT
  time,

  -- Pivot signals into columns.
  -- MAX(...) works because for a given (time, signal) there is at most one value.
  MAX(CASE WHEN signal = 'latitude'  THEN value END) AS latitude,
  MAX(CASE WHEN signal = 'longitude' THEN value END) AS longitude,
  MAX(CASE WHEN signal = 'altitude'  THEN value END) AS altitude,   -- meters
  MAX(CASE WHEN signal = 'airspeed'  THEN value END) AS airspeed    -- m/s
FROM telemetry
GROUP BY time;

