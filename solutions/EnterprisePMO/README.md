# Enterprise PMO Governance Hub

A Project Management Office (PMO) governance hub on SharePoint Online and Power
Automate. It is built from the *Enterprise PMO & Governance Blueprint:
SharePoint Online & Power Automate* and has three parts:

1. **Executive hub page**: `Portfolio-Governance-Hub.aspx`. It shows initiative
   health, overdue escalations, the decisions the Executive Board owes, the
   governance calendar and the key documents.
2. **List formatting**: RAG status pills, and overdue / due-soon badges on due
   dates.
3. **Six flows**: a daily digest to the Steering Committee, a weekly
   predictive early warning, a date-churn tracker on each of the two lists
   that hold due dates, change request approval, and risk and issue
   escalation requests.
4. **A Copilot prompt pack** ([`copilot/COPILOT-PROMPTS.md`](copilot/COPILOT-PROMPTS.md))
   for rebuilding all of it by hand with Copilot. It includes a Copilot
   Studio agent that lets people report a risk from Teams, and prompts for
   running the hub.

| # | Flow | Trigger | What it does |
|---|------|---------|--------------|
| 01 | [Daily executive overdue digest](powerautomate/flows/01-Daily-Executive-Digest.json) | Weekdays 07:00 UK | Posts one adaptive card to the Steering Committee channel. It lists overdue escalated RAID risks and issues, and overdue Executive Board actions and decisions. Nothing is posted when nothing is overdue. It posts at most once a day (PMO Digest History). Off until `DigestEnabled` = Yes |
| 02 | [Predictive early warning](powerautomate/flows/02-Predictive-Early-Warning.json) | Mondays 06:00 UK | For each active workstream it scores three indicators: net risk velocity (RVEL-HIGH), action burn-down (ABD-SLO) and date churn (CHURN-CRIT). It writes a weekly PMO Trend Snapshots row with a plain-English reason. When the score reaches the threshold it posts an advisory card. Cards are off until `EarlyWarningEnabled` = Yes; the snapshots are written either way |
| 03a | [RAID date churn tracker](powerautomate/flows/03a-RAID-Date-Churn.json) | Master RAID Log item created or changed | When a target date moves later, it logs the push and counts it. It keeps the original baseline date and stamps *Closed on* |
| 03b | [Action date churn tracker](powerautomate/flows/03b-Action-Date-Churn.json) | Action and Decision Tracker item created or changed | The same for due dates. It stamps *Completed on* |
| 04 | [Change request approval](powerautomate/flows/04-Change-Request-Approval.json) | New Change Requests item | Allocates CR-nnn. The PMO reviews it (14 days). Within tolerance, that review is the decision; scope changes and anything over the budget or schedule tolerance go to the Steering Committee (21 days). It records the outcome, logs the decision in the Action and Decision Tracker and emails the requester. Off until `CRApprovalsEnabled` = Yes |
| 05 | [Risk and issue escalation request](powerautomate/flows/05-Risk-Escalation-Request.json) | *Request Executive Board escalation* ticked on a RAID item | The Head of PMO approves within 3 days. If approved, the item is flagged *Escalated to Executive Board* and posted to the Steering Committee channel straight away (the post is off until `EscalationAlertsEnabled` = Yes). If declined or not decided, the request is cleared so it can be asked again |

Process diagrams are in [`diagrams/pmo-flows.md`](diagrams/pmo-flows.md).

## Layout

```
EnterprisePMO/
├── powerautomate/flows/   flow definitions (Workflow Definition Language JSON)
├── sharepoint/            list-schema.json (10 lists and libraries), dashboard.json (page and views),
│                          rag-format.json, due-date-format.json, status-format.json (column formatting)
├── provisioning/          Provision-PMOHub.ps1: lists, columns, formatting, views and the hub page
├── diagrams/              Mermaid process diagrams
├── copilot/               COPILOT-PROMPTS.md: build-it-with-Copilot prompts, risk agent, running prompts
├── tools/                 build_copilot_prompts.py: regenerates the prompt pack from the schema
├── DEPLOY-AND-TEST.md     step-by-step deployment and test script
└── solution-config.json   solution name, version, publisher, environment variables
```

The validation and packaging tools are shared with the other solutions and
live in `../SharePointGovernance/tools/`. Run them with
`--root solutions/EnterprisePMO`.

## Lists

All the lists are on the one PMO site. `provisioning/Provision-PMOHub.ps1`
creates them from `sharepoint/list-schema.json`.

