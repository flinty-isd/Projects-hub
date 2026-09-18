# Deploying to a Microsoft 365 tenant

How to get the two dashboards onto a real SharePoint Online site, and how
Fabric and Copilot agents fit on top of them.

> **None of this has been run against a tenant.** There was no SharePoint
> environment, no PowerShell runtime and no Fabric capacity available when it
> was written. Treat it as a reviewed plan, not a tested procedure — do a
> dry run in a dev site collection first, and use `-WhatIf` throughout.

## Layers

| Layer | What it gives you | Needs |
| --- | --- | --- |
| Lists + JSON formatting | The dashboards themselves, rendered natively | SharePoint Online only |
| Fabric / Power BI | The charts native mode gives up — Gantt, cross-list rollups, trend over time | Fabric capacity or Power BI Pro |
| Copilot agent | Ask-a-question layer over the same lists | M365 Copilot licence |

Each layer is optional and sits on the one above it. Deploy layer 1, confirm it,
then decide whether you need 2 and 3.

---

# 1. SharePoint Online

## Prerequisites

- **Role:** Site Collection Administrator on the target site. Creating the site
  from scratch also needs SharePoint Administrator.
- **Module:** `Install-Module PnP.PowerShell -Scope CurrentUser` (2.x or later).
- **An Entra ID app registration** for PnP itself. Since PnP.PowerShell 2.x the
  old multi-tenant PnP Management Shell app is gone, so `-ClientId` is required
  on every connect:

  ```powershell
  Register-PnPEntraIDApp -ApplicationName "PnP Provisioning" `
      -Tenant contoso.onmicrosoft.com -Interactive
  ```

  This is separate from the app-only registration the hosted dashboards use at
  runtime. That one needs `Sites.Read.All`; this one needs delegated SharePoint
  permissions and acts as you.

## Sites

One site holding all seven lists, or two sites split by audience. The scripts
support both via `-Include`:

```powershell
# Single site
New-PnPSite -Type CommunicationSite -Title "Delivery Dashboards" `
    -Url https://contoso.sharepoint.com/sites/Dashboards

# Or split
New-PnPSite -Type CommunicationSite -Title "PM Dashboard" -Url .../sites/PMDashboard
New-PnPSite -Type CommunicationSite -Title "IT Governance" -Url .../sites/ITGovernance
```

Split is usually right for governance: the audit findings and risk register
want tighter membership than a project task list, and SharePoint permissions
are per-site. That decision also carries into the agent layer, which inherits
site permissions.

## Deploy

Dry run first — every script supports `-WhatIf`:

```powershell
$url = "https://contoso.sharepoint.com/sites/Dashboards"
$id  = "00000000-0000-0000-0000-000000000000"

.\provisioning\Provision-SharePointLists.ps1  -SiteUrl $url -ClientId $id -WhatIf
```

Then for real, in this order:

```powershell
.\provisioning\Provision-SharePointLists.ps1  -SiteUrl $url -ClientId $id
.\sharepoint-modern\Apply-Formatting.ps1      -SiteUrl $url -ClientId $id
.\sharepoint-modern\Provision-ModernPages.ps1 -SiteUrl $url -ClientId $id -Publish
```

Order matters: formatting needs the columns, pages need the lists. All three are
idempotent — lists, fields and the `RiskScore` calculated column are only created
if missing, and formatting is overwritten each run.

If you split across two sites, run each with the matching `-Include`:

```powershell
.\provisioning\Provision-SharePointLists.ps1 -SiteUrl $pmUrl  -ClientId $id -Include Pm
.\provisioning\Provision-SharePointLists.ps1 -SiteUrl $govUrl -ClientId $id -Include Governance
```

Optionally seed demo rows to prove the connection end to end. Dates are relative
to today, so overdue rows stay overdue:

```powershell
.\provisioning\Add-SampleData.ps1 -SiteUrl $url -ClientId $id `
    -People "ana@contoso.com","raj@contoso.com"
```

It adds without clearing, so run it once.

## Verify

1. Each list opens and the columns carry their **display** names ("Assigned To")
   while the URL/column settings show the **internal** names (`AssignedTo`). If
   you see `Assigned_x0020_To`, a column was created by hand — recreate it.
2. Formatting renders: status pills coloured, `% Complete` as a bar, past-due
   dates red, high-scoring risks with a heat badge.
3. `PM-Dashboard.aspx` and `IT-Governance.aspx` exist and are published.
4. Set the dashboard as the landing page: `Set-PnPHomePage -RootFolderRelativeUrl
   SitePages/IT-Governance.aspx`.

The most likely thing to need hand-finishing is the List web parts on the pages
— their property names have shifted between SharePoint and PnP versions. If one
lands unconfigured, see the "Known rough edges" note in
`sharepoint-modern/README.md` for how to inspect what your tenant expects.

## Promoting dev → test → prod

Rather than re-running scripts per environment, capture the finished dev site
and replay it:

```powershell
Connect-PnPOnline -Url $devUrl -Interactive -ClientId $id
Get-PnPSiteTemplate -Out dashboards.pnp -Handlers Lists,PageContents,Fields

Connect-PnPOnline -Url $prodUrl -Interactive -ClientId $id
Invoke-PnPSiteTemplate -Path dashboards.pnp
```

The template is XML, so it belongs in version control next to the scripts and
gives you a reviewable diff when the schema changes. The scripts remain the way
you build the *first* site; the template is how you copy it.

## Unattended / pipeline runs

Interactive sign-in doesn't work in a build agent. Use app-only with a
certificate:

```powershell
Connect-PnPOnline -Url $url -ClientId $id -Tenant contoso.onmicrosoft.com `
    -CertificatePath .\pnp.pfx -CertificatePassword (Read-Host -AsSecureString)
```

