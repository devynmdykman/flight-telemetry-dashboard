import streamlit as st
import duckdb
import pandas as pd
import plotly.express as px

DB_PATH = "/Users/devyndykman/Desktop/beta_submission.duckdb"

st.set_page_config(page_title="BETA Flight Dashboard", layout="wide")
st.title("Flight Overview Dashboard")

@st.cache_data
def get_flight_list():
    con = duckdb.connect(DB_PATH, read_only=True)
    df = con.execute("""
        SELECT flight_number
        FROM flight_summary
        ORDER BY flight_number
    """).fetchdf()
    con.close()
    return df["flight_number"].tolist()

@st.cache_data
def get_flight_summary(flight_number: int) -> pd.DataFrame:
    con = duckdb.connect(DB_PATH, read_only=True)
    df = con.execute("""
        SELECT *
        FROM flight_summary
        WHERE flight_number = ?
    """, [flight_number]).fetchdf()
    con.close()
    return df

@st.cache_data
def get_flight_timeseries(flight_number: int) -> pd.DataFrame:
    con = duckdb.connect(DB_PATH, read_only=True)
    df = con.execute("""
        SELECT
          CAST(time AS TIMESTAMPTZ) AS ts,
          latitude,
          longitude,
          altitude,   -- meters
          airspeed    -- m/s
        FROM telemetry_clean
        WHERE flight_number = ?
        ORDER BY ts
    """, [flight_number]).fetchdf()
    con.close()
    return df

flights = get_flight_list()
flight_number = st.selectbox("Select a flight", flights)

summary = get_flight_summary(int(flight_number)).iloc[0]
ts = get_flight_timeseries(int(flight_number))

# KPIs
c1, c2, c3, c4, c5 = st.columns(5)
c1.metric("Distance (nm)", f"{summary['distance']:.1f}")
c2.metric("Max Altitude (ft)", f"{summary['max_altitude']:.0f}")
c3.metric("Max Airspeed (kts)", f"{summary['max_airspeed']:.1f}")
c4.metric("Max Climb Rate (ft/min)", f"{summary['max_climb_rate']:.0f}")
c5.metric("Route", f"{summary['origin_airport']} → {summary['destination_airport']}")

st.divider()

# Charts
left, right = st.columns(2)

with left:
    fig_alt = px.line(
        ts,
        x="ts",
        y="altitude",
        title="Altitude vs Time (meters)",
    )
    st.plotly_chart(fig_alt, use_container_width=True)

with right:
    fig_spd = px.line(
        ts,
        x="ts",
        y="airspeed",
        title="Airspeed vs Time (m/s)",
    )
    st.plotly_chart(fig_spd, use_container_width=True)

fig_path = px.line(
    ts,
    x="longitude",
    y="latitude",
    title="Flight Path (lon vs lat)",
)
st.plotly_chart(fig_path, use_container_width=True)
