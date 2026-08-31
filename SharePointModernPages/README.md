# HPUK SharePoint Project Control Centre - modern pages (PnP provisioning)

PnP PowerShell scripts that provision the **real** Implementation
Specification target architecture: SharePoint Lists consumed by native
modern SharePoint pages - not the interim ASP.NET Web Forms app in
`../SharePointReportingDashboard/`. That folder is a Windows/IIS-only
preview tool; this folder is what actually gets deployed into the live
HPUK tenant.

No SharePoint/Microsoft 365 connector is available in the environment
these scripts were written in, so none of this has been run against a
real tenant - it's reviewed, consistent PowerShell, not tested output.
Read a script before running it, and try it against a test site first.

## What gets created

| Script | Creates |
|---|---|
| `scripts/01-Provision-Lists.ps1` | The six authoritative lists and their fields (Implementation Specification §2) |
| `scripts/02-Provision-Views.ps1` | The filtered views each page section needs |
| `scripts/03-Provision-Pages.ps1` | The four modern pages, laid out with those views (Implementation Specification §3) |

All three are **idempotent** - re-running them skips anything that
already exists rather than duplicating it. Run them in order, against the
same site.

## Prerequisites

1. PnP.PowerShell module: `Install-Module -Name PnP.PowerShell -Scope CurrentUser`
2. A SharePoint site to provision into (an existing HPUK project site, or a
   new one) - Site Owner/member permissions with rights to create lists and
   pages.
3. `SP_MigrationRegister` is assumed to already exist live (per
   `HPUK_Migration_Register_Bulk_Update_1.xlsx`, which exports from it) -
   `01-Provision-Lists.ps1` leaves it alone if found and only adds any
   fields it's missing. The other five lists are created fresh if absent.

## Running it

```powershell
$site = "https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects"   # <- your real site
.\scripts\01-Provision-Lists.ps1  -SiteUrl $site
.\scripts\02-Provision-Views.ps1  -SiteUrl $site
.\scripts\03-Provision-Pages.ps1  -SiteUrl $site
```

Each script prompts an interactive sign-in (`Connect-PnPOnline -Interactive`).
For unattended/scheduled runs, switch `Connect-ControlCentreSite` in
`scripts/Common.ps1` to an app-only connection instead.

## List and field names

`SP_MigrationRegister`'s field names (`SiteID`, `SiteTitle` via the Title
field, `SiteURL`, `MigrationStatus`, `ReadinessRAG`, ...) are taken
directly from the real, live list, as seen in the bulk-update workbook's
"Migration Register Update" sheet header row - not invented. Its Choice
field values (`MigrationStatus`, `ReadinessRAG`, `UATStatus`,
`BusinessSignoff`, `MigrationMethod`) are likewise copied from that
workbook's own `Choices` sheet, so a fresh list this script creates (on a
site where it doesn't exist yet) stays consistent with the one already in
production.

The other five lists (`SP_PageDelivery`, `SP_Actions`, `SP_RAID`,
`SP_Decisions`, `SP_ProjectUpdates`) use this script's own naming
convention, since no real internal names for them were available at the
time this was written - `SP_PageDelivery` matches the name used in the
bulk-update workbook's own Instructions sheet ("Page-delivery work remains
in SP_PageDelivery"); the rest are this script's best guess at a
consistent pattern. **If your tenant already has these lists under
different names, rename them at the top of `01-Provision-Lists.ps1`
before running it**, rather than ending up with duplicates.

`Department` and `Wave` choice values in `Common.ps1` are assumed
(reasonable ports-company departments / a generic wave numbering) since
neither document provided an authoritative list - adjust
`$DepartmentChoices` / `$WaveChoices` in `scripts/Common.ps1` to match
reality before running.

## What's fully scripted vs. what needs a manual pass

Fully scripted: page sections, banner text, and every List web part,
bound to a real filtered view of a real list.

Left as a short manual step, and called out on-page where relevant:

- **A single "Attention Required" table blending RAID + Actions + blocked
  sites + decisions.** SharePoint's stock List web part shows one list at
  a time. The script places the equivalent exception views side by side
  instead of faking a merged table - a true merged view would need an
  SPFx web part or a Power Automate flow that copies exceptions into one
  list.
- **A visual step-by-step delivery timeline** (Define > Design > Content >
  Build > UAT > Sign-off > Go-live) for the People page. There's no
  built-in web part for this; a text note points at PAGE-001's Delivery
  Status in the Page Backlog list instead.
- **Quick Chart web parts** (e.g. completion by department, on the
  Migration page) are left as a text placeholder rather than scripted -
  the Quick Chart web part's property schema isn't reliably scriptable
  without testing against a live tenant, but adding one by hand via the
  page editor is a two-minute job once the page and list exist.
- **List web part rendering in general.** Its JSON property schema is
  internal to SharePoint and has changed between releases; `Common.ps1`
  uses the commonly-seen/community-verified property set, but if a web
  part comes up blank after running `03-Provision-Pages.ps1`, delete it on
  the page and re-add "List" from the picker - the section layout and
  which list/view belongs where is unaffected.

## Not in this folder

Per the Implementation Specification, still out of scope here: Power
Automate flows (§5 - overdue-action escalation, RAID alerts, weekly
snapshot writes), migrating the real workbook data into these lists (§6-7),
and the Copilot agent from the Agent Instructions document. Ask if you want
any of those built out next.
