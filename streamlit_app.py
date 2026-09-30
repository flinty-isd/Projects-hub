import pandas as pd
import plotly.express as px
import streamlit as st

import kpis
import mock_data
from data_transform import risks_from_graph_items, tasks_from_graph_items
from sharepoint_client import SharePointClient, load_config_from_secrets

st.set_page_config(page_title="SharePoint PM Dashboard", layout="wide")


@st.cache_data(ttl=300)
def load_live_data(_client: SharePointClient):
    tasks_df = tasks_from_graph_items(_client.get_tasks())
    risks_df = risks_from_graph_items(_client.get_risks())
    return tasks_df, risks_df


def load_data():
    config = load_config_from_secrets()
    if config is None:
        return mock_data.sample_tasks(), mock_data.sample_risks(), False, None
    try:
        client = SharePointClient(config)
        tasks_df, risks_df = load_live_data(client)
        return tasks_df, risks_df, True, None
    except Exception as exc:  # connection/auth/schema issues fall back to demo data
        return mock_data.sample_tasks(), mock_data.sample_risks(), False, str(exc)


st.title("📊 SharePoint PM Dashboard")

tasks_df, risks_df, is_live, load_error = load_data()

if load_error:
    st.warning(f"Couldn't load live SharePoint data, showing demo data instead: {load_error}")
elif not is_live:
    st.info(
        "Demo mode — showing sample data. Add SharePoint credentials to `.streamlit/secrets.toml` "
        "(see README.md) to connect a live site."
    )
else:
    st.success("Connected to live SharePoint data.")
    if st.button("Refresh data"):
        st.cache_data.clear()
        st.rerun()

with st.sidebar:
    st.header("Filters")
    status_options = sorted(tasks_df["status"].unique()) if not tasks_df.empty else []
    owner_options = sorted(tasks_df["assigned_to"].unique()) if not tasks_df.empty else []
    status_filter = st.multiselect("Status", status_options, default=status_options)
    owner_filter = st.multiselect("Owner", owner_options, default=owner_options)

filtered_tasks = tasks_df
if not tasks_df.empty:
    filtered_tasks = tasks_df[
        tasks_df["status"].isin(status_filter) & tasks_df["assigned_to"].isin(owner_filter)
    ]

tab_overview, tab_timeline, tab_kpis, tab_risks = st.tabs(
    ["Overview", "Timeline", "KPIs", "Risks & Issues"]
)

with tab_overview:
    st.subheader("Tasks")
    st.dataframe(filtered_tasks, use_container_width=True, hide_index=True)
    if not filtered_tasks.empty:
        status_counts = kpis.tasks_by_status(filtered_tasks)
        st.plotly_chart(
            px.bar(status_counts, x="status", y="count", title="Tasks by status"),
            use_container_width=True,
        )

with tab_timeline:
    st.subheader("Project timeline")
    timeline_df = filtered_tasks.dropna(subset=["start_date", "due_date"])
    if timeline_df.empty:
        st.info("No tasks with both a start and due date to plot.")
    else:
        fig = px.timeline(
            timeline_df,
            x_start="start_date",
            x_end="due_date",
            y="title",
            color="status",
            title="Task timeline",
        )
        fig.update_yaxes(autorange="reversed")
        st.plotly_chart(fig, use_container_width=True)

with tab_kpis:
    st.subheader("Progress & KPIs")
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Total tasks", len(filtered_tasks))
    col2.metric("Avg % complete", f"{kpis.average_percent_complete(filtered_tasks)}%")
    col3.metric("Overdue tasks", kpis.overdue_count(filtered_tasks, pd.Timestamp.now()))
    col4.metric("Open risks", kpis.open_risk_count(risks_df))

    if not filtered_tasks.empty:
        owner_counts = kpis.tasks_by_owner(filtered_tasks)
        st.plotly_chart(
            px.bar(owner_counts, x="assigned_to", y="count", title="Tasks by owner"),
            use_container_width=True,
        )

with tab_risks:
    st.subheader("Risks & issues")
    st.dataframe(risks_df, use_container_width=True, hide_index=True)
    if not risks_df.empty:
        severity_counts = risks_df["severity"].value_counts().reset_index()
        severity_counts.columns = ["severity", "count"]
        st.plotly_chart(
            px.bar(severity_counts, x="severity", y="count", title="Risks by severity"),
            use_container_width=True,
        )
