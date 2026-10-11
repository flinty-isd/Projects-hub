# Vessel Condition Report

Replaces the legacy InfoPath "Vessel Condition Report" form (real inventory:
3 pages, 40 fields, 19 rules, 7 conditions, 37 actions, **no associated
SharePoint workflow** — see [`../../docs/infopath-migration/triage.md`](../../docs/infopath-migration/triage.md)).

## ⚠️ Field list is inferred, not extracted

**The inventory spreadsheet only has field/rule/action *counts* for this
form, not the actual field names or logic.** The schema below is a
best-effort reconstruction from the form's name and domain (a port
operation): an inspector records a vessel's condition on arrival/departure
— hull, deck, mooring and safety equipment condition, and any defects found.

It models **22 header fields + a repeating defects table against a real
count of 40 total fields** — treat it as a starting skeleton to correct
once the real form is available, not a finished migration.

## No workflow — intentionally

Unlike every other solution in this repo, there is **no Power Automate flow
here**. The real inventory records `WORKFLOW PRESENT = N` for this form — it
was pure data capture in InfoPath, with no SharePoint workflow attached.
Don't add an approval/notification flow unless the business actually wants
one; that would be scope creep beyond what the legacy form did.

## Folders

| Folder | Contents |
|---|---|
| `sharepoint/` | List schema: report header + repeating defects (inferred — see above) |
| `powerapps/` | Canvas app source: report form |