Prefer **`Sites.Selected`** over `Sites.FullControl.All` — it grants the app
write access to named sites only, rather than every site in the tenant. Grant it
per-site through Graph after consenting the app permission. Store the
certificate in Key Vault, not in the repo.

Note the scripts currently hardcode `-Interactive` in their `Connect-PnPOnline`
calls, so running them unattended means parameterising that connect line first.

---

# 2. Fabric and Power BI

Native mode deliberately gives up the Gantt timeline, the 5×5 heat-map grid, and
any chart that spans two lists — JSON formatting can't draw those. That is
exactly the gap Fabric fills, and the result embeds back into the same
SharePoint page, so users never leave the site.

## Which path

**Power BI only** — Power BI Desktop → *SharePoint Online List* connector (pick
the 2.0 implementation) → build the report → publish to a workspace → add the
**Power BI report** web part to `PM-Dashboard.aspx`. Enough for a Gantt and a
proper heat map. Viewers need Pro unless the workspace sits on F64+/P capacity.

**Fabric** — worth it when you want any of: history (lists overwrite, so
"open findings over time" doesn't exist unless you snapshot it), consolidation
across several sites, or downstream reuse. Dataflow Gen2 with a SharePoint
Online list source, destination a Lakehouse table, then a Direct Lake semantic
model over it.

Start with the first. Move to the second when someone asks a question the
current lists can't answer because yesterday's values are gone.

## Gotchas specific to these lists

- **Person columns** (`AssignedTo`, `Owner`, `RequestedBy`, `Approver`) arrive as
  records, not strings. Expand to `.Title` or `.EMail` in Power Query. The
  Python and C# clients already do the equivalent — see `_extract_person` in
  `data_transform.py` for the shapes to expect.
- **Choice columns** can arrive as lists. Expand before filtering on them.
- **`PercentComplete`** is stored 0–1, not 0–100. Format as a percentage rather
  than multiplying, or your bars disagree with the SharePoint view.
- **`RiskScore`** is a calculated column. Recompute `Likelihood * Impact` in
  Power Query instead of depending on it — calculated columns surface
  inconsistently across connector versions, and the arithmetic is trivial.
- **Throttling.** SharePoint lists are not a warehouse. Keep scheduled refresh
  modest and filter incrementally on `Modified` rather than pulling every row
  every time.

## Keep the numbers agreeing

The KPI thresholds are currently pinned in three places — `kpis.py`,
`GovernanceKpis.cs`, and the JSON formatters — and they match. A Fabric semantic
model makes a fourth. The ones that matter:

| Rule | Definition |
| --- | --- |
| Task/finding closed | `Done`, `Completed`, `Closed`, and for findings `Resolved`, case-insensitive |
| Compliance rate | `Compliant` ÷ (all controls except `Not Assessed`) |
| High risk | `Likelihood × Impact` ≥ 15, excluding `Closed` |
| Policy current | `NextReview` in the future; blank counts as *not* current |
| Exception warning | `Active` only, 90-day window |

Put these in DAX measures once, in the shared semantic model, and point every
report at it. A report that redefines "overdue" inline is how two dashboards
start disagreeing in a steering meeting.

---

# 3. Copilot agents

Both dashboards are question-shaped — "which policies are overdue?", "what's
open and critical for Raj?", "which waivers lapse this quarter?" — so an agent
over the same site is a natural third layer.

## Two options, and the honest difference

**SharePoint agent** — created from the site itself, grounded on that site's
content, stored as a `.agent` file in the site and shared like any file. Fast to
stand up, no development. It inherits site permissions, which is the property
that makes it safe to hand out: a user who can't see the findings list can't get
answers from it either.

The caveat: grounding is strongest over **documents and pages**, and weaker over
**list items**. For the Policies library, where the policy documents live, that's
fine. For the numeric governance lists — findings, risk register, exceptions —
don't assume it can reliably count or aggregate rows. Test that specifically in
your tenant before promising it to anyone, because it's the part most likely to
disappoint.

**Copilot Studio agent with an action** — give the agent an explicit tool that
queries the lists (Power Automate flow or a Graph call) and returns structured
rows. More work, but the counts are deterministic rather than inferred, which
for a compliance number is the difference between useful and dangerous.

For this project: SharePoint agent for the policy content, Copilot Studio with
actions for anything that produces a number someone might report upward.

## If you build the Copilot Studio one

The KPI rules in the table above *are* the agent's logic. Implement them in the
action, not in the prompt — an agent asked to work out "overdue" from raw dates
will get it right most of the time, which is the worst failure mode for
governance reporting. Return the filtered rows and let the agent phrase them.

A "Not Assessed" control is not a compliant one and not a failing one; make sure
the action's response distinguishes the three, or the agent will round the
compliance rate in whichever direction the question implies.

## Licensing and rollout

Agents need M365 Copilot licensing (SharePoint agents have also been available
via pay-as-you-go metering — check what your tenant is actually on before
assuming per-user). Roll out to the governance team first: they'll recognise a
wrong number, which general users won't.

---

# What isn't verified

- No script here has been executed. No tenant, no PowerShell runtime.
- The List web part properties in `Provision-ModernPages.ps1` are the least
  stable part and may need hand-correction on first run.
- Fabric and agent capabilities move quickly. The shapes above were accurate as
  written, but confirm connector behaviour and agent grounding against current
  docs and your own tenant rather than against this file.
- The hosted apps in `/`, `/aspx` and `/governance-aspx` remain for testing and
  for the charts; only the Python side is covered by CI.
