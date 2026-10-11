# Mis-Declared Empties — Power Automate flow

The real inventory lists exactly one associated workflow for this form:
**"MisDeclared Empties Notification 2013"** — 1 variable, 1 step, 0
conditions, 6 actions, 4 estimated rebuild-hours. That shape (no
conditions, a flat run of actions) matches a pure notification fan-out: no
approval, no branching — just alert every team that needs to know a
container wasn't actually empty. `flows/Notify-MisDeclaredEmpty.json`
reconstructs that as 6 actions: get the submitter's details, then send
notifications to Terminal Operations, Customs, and the shipping line/agent,
and update the item's status to "Under Investigation".

This is a reconstruction from the step/action counts, not the real flow —
the actual recipients, wording, and any extra logic should be confirmed
against the live SharePoint workflow (`.xoml`/workflow history) before this
replaces it.
