--01_telemetry_wide.sql
--Purpose:
--Display telemetry analytics 

CREATE OR REPLACE VIEW telemetry_wide AS
SELECT
  time,

  MAX(CASE WHEN signal = 'latitude'  THEN value END) AS latitude,
  MAX(CASE WHEN signal = 'longitude' THEN value END) AS longitude,
  MAX(CASE WHEN signal = 'altitude'  THEN value END) AS altitude,   -- meters
  MAX(CASE WHEN signal = 'airspeed'  THEN value END) AS airspeed    -- m/s
FROM telemetry
GROUP BY time;
