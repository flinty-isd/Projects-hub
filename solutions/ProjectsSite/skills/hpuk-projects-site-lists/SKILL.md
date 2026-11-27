---
name: hpuk-projects-site-lists
description: Creates the HPUK project SharePoint lists on a projects site (e.g. /sites/hpuk-pof-projects), from the schemas the flows and pages are built on. Three sets, any combination - Enterprise PMO hub (10 lists - Workstreams, Master RAID Log, Action and Decision Tracker, Change Requests, governance calendar, document libraries, PMO audit lists), Project Control Centre (6 SP_ lists - Migration Register, Page Delivery, Actions, RAID, Decisions, Project Updates) and the Control Board lists for portal flow P2 (Programme Status, Board Decisions, Programme RAID, Migration Waves, Programme Gates). Use it whenever David asks to create, set up, provision, rebuild or check the project lists or a projects site, to add a missing column, to say which lists or columns a set needs, or why a list creation failed - even when no set is named, e.g. "set up the lists on the projects site", "create all the lists", "the RAID list is missing a column". Not for the governance, news or asset lists, or for building pages, views or flows.
---

# HPUK projects site lists

You set up the SharePoint lists for HPUK's project work on a projects site, exactly as the
repository's schemas describe them, so the flows, pages and Power App built on them work first
time. The schemas in `schemas/` are generated from the solutions (`EnterprisePMO`,
`SharePointControlCentre`, `PortalSnapshots`) and are the only source of truth: never invent,
rename or retype a column. `references/list-sets.md` lists every list and column; read it to
answer "which columns does X have" questions.

## The three sets

| Set | Lists | For |
|---|---|---|
| `pmo` | 10 | Enterprise PMO hub: flows 01-05 and the Portfolio-Governance-Hub page |
| `controlcentre` | 6 (5 created, `SP_MigrationRegister` checked only) | Project Control Centre pages and Power App |
| `board` | 5 | Control Board portal, refreshed by PortalSnapshots flow P2 |

`all` means all three. **They overlap:** each has a RAID log and a decisions list (and two have
actions lists). Before creating more than one set on the same site, say so in one line and ask
which list is the master for RAID and for decisions; record the answer in your summary. Don't
refuse, it's David's call.

## How you work

1. **Confirm the site and the sets.** Ask for the full site URL if you don't have it. Don't
   guess a site: the wrong one gets 20 lists it doesn't want. If David says "all the lists",
   that's `all`, with the overlap question above.
2. **Plan offline.** Run `python scripts/plan_lists.py --sets <sets>` (e.g. `--sets pmo,board`)
   and show the result in short form: lists to create, any overlap warnings. If it reports
   schema problems, stop: the fix belongs in the source schema in the repository, then the skill
   is rebuilt (`ProjectsSite/tools/build_skill.py`).
3. **Check you can run it.** Creating lists needs PowerShell 7 with PnP.PowerShell 2.x on a
   machine signed in as a Site Owner of the site. If you have a shell there (Claude Code on
   David's machine), check with `pwsh -c "Get-Module PnP.PowerShell -ListAvailable"`. If you
   can't run it (chat, or no PnP), give David the two commands below to run himself and tell
   him what to send back (the summary table).
4. **Dry run.** Always first:
   ```powershell
   ./scripts/Provision-ProjectLists.ps1 -SiteUrl <site> -Sets <sets> -Interactive -PlanOnly
   ```
   It connects and lists what it would create or add, changing nothing. Show David the result.
5. **Get a clear yes, then run** the same command without `-PlanOnly`. Creating lists changes a
   live site that other people use, so a yes to the plan is needed every time; a yes on another
   site or an earlier day doesn't count.
6. **Report** from the script's summary table: per list `created`, `exists`,
   `exists: columns added` or `MISSING`. Then the follow-on steps it prints for each set (views
   and page for `pmo`, formatting and pages for `controlcentre`, the flow setting for `board`).

The script is safe to re-run: it only adds what's missing. It never deletes or changes an
existing list, column, view or item, and never creates or renames `SP_MigrationRegister`
(a live list; only missing columns are added to it).

## Rules

- Named accounts only: run as David or the site owner, or a registered app; never a shared or
  service account (D-03).
- Test site first when the site is new or the set hasn't been created anywhere before.
- Don't change a list by hand to "fix" a difference from the schema. Report it; the schema
  change goes through the repository (and the flows' validators) first.
- Never delete a list or column, even an empty one, as part of this skill. If David wants one
  removed, tell him what uses it (from `references/list-sets.md`) and let him do it.
- Flow-managed columns (marked in the reference) are hidden from forms on purpose. Don't unhide
  them.

## When it fails

| Error | Cause | Fix |
|---|---|---|
| Access denied / 403 | Not a Site Owner | Run as a Site Owner, or ask for the role |
| `A list, survey, discussion board, or document library with the specified title already exists` / URL in use | A different list already uses that URL | Rename or move the other list, or ask whether it is the same list under another title |
| `Lookup ... needs list 'PMO Workstreams'` | The lookup target failed or was skipped | Fix the first error and re-run; lookups resolve on the next run |
| `SP_MigrationRegister not found` | Wrong site, or the register hasn't been imported | Check the site URL; the register is imported from its workbook, never created here |
| `Connect-PnPOnline` fails | PnP not installed, or the tenant needs an app registration for interactive sign-in | `Install-Module PnP.PowerShell -Scope CurrentUser`; use `-ClientId` with the tenant's PnP app registration |
| Script stops part-way | Network or throttling | Re-run: completed lists and columns are skipped |

## Keep it short

Lead with what happened (or will happen) in one or two sentences, then the table. Don't repeat
the plan after the real run unless something differed from it.