| List | Purpose | Written by |
|------|---------|------------|
| PMO Workstreams | One row per workstream: code, sponsor, lead, Active, Overall/Schedule/Budget/Scope RAG | PMO |
| Master RAID Log | Risks, assumptions, issues and dependencies. *Escalated to Executive Board* puts an item on the hub and, once overdue, in the digest. Anyone can tick *Request Executive Board escalation*; flow 05 gets it decided | Everyone; flows 03a and 05 write the tracking and escalation columns |
| Action and Decision Tracker | Actions and decisions. *Decision forum* says who owns each one | Everyone; flow 03b writes the tracking columns |
| Change Requests | Baseline change control (CR-nnn), with budget and schedule impact. Target of the *Submit Change Request* quick link | Everyone; flow 04 writes the reference, status and decision |
| PMO Governance Calendar | Steering Committee gates, PMO working groups, Scope Control Board, with submission deadlines (Events template) | PMO |
| Portfolio Document Repository | PIDs, baseline charters, stage-gate submissions, closure reports | PMO and workstreams |
| Governance Framework and SOPs | Frameworks, stage-gate guidance, templates, SOPs | PMO |
| PMO Trend Snapshots | Weekly metrics for each workstream. The Power BI trend report reads it | Flow 02 only |
| PMO Date Push Log | One row each time a date moves later: the audit trail | Flows 03a/03b only |
| PMO Digest History | One row per daily digest | Flow 01 only |

## Hub page

| Section | Layout | Content |
|---|---|---|
| 1. Header | One column | Welcome text and the Quick Links web part (five links, with audience targeting) |
| 2. Portfolio health | 2/3 + 1/3 | Power BI report (RAG scorecard, slippage trend, early-warning heatmap); PMO executive commentary |
| 3. Escalations | 1/2 + 1/2 | Master RAID Log: *Executive escalations*; Action and Decision Tracker: *Pending board decisions* |
| 4. Cadence and artefacts | 1/3 × 3 | Calendar: *Next 30 days*; documents: *PIDs and charters*; People: PMO leadership contacts |
| 5. Requests in flight | 1/2 + 1/2 | Change Requests: *Open change requests*; Master RAID Log: *Escalation requests* |

The script builds the page and its views. A few things can only be set by
hand in the page editor, and the script prints the list at the end:

- the Quick Links entries and their audiences
- the Power BI report
- the commentary text
- the People descriptions

`tools/validate_dashboard.py --root solutions/EnterprisePMO` checks every view
against the list schema. It also checks that every view showing a formatted
due date includes Status: the badge reads Status, and SharePoint ignores
`[$Status]` when the column isn't in the view.

## Changes from the blueprint

The blueprint is followed throughout, except where its specification would
not have worked or conflicts with how this repository runs flows. The table
lists each change.

