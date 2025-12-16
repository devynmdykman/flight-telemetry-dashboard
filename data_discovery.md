## Data discovery (DuckDB)

### Database format
- File is a DuckDB database (not SQLite)

### Tables
- airports (10,670 rows)
  - code, name, country, latitude, longitude
- telemetry (59,591 rows)
  - time (string), signal (string), value (double)

### Telemetry signals
- latitude
- longitude
- altitude
- airspeed

### Observations
- Telemetry data is in long format (one signal per row)
- Some timestamps missing altitude / airspeed
- Negative airspeed values observed
