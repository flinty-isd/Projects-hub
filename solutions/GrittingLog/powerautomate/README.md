# Gritting Log — Power Automate flow

The real inventory lists exactly one associated workflow:
**"Gritting Log Notification Workflow 2010"** — 1 variable, 3 steps, 2
conditions, 3 actions, 2 estimated rebuild-hours. That shape (a couple of
conditions, few actions) matches an exception alert rather than a routine
notification: most gritting rounds don't need anyone told, only the ones
where a safety-critical area was missed.

`flows/Notify-IncompleteGritting.json` reconstructs that as: check whether
any area in the submitted log is both `SafetyCritical` and not `Completed`;
if so, alert the site/duty manager and set `AllAreasComplete = false` on the
header; otherwise the flow ends without action. This is a reconstruction
from the step/condition/action counts, not the real flow — confirm the
actual recipients and condition logic against the live SharePoint workflow
before this replaces it.
