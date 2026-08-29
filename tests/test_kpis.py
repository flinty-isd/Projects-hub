import pandas as pd

import kpis


def tasks_df(rows):
    return pd.DataFrame(rows)


def test_average_percent_complete():
    df = tasks_df([
        {"percent_complete": 1.0},
        {"percent_complete": 0.5},
        {"percent_complete": 0.0},
    ])
    assert kpis.average_percent_complete(df) == 50.0


def test_average_percent_complete_empty():
    assert kpis.average_percent_complete(pd.DataFrame()) == 0.0


def test_overdue_count_excludes_done_tasks():
    today = pd.Timestamp("2026-08-29")
    df = tasks_df([
        {"status": "In Progress", "due_date": pd.Timestamp("2026-08-01")},  # overdue
        {"status": "Done", "due_date": pd.Timestamp("2026-08-01")},  # done, not overdue
        {"status": "Not Started", "due_date": pd.Timestamp("2026-09-01")},  # future
        {"status": "In Progress", "due_date": pd.NaT},  # no due date
    ])
    assert kpis.overdue_count(df, today) == 1


def test_tasks_by_status_counts():
    df = tasks_df([{"status": "Done"}, {"status": "Done"}, {"status": "Open"}])
    result = kpis.tasks_by_status(df).set_index("status")["count"].to_dict()
    assert result == {"Done": 2, "Open": 1}


def test_open_risk_count():
    # "Mitigated" risks are still tracked as open; only Done/Closed statuses
    # are excluded from the open count.
    risks = pd.DataFrame([
        {"status": "Open"},
        {"status": "Mitigated"},
        {"status": "Closed"},
    ])
    assert kpis.open_risk_count(risks) == 2
