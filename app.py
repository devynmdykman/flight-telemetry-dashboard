import streamlit as st
import duckdb
import pandas as pd
import plotly.express as px

def m_to_ft(m: float) -> float:
    return m * 3.28084

def ms_to_knots(ms: float) -> float:
    return ms * 1.94384

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
use_aviation_units = st.toggle("Use aviation units (ft, knots)", value=True)

summary = get_flight_summary(int(flight_number)).iloc[0]
ts = get_flight_timeseries(int(flight_number))

# Ensure ts is sorted
ts = ts.sort_values("ts")

# Add conversions for charting
ts["altitude_ft"] = ts["altitude"] * 3.28084
ts["airspeed_knots"] = ts["airspeed"] * 1.94384

# KPIs
c1, c2, c3, c4, c5 = st.columns(5)
c1.metric("Distance (nm)", f"{summary['distance']:.1f}")
c2.metric("Max Altitude (ft)", f"{summary['max_altitude']:.0f}")
c3.metric("Max Airspeed (kts)", f"{summary['max_airspeed']:.1f}")
c4.metric("Max Climb Rate (ft/min)", f"{summary['max_climb_rate']:.0f}")
c5.metric("Route", f"{summary['origin_airport']} → {summary['destination_airport']}")

st.divider()

st.subheader("Flight Health Checks")

# Basic checks
n_points = len(ts)
n_missing_alt = int(ts["altitude"].isna().sum())
n_missing_spd = int(ts["airspeed"].isna().sum())
n_negative_spd = int((ts["airspeed"] < 0).sum())

# Compute climb rate in ft/min from timeseries (simple, explainable)
# (This is for QC display; your official max_climb_rate is from SQL.)
dt_seconds = ts["ts"].diff().dt.total_seconds()
dalt_ft = ts["altitude_ft"].diff()
climb_ft_min = dalt_ft / (dt_seconds / 60.0)
climb_ft_min = climb_ft_min.replace([float("inf"), float("-inf")], pd.NA)

max_abs_climb = float(climb_ft_min.abs().max(skipna=True)) if climb_ft_min.notna().any() else 0.0

# Heuristic thresholds (simple + defensible)
# Adjust if needed, but these are reasonable "attention" triggers.
CLIMB_RATE_ALERT_FTPM = 4000  # alert if extremely steep climb/descent
NEG_AIRSPEED_ALERT = 1        # any negative airspeed is worth flagging

colA, colB, colC, colD = st.columns(4)

# Status helper
def status_line(ok: bool, ok_msg: str, warn_msg: str):
    if ok:
        st.success(ok_msg)
    else:
        st.warning(warn_msg)

with colA:
    st.caption("Data completeness")
    status_line(n_missing_alt == 0, "Altitude: no missing", f"Altitude: {n_missing_alt} missing")
    status_line(n_missing_spd == 0, "Airspeed: no missing", f"Airspeed: {n_missing_spd} missing")

with colB:
    st.caption("Sensor sanity")
    status_line(n_negative_spd < NEG_AIRSPEED_ALERT, "No negative airspeed", f"{n_negative_spd} negative airspeed samples")

with colC:
    st.caption("Dynamics")
    status_line(max_abs_climb <= CLIMB_RATE_ALERT_FTPM,
                f"Climb/descent ok (max |rate| ≈ {max_abs_climb:.0f} ft/min)",
                f"High climb/descent (max |rate| ≈ {max_abs_climb:.0f} ft/min)")

with colD:
    st.caption("Volume")
    st.info(f"{n_points:,} telemetry points")

with st.expander("Why these checks?"):
    st.write(
        """
        Telemetry is often messy in real systems (dropouts, sensor noise, invalid values).
        These checks highlight common issues:
        - Missing altitude/airspeed samples (gaps)
        - Negative airspeed values (sensor artifact or sign convention)
        - Extremely high climb/descent rates (possible data jitter or timestamp irregularities)
        """
    )

# Charts
left, right = st.columns(2)

with left:
    alt_col = "altitude_ft" if use_aviation_units else "altitude"
    alt_title = "Altitude vs Time (ft)" if use_aviation_units else "Altitude vs Time (m)"

    fig_alt = px.line(ts, x="ts", y=alt_col, title=alt_title)
    st.plotly_chart(fig_alt, use_container_width=True)


with right:
    spd_col = "airspeed_knots" if use_aviation_units else "airspeed"
    spd_title = "Airspeed vs Time (knots)" if use_aviation_units else "Airspeed vs Time (m/s)"

    fig_spd = px.line(ts, x="ts", y=spd_col, title=spd_title)
    st.plotly_chart(fig_spd, use_container_width=True)


fig_path = px.line(
    ts,
    x="longitude",
    y="latitude",
    title="Flight Path (lon vs lat)",
)
st.plotly_chart(fig_path, use_container_width=True)
