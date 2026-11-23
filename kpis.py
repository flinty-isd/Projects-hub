"""Pure functions computing dashboard KPIs from normalized task/risk DataFrames.

Kept separate from streamlit_app.py so they can be unit tested directly,
without going through the Streamlit UI layer.
"""

import pandas as pd

DONE_STATUSES = {"done", "completed", "closed"}


def average_percent_complete(tasks_df: pd.DataFrame) -> float:
    if tasks_df.empty or "percent_complete" not in tasks_df.columns:
        return 0.0
    return round(tasks_df["percent_complete"].mean() * 100, 1)


def overdue_count(tasks_df: pd.DataFrame, as_of: pd.Timestamp) -> int:
    if tasks_df.empty or "due_date" not in tasks_df.columns:
        return 0
    is_done = tasks_df["status"].str.lower().isin(DONE_STATUSES)
    is_overdue = tasks_df["due_date"].notna() & (tasks_df["due_date"] < as_of) & ~is_done
    return int(is_overdue.sum())


def tasks_by_status(tasks_df: pd.DataFrame) -> pd.DataFrame:
    if tasks_df.empty:
        return pd.DataFrame(columns=["status", "count"])
    counts = tasks_df["status"].value_counts().reset_index()
    counts.columns = ["status", "count"]
    return counts


def tasks_by_owner(tasks_df: pd.DataFrame) -> pd.DataFrame:
    if tasks_df.empty:
        return pd.DataFrame(columns=["assigned_to", "count"])
    counts = tasks_df["assigned_to"].value_counts().reset_index()
    counts.columns = ["assigned_to", "count"]
    return counts


def open_risk_count(risks_df: pd.DataFrame) -> int:
    if risks_df.empty or "status" not in risks_df.columns:
        return 0
    is_closed = risks_df["status"].str.lower().isin(DONE_STATUSES)
    return int((~is_closed).sum())
