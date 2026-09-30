"""Map raw Microsoft Graph SharePoint list items onto the normalized
columns the dashboard renders.

SharePoint list internal field names vary per site/list template. If your
list uses different internal names than the defaults below, edit
TASK_FIELD_MAP / RISK_FIELD_MAP to match (find internal names via
Graph Explorer: GET /sites/{site-id}/lists/{list-id}/columns).
"""

import pandas as pd

TASK_FIELD_MAP = {
    "title": "Title",
    "status": "Status",
    "assigned_to": "AssignedTo",
    "start_date": "StartDate",
    "due_date": "DueDate",
    "percent_complete": "PercentComplete",
    "priority": "Priority",
}

RISK_FIELD_MAP = {
    "title": "Title",
    "severity": "Severity",
    "owner": "Owner",
    "status": "Status",
    "description": "Description",
}

TASK_COLUMNS = list(TASK_FIELD_MAP.keys())
RISK_COLUMNS = list(RISK_FIELD_MAP.keys())


def _extract_person(value):
    """SharePoint person fields can come back as a string, a dict with
    LookupValue/DisplayName, or a list of such dicts (multi-select)."""
    if value is None:
        return ""
    if isinstance(value, list):
        return ", ".join(_extract_person(v) for v in value if v)
    if isinstance(value, dict):
        return value.get("LookupValue") or value.get("DisplayName") or value.get("Email") or ""
    return str(value)


def _extract_percent(value):
    if value in (None, ""):
        return 0.0
    try:
        pct = float(value)
    except (TypeError, ValueError):
        return 0.0
    return pct / 100.0 if pct > 1 else pct


def _items_to_dataframe(items, field_map, columns):
    rows = []
    for item in items:
        fields = item.get("fields", item)
        row = {key: fields.get(source_field) for key, source_field in field_map.items()}
        rows.append(row)
    df = pd.DataFrame(rows, columns=columns)
    if df.empty:
        return df

    if "assigned_to" in df.columns:
        df["assigned_to"] = df["assigned_to"].apply(_extract_person)
    if "owner" in df.columns:
        df["owner"] = df["owner"].apply(_extract_person)
    if "percent_complete" in df.columns:
        df["percent_complete"] = df["percent_complete"].apply(_extract_percent)
    for date_col in ("start_date", "due_date"):
        if date_col in df.columns:
            df[date_col] = pd.to_datetime(df[date_col], errors="coerce")
    for text_col in ("title", "status", "priority", "severity", "description"):
        if text_col in df.columns:
            df[text_col] = df[text_col].fillna("").astype(str)
    return df


def tasks_from_graph_items(items):
    return _items_to_dataframe(items, TASK_FIELD_MAP, TASK_COLUMNS)


def risks_from_graph_items(items):
    return _items_to_dataframe(items, RISK_FIELD_MAP, RISK_COLUMNS)
