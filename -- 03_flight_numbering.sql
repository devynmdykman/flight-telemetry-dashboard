-- 03_flight_numbering.sql
-- Purpose:
-- Turn the in_flight boolean into flight segments by detecting transitions.
-- A flight starts when we go from (not in_flight) -> (in_flight)
-- Then flight_number is just the running total of these start events over time.
-- I only keep in_flight rows here because this is a "strict airborne" definition.

CREATE OR REPLACE VIEW telemetry_labeled AS
WITH flagged AS (
  SELECT
    *,
    -- prev_in_flight lets us detect transitions.
    COALESCE(LAG(in_flight) OVER (ORDER BY time), FALSE) AS prev_in_flight
  FROM telemetry_flagged
),
starts AS (
  SELECT
    *,
    -- flight_start = 1 only at the first row of each flight segment.
    CASE
      WHEN in_flight = TRUE AND prev_in_flight = FALSE THEN 1
      ELSE 0
    END AS flight_start
  FROM flagged
)
SELECT
  *,
  -- Cumulative sum turns start events into sequential flight numbers.
  SUM(flight_start) OVER (ORDER BY time) AS flight_number
FROM starts
WHERE in_flight = TRUE;
