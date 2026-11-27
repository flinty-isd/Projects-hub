# Projects site lists

A Claude skill, **hpuk-projects-site-lists**, that creates the HPUK project lists on a
SharePoint projects site (for example `/sites/hpuk-pof-projects`).

The lists come from the repository's own schemas, so the flows, pages and Power App built on
them work against the columns they expect. There are three sets, and each run can create any
combination:

| Set | Lists | Source |
|---|---|---|
| `pmo` | 10: Enterprise PMO hub | `EnterprisePMO/sharepoint/list-schema.json` |
| `controlcentre` | 6: Project Control Centre (`SP_MigrationRegister` is checked only) | `SharePointControlCentre/sharepoint/list-schema.json` |
| `board` | 5: Control Board lists for portal flow P2 | `PortalSnapshots/sharepoint/list-schema.json` (lists on the Control Board site only) |

The sets overlap. Each has a RAID log and a decisions list, so the skill asks which list is the
master before it creates more than one set on a site.

## Layout

```
ProjectsSite/
├── skills/hpuk-projects-site-lists/
│   ├── SKILL.md                        how Claude runs it: confirm, plan, dry run, yes, run, report
│   ├── scripts/plan_lists.py           offline plan and schema check (no SharePoint connection)
│   ├── scripts/Provision-ProjectLists.ps1  creates lists and missing columns; -PlanOnly changes nothing
│   ├── schemas/                        generated: pmo.json, controlcentre.json, board.json, catalogue.json
│   └── references/list-sets.md         generated: every list and column, and what uses it
└── tools/build_skill.py                regenerates schemas/ and references/; --check for CI; --zip to package
```

## Using it

**In Claude Code** on a machine with PowerShell 7 and PnP.PowerShell, copy or link the skill
folder into `~/.claude/skills/` (or the project's `.claude/skills/`). Then ask Claude to "create
the lists on the projects site". Claude:

1. confirms the site and sets
2. shows the offline plan and the dry run
3. waits for your yes
4. runs the script and reports the summary

**On claude.ai**, upload `hpuk-projects-site-lists.zip`, built with `--zip`, under *Settings >
Capabilities > Skills*. Claude can't reach SharePoint from there, so it plans and gives you the
commands to run yourself.

**Without Claude**, run the script directly:

```powershell
cd skills/hpuk-projects-site-lists
python scripts/plan_lists.py --sets pmo,board
./scripts/Provision-ProjectLists.ps1 -SiteUrl https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects -Sets pmo,board -ClientId <pnp-app-id> -Interactive -PlanOnly
./scripts/Provision-ProjectLists.ps1 -SiteUrl https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects -Sets pmo,board -ClientId <pnp-app-id> -Interactive
```

## Behaviour

- **Safe to re-run.** The script creates missing lists and adds missing columns only. It never
  deletes or changes an existing list, column, view or item.
- **`SP_MigrationRegister` is never created or renamed.** It is a live list imported from its
  workbook, so the script only adds any missing columns to it.
- **Column details follow the schemas.** Types, choices, defaults, required columns, date-only
  dates, decimals, lookups, link columns, indexes and renamed Title columns all come from the
  schema. Flow-managed columns are hidden from the new and edit forms.
- **Lists only.** The PMO hub's views, formatting and page still come from
  `EnterprisePMO/provisioning/Provision-PMOHub.ps1`, which skips lists that already exist. Both
  scripts can run on the same site, in either order.

## Keeping it in step

Change a list in its own solution's `list-schema.json`, where the flows' validators check it.
Then run:

```
python solutions/ProjectsSite/tools/build_skill.py
python solutions/ProjectsSite/skills/hpuk-projects-site-lists/scripts/plan_lists.py --check
```

CI (`.github/workflows/projects-site-skill.yml`) fails if the skill's copies are out of date or
a schema uses something the script can't create. **Not yet run against a tenant.** The offline
plan has been run against all three sets. The PowerShell script hasn't been run or parsed here,
because no PowerShell was available. Use `-PlanOnly` on a test site first.
