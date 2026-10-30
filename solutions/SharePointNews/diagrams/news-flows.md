# SharePoint News flows — process diagrams

One diagram per flow in `../powerautomate/flows/`; C3a (HPUK News) and C3b
(Other News) are the same flow on different sites. Green ends are
successful outcomes, red ends need someone to act, blue ends are deliberate
stops or follow-ups. The shapes and colours follow the governance diagrams
([`../../SharePointGovernance/diagrams/governance-flows.md`](../../SharePointGovernance/diagrams/governance-flows.md)).
Delivery statuses are the *DeliveryStatus* choices of the Delivery Log in
[`../sharepoint/list-schema.json`](../sharepoint/list-schema.json).

## End to end

Who does what, from request to review. Regenerate with `python solutions/SharePointGovernance/tools/draw_workflows.py`.

![SharePoint News: publish to inbox](news-workflow.svg)

## Overview

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'fontFamily': 'Source Sans 3, Source Sans Pro, Segoe UI, sans-serif', 'fontSize': '15px', 'primaryColor': '#f0f2f6', 'primaryBorderColor': '#5e616d', 'primaryTextColor': '#31333f', 'lineColor': '#5e616d', 'clusterBkg': '#f8f9fb', 'clusterBorder': '#cdd0d8', 'edgeLabelBackground': '#ffffff', 'tertiaryColor': '#ffffff'}}}%%
flowchart TD
  P([Publisher publishes a post]) --> SP[("Site Pages<br/>HPUK News + Other News")]
  SP -- "daily 06:00: ExpiryDate passed" --> C1["C1 Expiry"] -- "Status = Expired" --> SP
  SP -- "Mondays 07:00: Live, InRoundup, last week" --> C2["C2 Port roundup"]
  SP -- "published major version, Urgent,<br/>not yet sent" --> C3["C3a / C3b Urgent notice"]
  CD[("Comms Distribution<br/>port → email group, Teams channel")] --> C2 & C3
  C2 & C3 -- "reserve key, then send" --> OUT[/"Email from Comms mailbox<br/>Teams channel post"/]
  C2 & C3 -- "Reserved → Sent / Failed / Reconcile" --> DL[("Delivery Log")]
  C3 -- "all sent: UrgentSent = Yes" --> SP
