-- 04_valid_flights.sql
-- Purpose:
-- The transition-based approach can produce tiny "flights" due to brief spikes or gaps.
-- To remove noise, I filter out segments shorter than 2 minutes.
-- This yields a clean set of "valid_flights" that we use for all summary metrics.
--
-- Note: telemetry time is stored as a string, so I cast to TIMESTAMPTZ
-- to do proper time arithmetic.

CREATE OR REPLACE VIEW valid_flights AS
SELECT
  flight_number,
  MIN(CAST(time AS TIMESTAMPTZ)) AS start_time,
  MAX(CAST(time AS TIMESTAMPTZ)) AS end_time,
  DATE_DIFF(
    'second',
    MIN(CAST(time AS TIMESTAMPTZ)),
    MAX(CAST(time AS TIMESTAMPTZ))
  ) AS duration_seconds
FROM telemetry_labeled
GROUP BY flight_number
HAVING DATE_DIFF(
  'second',
  MIN(CAST(time AS TIMESTAMPTZ)),
  MAX(CAST(time AS TIMESTAMPTZ))
) >= 120;

-- telemetry_clean = only telemetry points that belong to valid flights.
CREATE OR REPLACE VIEW telemetry_clean AS
SELECT t.*
FROM telemetry_labeled t
JOIN valid_flights v
  USING (flight_number);

