# SharePoint modern pages & JSON formatting

Renders both dashboards **natively inside SharePoint** — no external app to host.
The lists themselves become the dashboard: JSON formatting supplies the visual
encoding, and modern pages group the lists together.

Use this if you'd rather not deploy the `/aspx` or Streamlit apps. It gives up
the custom charts and the Gantt timeline, but it needs no hosting, no Azure AD
app registration, and it honours SharePoint permissions automatically.

| File | Purpose |
| --- | --- |
| `formatting/*.json` | Column and view formatting — the visual layer |
| `Apply-Formatting.ps1` | Applies that formatting; also adds the `RiskScore` calculated column |
| `Provision-ModernPages.ps1` | Builds two modern pages out of List web parts |

> **Not run against a live tenant.** Written without access to SharePoint or a
> PowerShell runtime, so the scripts are unexecuted. The JSON *has* been
> validated: every file parses, every `[$Field]` reference matches a column the
> provisioning script creates, and each file carries the right schema URL for
> its kind. Use `-WhatIf` on the scripts first.

## Order of operations

Lists must already exist (`../provisioning/Provision-SharePointLists.ps1`).

```powershell
# 1. Formatting — this is the part that does the visual work
.\Apply-Formatting.ps1 -SiteUrl $url -ClientId $id -WhatIf
.\Apply-Formatting.ps1 -SiteUrl $url -ClientId $id

# 2. Pages that gather the lists together
.\Provision-ModernPages.ps1 -SiteUrl $url -ClientId $id -Publish
```

Both take `-Include Pm|Governance|All`. If the two dashboards live on separate
sites, run each with the matching `-Include`.

Applying formatting by hand instead: open the list → column dropdown → **Column
settings → Format this column** → *Advanced mode* → paste the matching JSON. For
view formatting it's **All Items → Format current view → Advanced mode**.

## What the formatting does

**Tasks** — status and priority pills; a progress bar for `% Complete`; due dates
turn red once past unless the task is Done; overdue rows tinted.

**Risks** — severity and status pills.

**Policies** — status pills; `Next Review` turns red once past and shows *"No
review date"* in amber when blank (blank counts as *not current*, matching how
the dashboards compute the currency rate); rows needing review tinted amber.

**Controls** — compliance pills (`Compliant` green → `Non-Compliant` red, `Not
Assessed` grey); framework shown as a neutral outlined tag.

**Audit findings** — severity pills with `Critical` as solid red; due dates red
once past unless Closed; overdue rows tinted red, open Critical rows tinted.

**Risk register** — `Risk Score` heat badge (15+ extreme, 10–14 high, 5–9
moderate, below 5 low), treatment and status pills, high-scoring open rows
tinted.

**Policy exceptions** — status pills; expiry amber inside 90 days and red once
lapsed while still marked Active; rows tinted to match.

The thresholds mirror the KPI logic in the other implementations, so the numbers
agree whichever front end you use.

## The one schema change

`Apply-Formatting.ps1` adds a calculated column to **RiskRegister**:

```
Risk Score  (internal name: RiskScore)  =  [Likelihood] * [Impact]
```

The heat badge formats that column. Everything else only sets formatting and
changes no data. The column is created only if missing, so re-running is safe.

## Charts

JSON formatting can't draw a chart. Options, roughly in order of effort:

1. **Quick chart web part** — edit a page, add *Quick chart*, point it at a list
   column. Fine for a single count-by-category bar. Add it by hand; its property
   shape is not stable enough to script reliably.
2. **Group a list view by Status / Severity / Framework** — gives counts per
   group with the pills intact. No extra parts needed, and it's what most people
   actually use.
3. **Power BI web part** — the real answer if you need the Gantt timeline or
   combined cross-list charts. Out of scope here.

The `/aspx` and Streamlit implementations remain the option if you specifically
want the Gantt timeline and the 5×5 heat-map grid rendered as a grid.

## Known rough edges

- **List web part properties** are the least stable thing in these scripts and
  have changed between SharePoint and PnP versions. If a web part lands
  unconfigured, add one by hand and inspect what your tenant expects:
  `(Get-PnPPage IT-Governance).Controls | Select-Object -ExpandProperty PropertiesJson`,
  then adjust `Get-ListWebPartProperties`.
- **Row formatting applies per view.** The scripts target `All Items` by default;
  pass `-ViewName` for another, and re-run for each view you care about.
- **Renaming a choice value breaks its colour** — the formatters match on the
  literal text (`'Non-Compliant'`, `'In Remediation'`, …). Change a choice in the
  list and update the matching JSON.
- **`sp-field-severity--*` row classes** are SharePoint's own; they follow the
  current theme, which is why rows are tinted with them rather than hard-coded
  backgrounds.
