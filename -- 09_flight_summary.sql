-- 09_flight_summary.sql
-- Purpose:
-- Assemble the final required view by joining the individual per-flight components:
-- - basic start/end + max altitude/speed
-- - total distance
-- - max climb rate
-- - origin/destination airports
--
-- This yields one row per flight with the exact schema requested in the prompt.

CREATE OR REPLACE VIEW flight_summary AS
SELECT
  b.flight_number::INT AS flight_number,
  b.start_time,
  b.end_time,
  d.distance_nm AS distance,                 -- nautical miles
  b.max_airspeed_knots AS max_airspeed,      -- knots
  b.max_altitude_ft AS max_altitude,         -- feet
  c.max_climb_rate_ft_min AS max_climb_rate, -- ft/min
  o.origin_airport,
  x.destination_airport
FROM flight_summary_basic b
LEFT JOIN flight_distance d    USING (flight_number)
LEFT JOIN flight_climb c       USING (flight_number)
LEFT JOIN flight_origin o      USING (flight_number)
LEFT JOIN flight_destination x USING (flight_number)
ORDER BY b.flight_number;