```

## C1 — News expiry (daily 06:00 UK)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'fontFamily': 'Source Sans 3, Source Sans Pro, Segoe UI, sans-serif', 'fontSize': '15px', 'primaryColor': '#f0f2f6', 'primaryBorderColor': '#5e616d', 'primaryTextColor': '#31333f', 'lineColor': '#5e616d', 'clusterBkg': '#f8f9fb', 'clusterBorder': '#cdd0d8', 'edgeLabelBackground': '#ffffff', 'tertiaryColor': '#ffffff'}}}%%
flowchart TD
  A([Daily 06:00 UK time]) --> Q["Both sites: published Live pages<br/>with ExpiryDate before today (UK date)"]
  Q --> W{"ExpiryWritesEnabled = Yes?"}
  W -->|No| DRY[/"Dry run: email support owner<br/>the pages that would expire"/]:::info
  W -->|Yes| U["Status = Expired via ValidateUpdateListItem<br/>(no new version, no draft)"]
  U --> OK{"Update succeeded?"}
  OK -->|Yes| EX[/"Expired - drops off News web parts"/]:::good
  OK -->|No| F[/"Failure listed -> support owner alerted"/]:::bad
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

## C2 — Weekly port roundup (Mondays 07:00 UK)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'fontFamily': 'Source Sans 3, Source Sans Pro, Segoe UI, sans-serif', 'fontSize': '15px', 'primaryColor': '#f0f2f6', 'primaryBorderColor': '#5e616d', 'primaryTextColor': '#31333f', 'lineColor': '#5e616d', 'clusterBkg': '#f8f9fb', 'clusterBorder': '#cdd0d8', 'edgeLabelBackground': '#ffffff', 'tertiaryColor': '#ffffff'}}}%%
flowchart TD
  A([Mondays 07:00 UK time]) --> DE{"DispatchEnabled = Yes?"}
  DE -->|No| CX[/"Cancelled - nothing sent"/]:::info
  DE -->|Yes| P["Posts from both sites: Live, InRoundup,<br/>first published last Monday 00:00 to this Monday 00:00 UK,<br/>not audience targeted"]
  P --> D["Each enabled Comms Distribution row"]
  D --> HP{"Any posts for this row?<br/>(its port, or All ports posts;<br/>an All ports row gets every post)"}
  HP -->|No| NONE([Nothing sent to this row])
  HP -->|Yes| G["Build digest: title, summary, link<br/>(by Strategy theme if RoundupGroupByTheme = Yes)"]
  G --> RS[["Reserve, then send: email group and Teams channel<br/>(see Reserve then send)"]]
  RS --> FL{"Any failures?"}
  FL -->|No| DONE[/"Roundup sent; Delivery Log rows Sent"/]:::good
  FL -->|Yes| AL[/"Support owner alerted"/]:::bad
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

## C3a / C3b — Urgent notice (on publish)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'fontFamily': 'Source Sans 3, Source Sans Pro, Segoe UI, sans-serif', 'fontSize': '15px', 'primaryColor': '#f0f2f6', 'primaryBorderColor': '#5e616d', 'primaryTextColor': '#31333f', 'lineColor': '#5e616d', 'clusterBkg': '#f8f9fb', 'clusterBorder': '#cdd0d8', 'edgeLabelBackground': '#ffffff', 'tertiaryColor': '#ffffff'}}}%%
flowchart TD
  A([Site Pages item changed:<br/>HPUK News - C3a, Other News - C3b]) --> TC{"Published major version (x.0), Live,<br/>Urgent = Yes, UrgentSent = No?"}
  TC -->|No| Z([Flow doesn't run])
  TC -->|Yes| DE{"DispatchEnabled = Yes?"}
  DE -->|No| CX[/"Cancelled - nothing sent"/]:::info
  DE -->|Yes| GL{"First published before<br/>UrgentGoLiveDate?"}
  GL -->|Yes| OLD[/"Stopped - old or migrated post"/]:::info
  GL -->|No| UP{"Author or last editor<br/>an urgent publisher?"}
  UP -->|No| NA[/"Skipped - not an urgent publisher;<br/>Comms told once"/]:::bad
  UP -->|Yes| AT{"Audience targeted?"}
  AT -->|Yes| AS[/"Skipped - audience targeted;<br/>Comms told once"/]:::info
  AT -->|No| DS["Port rows in Comms Distribution<br/>(All ports post: every port row;<br/>the All ports row never gets urgent alerts)"]
  DS --> ND{"Any destinations?"}
  ND -->|No| NDL[/"Skipped - no destinations;<br/>Comms told once"/]:::bad
  ND -->|Yes| RS[["Reserve, then send per destination: email and Teams<br/>key urgent|site|page|round|port|channel"]]
  RS --> ALL{"All sent?"}
  ALL -->|Yes| US[/"UrgentSent = Yes<br/>(no new version, no draft)"/]:::good
  ALL -->|No| AL[/"UrgentSent stays No; support alerted;<br/>resubmitting sends only Failed rows"/]:::bad
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

A correction is sent by raising **NotificationRound** and setting UrgentSent
back to No, then republishing: the new round gives new keys.

## Reserve then send (C2 and C3, per email or Teams destination)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'fontFamily': 'Source Sans 3, Source Sans Pro, Segoe UI, sans-serif', 'fontSize': '15px', 'primaryColor': '#f0f2f6', 'primaryBorderColor': '#5e616d', 'primaryTextColor': '#31333f', 'lineColor': '#5e616d', 'clusterBkg': '#f8f9fb', 'clusterBorder': '#cdd0d8', 'edgeLabelBackground': '#ffffff', 'tertiaryColor': '#ffffff'}}}%%
flowchart TD
  A([Destination with an email group or Teams channel]) --> K{"Delivery Log row<br/>for this key?"}
  K -->|None| R1["Write Reserved row<br/>(key is unique and indexed)"]
  K -->|Failed| R2["Set the row back to Reserved"]
  K -->|"Sent, Reserved or Reconcile"| SKIP([Skip: already handled or waiting for a person])
  R1 & R2 --> RS{"Reservation saved?"}
  RS -->|No| RF[/"Not sent - another run holds the key;<br/>recorded as a failure"/]:::bad
  RS -->|Yes| S["Send once (no automatic retry)"]
  S --> O{"Outcome"}
  O -->|Delivered| SENT[/"Sent"/]:::good
  O -->|"4xx, not 408 / 429"| FAILED[/"Failed - resent on the next run"/]:::bad
  O -->|"Timeout, 5xx or throttled"| REC[/"Reconcile - a person checks the<br/>Needs checking view, sets Failed to resend"/]:::info
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```
