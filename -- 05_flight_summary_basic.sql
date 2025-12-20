-- 05_flight_summary_basic.sql
-- Purpose:
-- Build the "easy wins" of the flight summary:
-- - start_time / end_time per flight
-- - max altitude, max airspeed
--
-- Conversions:
-- - meters -> feet: * 3.28084
-- - m/s -> knots:  * 1.94384

CREATE OR REPLACE VIEW flight_summary_basic AS
SELECT
  flight_number,
  MIN(CAST(time AS TIMESTAMPTZ)) AS start_time,
  MAX(CAST(time AS TIMESTAMPTZ)) AS end_time,
  MAX(altitude) * 3.28084 AS max_altitude_ft,
  MAX(airspeed) * 1.94384 AS max_airspeed_knots
FROM telemetry_clean
GROUP BY flight_number;
