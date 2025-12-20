-- 02_flag_in_flight.sql
-- Purpose:
-- Define an in_flight flag to separate airborne segments from noise
-- I intentionally use BOTH altitude and airspeed (redundancy) because either sensor can be missing/noisy
-- Rule: in_flight if altitude > 100m OR airspeed > 30m/s
-- These thresholds are conservative and meant to capture clearly airborne flight 

CREATE OR REPLACE VIEW telemetry_flagged AS
SELECT
  *,
  CASE
    WHEN altitude > 100
      OR airspeed > 30
    THEN TRUE
    ELSE FALSE
  END AS in_flight
FROM telemetry_wide;
