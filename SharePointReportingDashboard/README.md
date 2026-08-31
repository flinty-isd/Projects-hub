# HPUK SharePoint Project Control Centre (interim ASPX reporting view)

An ASP.NET Web Forms (`.aspx`) app that mirrors the SharePoint-based
Project Management Information System described in the Hutchison Ports UK
"SharePoint Project Control Centre" Implementation Specification: site
migration status, the People page and other out-of-scope page deliverables,
and governance (RAID, actions, decisions, weekly snapshots).

**This is an interim reporting view, not the target architecture.** The
Implementation Specification's target model is native SharePoint Lists
consumed by modern SharePoint pages, with Power Automate for notifications
and Power BI for richer visualisation. This app exists to make that data
shape browsable outside SharePoint (e.g. during design/build) using the
same field names, so a real SharePoint-backed implementation is a drop-in
swap behind `IProjectControlDataService` (see Architecture below).

**All data in this app is synthetic.** The only figure carried over from
the real programme is `SitesComplete = 209`, the validated baseline stated
in the specification. Every site name, owner, date, RAID item, action and
decision is invented for illustration - none of it is the real HPUK
migration workbook data.

## Pages

Matches the four "Presentation" pages in Implementation Specification §3:

| Page              | Spec section | What it shows |
|-------------------|--------------|----------------|
| `Default.aspx`    | 3.1 Programme Control Centre | Executive KPIs (209 sites complete, remaining, overall RAG, pages outstanding, overdue actions), Programme Health, migration progress by department, Attention Required, Next Migrations, Page Delivery summary |
| `Migration.aspx`  | 3.3 Migration Page | Residual migration only: completion by department, Next 30 Days, Blocked/Amber Sites, Remaining Sites, Completed Sites. LMS is explicitly **not** shown as a blocker |
| `Pages.aspx`      | 3.2 People & Page Delivery Page | Headline cards, the People (PAGE-001) delivery timeline, priority queue, ownership gaps, page backlog (Out of Scope / Scope Change), related RAID & actions |
| `Governance.aspx` | 3.4 Governance / Control Board Page | Red/Amber RAID, overdue actions, pending decisions, scope changes, latest + historical Project Update snapshots |

## Non-negotiables carried from the spec

These are asserted directly in the UI, per the Copilot Agent Instructions
and Implementation Specification:

- The validated baseline is **209 completed sites** until superseded by a
  validated SharePoint record.
- **LMS is complete and is not displayed as a current programme blocker.**
- The **People page** is tracked as Page Delivery Register item **PAGE-001**
  with its own lifecycle (Define → Design → Content → Build → UAT →
  Sign-off → Go-live) - never as an LMS blocker.
- Site migration and page delivery are kept as separate views, never
  merged into one undifferentiated status.

## Running it

Classic ASP.NET Web Forms, .NET Framework 4.8 Web Application Project -
needs Windows + IIS or IIS Express (via Visual Studio); it does not run on
.NET Core/5+ or Linux, since `System.Web` is Windows-only.

1. Open `SharePointReportingDashboard.sln` in Visual Studio 2019+.
2. Press F5 (IIS Express). It opens to `Default.aspx`.

No NuGet restore or SharePoint credentials are needed for the mock mode.

## Architecture

All pages read through `Services.IProjectControlDataService`, one method
per authoritative SharePoint List:

```
Pages (Default/Migration/Pages/Governance .aspx)
        -> DataServiceFactory.GetService()
              -> IProjectControlDataService
                    -> MockProjectControlDataService   (today)
                    -> your CSOM/PnP implementation     (future)
```

| List (spec §2)         | Model                    | Service method            |
|-------------------------|--------------------------|----------------------------|
| Migration Register      | `Models.MigrationSite`   | `GetMigrationSites()`      |
| Page Delivery Register  | `Models.PageDeliveryItem`| `GetPageDeliveryItems()`   |
| Actions                 | `Models.ActionItem`      | `GetActions()`             |
| RAID                    | `Models.RaidItem`        | `GetRaidItems()`           |
| Decisions                | `Models.Decision`        | `GetDecisions()`            |
| Project Updates          | `Models.ProjectUpdateSnapshot` | `GetLatestSnapshot()` / `GetSnapshotHistory()` |

Field names on each model match the spec's list schema (§2.1-2.3) so that
swapping the mock service for a real SharePoint-backed one requires no
changes to models or pages - only a new `IProjectControlDataService`
implementation.

## Connecting the real SharePoint tenant

1. Add the SharePoint CSOM or `PnP.Framework` / `PnP.Core` NuGet package.
2. Implement `IProjectControlDataService` (see
   `Services/IProjectControlDataService.cs`) against the real Migration
   Register, Page Delivery Register, Actions, RAID, Decisions and Project
   Updates Lists - e.g. `CsomProjectControlDataService`.
3. Fill in the `SharePoint.*` keys in `Web.config` with an app-only
   registration that has read access to those Lists.
4. Set `UseMockData` to `false` in `Web.config`.
5. Return your new implementation from `DataServiceFactory.GetService()`
   when `UseMockData` is `false`.

## Not in scope here

Per the Implementation Specification, the following remain to be built
directly in the real Microsoft 365 tenant and are outside what a
git-committed ASPX app can do:

- Provisioning the six SharePoint Lists themselves (schemas in spec §2).
- The native modern SharePoint pages and web parts (spec §3).
- Power Automate flows for escalation, alerts and weekly snapshots (§5).
- Migrating/cleansing the real workbook data into the Lists (§6-7).
- Registering the Copilot agent described in the Agent Instructions
  document.
