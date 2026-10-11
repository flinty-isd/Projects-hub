# Mis-Declared Empties

Replaces the legacy InfoPath "Mis-Declared Empties" form (real inventory:
3 pages, 31 fields, 25 rules, 12 conditions, 45 actions, 1 notification
workflow — see [`../../docs/infopath-migration/triage.md`](../../docs/infopath-migration/triage.md)).

## ⚠️ Field list is inferred, not extracted

**The inventory spreadsheet only has field/rule/action *counts* for this
form, not the actual field names or logic.** Nobody has supplied the `.xsn`
template or a walkthrough of the live form yet. The schema below is a
best-effort reconstruction from the form's name and domain (a container
terminal/port operation): a container is declared as empty on its shipping
documentation, but is found on inspection to actually contain cargo,
residue, or to have a weight discrepancy — this form records that exception.

It models **17 fields against a real count of 31** — treat it as a
starting skeleton to correct once the real form is available, not a
finished migration. Before using this in production, get the real field
list and rebuild this schema to match.

## Folders

| Folder | Contents |
|---|---|
| `sharepoint/` | List schema (inferred — see above) |
| `powerapps/` | Canvas app source: report form |
| `powerautomate/` | Notification flow (no approval — this is an exception report, not a request) |
