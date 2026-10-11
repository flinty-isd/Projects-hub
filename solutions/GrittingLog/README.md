# Gritting Log

Replaces the legacy InfoPath "Gritting Log" form (real inventory: 2 pages,
47 fields, 34 rules, 18 conditions, 100 actions, 1 notification workflow —
see [`../../docs/infopath-migration/triage.md`](../../docs/infopath-migration/triage.md)).

## ⚠️ Field list is inferred, not extracted

**The inventory spreadsheet only has field/rule/action *counts* for this
form, not the actual field names or logic.** The schema below is a
best-effort reconstruction from the form's name and domain (a port/site
winter-maintenance log): a shift records the weather conditions and which
yard/road/walkway areas were gritted (salted) against ice, typically across
several site locations per entry.

It models **9 header fields + a repeating areas-gritted table against a
real count of 47 total fields** — the real form, at 47 fields for a "log",
most likely tracks considerably more site areas per entry or more detail
per area than modeled here. Treat this as a starting skeleton to correct
once the real form is available, not a finished migration.

## Folders

| Folder | Contents |
|---|---|
| `sharepoint/` | List schema: log header + repeating areas gritted (inferred — see above) |
| `powerapps/` | Canvas app source: log entry form |
| `powerautomate/` | Notification flow — alerts if any safety-critical area was left ungritted |
