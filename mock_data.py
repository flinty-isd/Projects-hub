"""Sample project data used in demo mode and in tests, matching the
normalized schema produced by data_transform.py."""

import pandas as pd


def sample_tasks() -> pd.DataFrame:
    return pd.DataFrame(
        [
            {"title": "Define project charter", "status": "Done", "assigned_to": "Alex Rivera",
             "start_date": "2026-07-01", "due_date": "2026-07-10", "percent_complete": 1.0, "priority": "High"},
            {"title": "Stakeholder kickoff", "status": "Done", "assigned_to": "Alex Rivera",
             "start_date": "2026-07-10", "due_date": "2026-07-14", "percent_complete": 1.0, "priority": "High"},
            {"title": "Requirements gathering", "status": "In Progress", "assigned_to": "Priya Shah",
             "start_date": "2026-07-14", "due_date": "2026-08-01", "percent_complete": 0.8, "priority": "High"},
            {"title": "Site migration plan", "status": "In Progress", "assigned_to": "Priya Shah",
             "start_date": "2026-07-20", "due_date": "2026-08-15", "percent_complete": 0.5, "priority": "Medium"},
            {"title": "Content inventory", "status": "In Progress", "assigned_to": "Jordan Lee",
             "start_date": "2026-07-25", "due_date": "2026-08-10", "percent_complete": 0.6, "priority": "Medium"},
            {"title": "Permissions mapping", "status": "Not Started", "assigned_to": "Jordan Lee",
             "start_date": "2026-08-05", "due_date": "2026-08-20", "percent_complete": 0.0, "priority": "Medium"},
            {"title": "Pilot migration batch", "status": "Not Started", "assigned_to": "Sam Okafor",
             "start_date": "2026-08-15", "due_date": "2026-08-25", "percent_complete": 0.0, "priority": "High"},
            {"title": "User training sessions", "status": "Not Started", "assigned_to": "Sam Okafor",
             "start_date": "2026-08-20", "due_date": "2026-09-05", "percent_complete": 0.0, "priority": "Low"},
            {"title": "Cutover checklist", "status": "Not Started", "assigned_to": "Alex Rivera",
             "start_date": "2026-08-01", "due_date": "2026-08-05", "percent_complete": 0.0, "priority": "High"},
            {"title": "Post-migration validation", "status": "Not Started", "assigned_to": "Priya Shah",
             "start_date": "2026-09-01", "due_date": "2026-09-10", "percent_complete": 0.0, "priority": "Medium"},
        ]
    ).assign(
        start_date=lambda df: pd.to_datetime(df["start_date"]),
        due_date=lambda df: pd.to_datetime(df["due_date"]),
    )


def sample_risks() -> pd.DataFrame:
    return pd.DataFrame(
        [
            {"title": "Legacy list templates not supported", "severity": "High", "owner": "Priya Shah",
             "status": "Open", "description": "Custom InfoPath forms have no direct SharePoint Online equivalent."},
            {"title": "Tenant storage quota", "severity": "Medium", "owner": "Sam Okafor",
             "status": "Open", "description": "Combined library size may exceed default site quota."},
            {"title": "Third-party workflow add-in", "severity": "High", "owner": "Jordan Lee",
             "status": "Open", "description": "Nintex workflows need to be rebuilt in Power Automate."},
            {"title": "User adoption resistance", "severity": "Low", "owner": "Alex Rivera",
             "status": "Mitigated", "description": "Early training sessions well received in pilot group."},
            {"title": "Downtime during cutover", "severity": "Medium", "owner": "Alex Rivera",
             "status": "Open", "description": "Cutover window needs off-hours scheduling."},
        ]
    )
