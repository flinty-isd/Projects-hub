# Enterprise PMO flows: process diagrams

Rendered by GitHub. One diagram per flow, then how the lists connect.

## How the pieces fit

```mermaid
flowchart LR
  subgraph Lists["PMO site lists"]
    WS[("PMO Workstreams")]
    RAID[("Master RAID Log")]
    ACT[("Action and Decision Tracker")]
    LOG[("PMO Date Push Log")]
    SNAP[("PMO Trend Snapshots")]
    HIST[("PMO Digest History")]
  end
  RAID -- "item changed" --> F3a["03a RAID churn tracker"]
  ACT -- "item changed" --> F3b["03b Action churn tracker"]
  F3a -- "push row" --> LOG
  F3b -- "push row" --> LOG
  F3a -- "ClosedDate, baseline, push count" --> RAID
  F3b -- "CompletedDate, baseline, push count" --> ACT
  RAID --> F1["01 Daily digest<br/>weekdays 07:00"]
  ACT --> F1
  F1 -- "claim / Posted / Failed" --> HIST
  F1 -- "adaptive card" --> T1["Teams: Steering Committee"]
  WS --> F2["02 Early warning<br/>Mondays 06:00"]
  RAID --> F2
  ACT --> F2
  LOG --> F2
  F2 -- "weekly row" --> SNAP
  F2 -- "score >= threshold" --> T2["Teams: PMO Risk Advisory"]
  SNAP --> PBI["Power BI trend report"]
  CR[("Change Requests")] -- "new request" --> F4["04 Change request approval"]
  F4 -- "Decision Made" --> ACT
  RAID -- "escalation requested" --> F5["05 Escalation request"]
  F5 -- "flag escalated" --> RAID
  F5 -- "approved" --> T1
```

## 01 Daily executive overdue digest

```mermaid
flowchart TD
  A["Weekdays 07:00 UK"] --> B{"DigestEnabled?"}
  B -- No --> Z["End"]
  B -- Yes --> C["Cutoff = start of today (UK) in UTC"]
  C --> D1["RAID: escalated, not Closed,<br/>target date before cutoff"]
  C --> D2["Actions: Executive Board, not Completed,<br/>due before cutoff"]
  D1 --> E{"Anything overdue?"}
  D2 --> E
  E -- No --> Z
  E -- Yes --> F{"Today's digest row exists?"}
  F -- Yes --> Z
  F -- No --> G["Claim row: Posting"]
  G --> H["Build card: up to DigestMaxItems each,<br/>'...and N more'"]
  H --> I["Post card to Steering Committee channel"]
  I -- OK --> J["Row: Posted"]
  I -- Failed --> K["Row: Failed + email PMO mailbox"]
```

## 02 Predictive early warning

```mermaid
flowchart TD
  A["Mondays 06:00 UK"] --> B["Read active workstreams, open + recently closed<br/>risks/issues and actions, push log, this week's snapshots"]
  B --> C["For each workstream"]
  C --> D["Net risk velocity = new - closed (7d)"]
  C --> E["Burn-down = closed 7d / (opened 7d + due next 10d)"]
  C --> F["Churn = pushes where PushesInWindow >= ChurnThreshold"]
  D --> G["Score: RVEL-HIGH + ABD-SLO + CHURN-CRIT (0-3)<br/>and plain-English reason"]
  E --> G
  F --> G
  G --> H{"Snapshot this week already?"}
  H -- Yes --> C
  H -- No --> I["Write PMO Trend Snapshots row"]
  I --> J{"Score >= threshold<br/>and EarlyWarningEnabled?"}
  J -- No --> C
  J -- Yes --> K["Post advisory card,<br/>mark AdvisoryPosted"]
  K --> C
```

## 03a / 03b Date churn trackers

```mermaid
flowchart TD
  A["Item created or changed"] --> B{"Trigger condition:<br/>date differs from TrackedDueDate<br/>or Status differs from TrackedStatus?"}
  B -- No --> Z["No run<br/>(includes the flow's own update)"]
  B -- Yes --> C{"Date moved later than<br/>the tracked date?"}
  C -- Yes --> D["Count this item's pushes in window,<br/>add PMO Date Push Log row"]
  C -- No --> E
  D --> E["Update item: TrackedDueDate, TrackedStatus,<br/>original baseline (first time only),<br/>Closed/Completed date when Status just closed,<br/>push count and note"]
```

## 04 Change request approval

```mermaid
flowchart TD
  A["Change request created"] --> B{"CRApprovalsEnabled?"}
  B -- No --> Z["Stays Submitted"]
  B -- Yes --> C["CR-nnn, route: Steering Committee if scope change<br/>or budget/schedule over tolerance, else PMO"]
  C --> D["Under review - PMO"]
  D --> E{"PMO approval (14 days)"}
  E -- Reject --> R["Returned to requester"]
  E -- "Timed out" --> O["Decision overdue"]
  E -- "Approve, within tolerance" --> AP["Approved (PMO)"]
  E -- "Approve, over tolerance" --> S["Under review - Steering Committee"]
  S --> F{"Steering Committee approval (21 days)"}
  F -- Approve --> AS["Approved (Steering Committee)"]
  F -- Reject --> RJ["Rejected"]
  F -- "Timed out" --> O
  AP --> L["Re-read item (Withdrawn wins), record decision"]
  AS --> L
  RJ --> L
  R --> L
  O --> L
  L --> M{"Approved or Rejected?"}
  M -- Yes --> N["Log Decision Made in Action and Decision Tracker,<br/>email requester"]
  M -- No --> P["Email requester and PMO mailbox"]
```

## 05 Risk and issue escalation request

```mermaid
flowchart TD
  A["RAID item: Request Executive Board escalation ticked"] --> B{"Trigger condition: not escalated,<br/>status Not requested / Declined / Not decided"}
  B -- No --> Z["No run"]
  B -- Yes --> C["Re-read item"]
  C --> D{"Claim: status = Requested<br/>(If-Match ETag)"}
  D -- "412: claimed by another run" --> Z2["Stop quietly"]
  D -- OK --> E{"Head of PMO approval (3 days)"}
  E -- Approve --> F["Escalated to Executive Board = Yes,<br/>status Approved"]
  F --> G["Card to Steering Committee channel<br/>(if EscalationAlertsEnabled)"]
  E -- Reject --> H["Status Declined, tick cleared"]
  E -- "Timed out" --> I["Status Not decided, tick cleared"]
  G --> J["Email submitter and owner"]
  H --> J
  I --> J
```
