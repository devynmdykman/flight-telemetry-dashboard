-- 08_airports.sql
-- Purpose:
-- Identify origin and destination airports by finding the nearest airport to:
-- - the first telemetry point of the flight (origin)
-- - the last telemetry point of the flight (destination)
--
-- For performance + simplicity I use a squared distance approximation in lat/lon space

CREATE OR REPLACE VIEW flight_endpoints AS
WITH base AS (
  SELECT
    flight_number,
    CAST(time AS TIMESTAMPTZ) AS ts,
    latitude,
    longitude
  FROM telemetry_clean
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY flight_number ORDER BY ts ASC)  AS rn_start,
    ROW_NUMBER() OVER (PARTITION BY flight_number ORDER BY ts DESC) AS rn_end
  FROM base
)
SELECT
  flight_number,
  MAX(CASE WHEN rn_start = 1 THEN latitude END)  AS start_lat,
  MAX(CASE WHEN rn_start = 1 THEN longitude END) AS start_lon,
  MAX(CASE WHEN rn_end   = 1 THEN latitude END)  AS end_lat,
  MAX(CASE WHEN rn_end   = 1 THEN longitude END) AS end_lon
FROM ranked
GROUP BY flight_number;

CREATE OR REPLACE VIEW flight_origin AS
SELECT
  e.flight_number,
  a.code AS origin_airport
FROM flight_endpoints e
CROSS JOIN airports a
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY e.flight_number
  ORDER BY
    (e.start_lat - a.latitude)*(e.start_lat - a.latitude)
  + (e.start_lon - a.longitude)*(e.start_lon - a.longitude)
) = 1;

CREATE OR REPLACE VIEW flight_destination AS
SELECT
  e.flight_number,
  a.code AS destination_airport
FROM flight_endpoints e
CROSS JOIN airports a
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY e.flight_number
  ORDER BY
    (e.end_lat - a.latitude)*(e.end_lat - a.latitude)
  + (e.end_lon - a.longitude)*(e.end_lon - a.longitude)
) = 1;