| Blueprint | Built | Why |
|---|---|---|
| Flow 3 trigger condition `@equals(DueDate, DueDate)` | Compares the date and Status with `TrackedDueDate` / `TrackedStatus`, which the flow writes on every run | The blueprint condition is always true, so it prevents nothing: every edit, including the flow's own update, starts a run. With the tracked copy, the flow's own update matches and doesn't re-trigger |
| Flow 3 reads the previous version through `_api/.../versions` | Reads the previous date from the tracked copy | It needs no REST call or version-index handling, and it still works after versions are trimmed. Versioning is still turned on for audit |
| Churn as "≥ 2 pushes within 14 days on a single item", but stored as one cumulative `DatePushCount` | PMO Date Push Log: one row per push, with that item's pushes in the window (`PushesInWindow`) | A cumulative count can't answer "within 14 days". Flow 02 reads the log |
| "Closed risks" = Status Closed and Modified in last 7 days | *Closed on* / *Completed on* dates stamped by flows 03a/03b | Any later edit to a closed item changes Modified, so the blueprint would count it as closed again |
| `EarlyWarningScore` never defined | One point per indicator over its threshold (0–3). Advisory at ≥ `EarlyWarningThreshold` (2) | The blueprint uses `>= 2` but never says how the score is made up |
| `item()?['Workstream']`, `item()?['RAGRating']` in Select | `?['Value']` | Choice and lookup columns come back as objects, so the card would have shown JSON |
| Card JSON with sample rows | Facts built from the query results, capped at `DigestMaxItems`, with a "...and N more" line | The sample rows were fixed text. The cap keeps the card under the Teams size limit |
| Overdue = due before `utcNow()` midnight UTC | Before the start of today, UK time | Date-only columns are stored as local midnight, so in summer time an item due today would show as overdue |
| Theme tokens `var(--sp-color-status-*)` in formatting | Fixed colours, matching the governance badges, and words always shown | Column formatting doesn't reliably resolve those tokens. A pill that loses its colour silently is worse than fixed colours |
| *Submit Risk / Issue Escalation* "with auto-flagging enabled" | People request an escalation on the RAID form; the Head of PMO approves it (flow 05), and approval sets the flag and alerts the Steering Committee | A new-form link can't set a field. A self-service flag would let anyone put any item in front of the Board. The approval keeps the Board's list for items the PMO stands behind, and still takes 3 days or less |
| Run under `svc-pmo-automation@` | Named flow owner | Policy D-03 allows no service or shared accounts (see the [deployment plan](../POWER-PLATFORM-DEPLOYMENT.md#identities)). Failure alerts go to a shared mailbox instead |
| Digest daily, 07:00 UTC | Weekdays, 07:00 UK time | Nobody acts on a weekend digest, and 07:00 UTC is 08:00 in summer |
| Board decisions view `DecisionOwner eq [Current User / Executive Board]` | *Decision forum* = Executive Board | A view can't filter on "current user or the Board". The forum makes ownership explicit. The view shows Board actions as well as decisions, which matches the digest |
| Snapshot `Workstream` as text or choice | Lookup to *PMO Workstreams* | Flow 02 needs a list of workstreams to loop over, and the lookup keeps the names consistent across lists |

Not built (needs a decision or a licence):

- **Highlighted Content and Events web parts.** Sections 4.1 and 4.2 use List
  web parts on filtered views, which are scriptable and validated in CI. The
  Events web part can point at *PMO Governance Calendar* instead, by hand.
- **Power BI report.** The web part is placed, but the report itself isn't in
  this repo. It should read PMO Workstreams, PMO Trend Snapshots and Master
  RAID Log. Viewers need Power BI Pro/PPU, or the workspace on Premium/Fabric
  capacity.

## Environment variables

| Variable | Used by | Default |
|---|---|---|
| `PMOSiteUrl` | all | set after import |
| `PMOOwnerEmail` | all: failure alerts, digest-not-posted | set after import (shared mailbox) |
| `SupportMailboxEmail` | all: optional copy of failure emails | empty |
| `SteerCoTeamId`, `SteerCoChannelId` | 01, 05 | set after import |
| `DigestEnabled` | 01 | No |
| `DigestMaxItems` | 01 | 20 |
| `RiskAdvisoryTeamId`, `RiskAdvisoryChannelId` | 02 | set after import |
| `EarlyWarningEnabled` | 02 (cards only) | No |
| `EarlyWarningThreshold` | 02 | 2 |
| `RiskVelocityThreshold` | 02 | 2 |
| `BurnDownThresholdPercent`, `BurnDownMinActionsDue` | 02 | 75, 3 |
| `ChurnThreshold`, `ChurnWindowDays` | 02, 03a, 03b | 2, 14 |
| `CRApprovalsEnabled` | 04 | No |
| `CRPMOApproverEmails`, `CRSteerCoApproverEmails` | 04 | set after import |
| `CRBudgetTolerance`, `CRScheduleToleranceDays` | 04 | 25000 (GBP), 10 days: set to the programme's agreed tolerances |
| `EscalationApproverEmails` | 05 | set after import (Head of PMO and a deputy) |
| `EscalationAlertsEnabled` | 05 (Teams post only) | No |

## Building and validating

```
python solutions/SharePointGovernance/tools/validate_flows.py --root solutions/EnterprisePMO
python solutions/SharePointGovernance/tools/validate_dashboard.py --root solutions/EnterprisePMO
python solutions/EnterprisePMO/tools/build_copilot_prompts.py --check
python solutions/SharePointGovernance/tools/build_kit.py --root solutions/EnterprisePMO --out dist
```

CI (`.github/workflows/pmo-flows.yml`) runs all four on every change under
this folder or the shared tools. After changing the list schema or the
thresholds, run `build_copilot_prompts.py` without `--check` to regenerate
the prompt pack. It uploads the unmanaged solution
`EnterprisePMO_<version>.zip` and the deployment kit.

The connectors are SharePoint, Microsoft Teams, Office 365 Outlook and
Approvals, all standard. List reads page up to 100,000 rows, which needs the flow owner's
Power Automate Premium licence. Without it, Power Automate stops at 5,000.

**Not yet tried against a real tenant.** Neither the flows nor the
provisioning script have run anywhere. The repo's static checks pass, but
PowerShell wasn't available to parse-check the script. Deploy to a test site
and a dev environment first ([DEPLOY-AND-TEST.md](DEPLOY-AND-TEST.md)).
