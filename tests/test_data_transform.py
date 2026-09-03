import pandas as pd

from data_transform import risks_from_graph_items, tasks_from_graph_items


def make_task_item(**fields):
    return {"fields": fields}


def test_tasks_from_graph_items_maps_expected_columns():
    items = [
        make_task_item(
            Title="Kickoff",
            Status="Done",
            AssignedTo={"LookupValue": "Alex Rivera"},
            StartDate="2026-07-01T00:00:00Z",
            DueDate="2026-07-10T00:00:00Z",
            PercentComplete=100,
            Priority="High",
        )
    ]
    df = tasks_from_graph_items(items)

    assert list(df.columns) == ["title", "status", "assigned_to", "start_date", "due_date",
                                 "percent_complete", "priority"]
    assert df.loc[0, "title"] == "Kickoff"
    assert df.loc[0, "assigned_to"] == "Alex Rivera"
    assert df.loc[0, "percent_complete"] == 1.0
    assert df.loc[0, "start_date"] == pd.Timestamp("2026-07-01", tz="UTC")


def test_tasks_from_graph_items_handles_missing_fields():
    items = [make_task_item(Title="No metadata yet")]
    df = tasks_from_graph_items(items)

    assert df.loc[0, "title"] == "No metadata yet"
    assert df.loc[0, "assigned_to"] == ""
    assert df.loc[0, "percent_complete"] == 0.0
    assert pd.isna(df.loc[0, "due_date"])


def test_tasks_from_graph_items_empty_list():
    df = tasks_from_graph_items([])
    assert df.empty
    assert list(df.columns) == ["title", "status", "assigned_to", "start_date", "due_date",
                                 "percent_complete", "priority"]


def test_risks_from_graph_items_maps_expected_columns():
    items = [
        make_task_item(
            Title="Legacy forms",
            Severity="High",
            Owner={"DisplayName": "Priya Shah"},
            Status="Open",
            Description="Needs rework",
        )
    ]
    df = risks_from_graph_items(items)

    assert df.loc[0, "title"] == "Legacy forms"
    assert df.loc[0, "owner"] == "Priya Shah"
    assert df.loc[0, "severity"] == "High"
