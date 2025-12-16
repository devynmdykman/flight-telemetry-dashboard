# Software Challenge

> BETA Technologies Analytics Engineer Challenge

## Instructions

Attached to this coding challenge is a dataset containing telemetry data from
several recent flights of our CX300 aircraft. It is structured as a table in a
[DuckDB](https://duckdb.org/) database file (see the
[persistent storage](https://duckdb.org/docs/stable/clients/python/overview#persistent-storage)
section of the docs for details on how to work with this file type).

```
TABLE telemetry:
    - timestamp: timestamptz
    - signal: varchar
    - value: double
```

The following signals are included:
- latitude: in degrees
- longitude: in degrees
- altitude: in m
- airspeed: in m/s


Additionally, there is a table of airport locations.

```
TABLE airports:
    - code: varchar, the airport code
    - name: varchar, the name of the airport
    - country: varchar, the country of the airport
    - latitude: double, degrees
    - longitude: double, degrees
```


### Part 1: Transformation

Your task is to transform this dataset, producing a new view that will allow
a user to easily answer common flight-level questions.

All transformation should be done in SQL, though Python code is acceptable
if needed. Additional intermediate views can be created if needed.

```
VIEW flight_summary:
  - flight_number: int
  - start_time: timestamp
  - end_time: timestamp
  - distance: double (Nautical miles)
  - max_airspeed: double (Knots)
  - max_altitude: double (ft)
  - max_climb_rate: double (ft/min)
  - origin_airport: varchar (airport code)
  - destination_airport: varchar (airport code)
```

The output should be a duckdb database file that contains the two original
tables, and your view.

### Part 2: Data Dashboard

Create a dashboard that combines data from the summary table and the telemetry
table to give the viewer an overview of a flight on a single screen. What data
to include in the dashboard is at your discretion.

The dashboard should be interactive and allow the user to dynamically switch
between different flights.

You can use any open source tool to create this dashboard.

## Deliverables

### Submission

Please send a zip file to [josh@beta.team](mailto:josh@beta.team)
that contains your full submission to the challenge described above. 

In addition to the code, please attach a brief summary of your solution,
with any supporting documentation we would need to run it. 

Your submission will be evaluated on the following criteria:
- Correctness
- Code simplicity & organization
- Design of presentation
- Documentation of solution

### Presentation

Please plan to present your transformation and dashboard to the team at the technical interview.
You will be able to screen-share. 
You should plan for a 15-minute presentation to ensure we have ample
time for questions and other interview topics. 
Slides are welcome.

As a bonus you are encouraged to do some exploratory analysis of this data
and present any insights that you are able to draw from it.

We're happy to answer any clarifying questions you might have; if you are
confused about the instructions, please don't hesitate to reach out.

Thank you for spending the time to complete this challenge. We are excited to review your submission!
