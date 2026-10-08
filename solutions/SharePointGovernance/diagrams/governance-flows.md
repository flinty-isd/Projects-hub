# SharePoint governance flows — process diagrams

One diagram per flow in `../powerautomate/flows/`. Each diagram shows the
decision the flow enforces and who approves it. Green ends are grants or
approvals, red ends are blocks or rejections. Role names map to people in
[`../README.md`](../README.md#roles).

## Overview

```mermaid
flowchart LR
  subgraph Access["Access & identity"]
    F1["01 Access request"] --> F2["02 Guest expiry"]
    F3["03 Site provisioning"] --> F8["08 Access recertification"]
    F1 -. grants via .-> SR[("Site Register")]
    F3 --> SR
    F8 --> SR
  end
  subgraph Content["Content disposition"]
    F4["04 InfoPath triage"]
    F5["05 File share disposition"]
  end
  subgraph Control["Project control"]
    F6["06 Change control"]
    F7["07 Wave readiness & sign-off"]
    F9["09 RAID escalation"]
  end
  F4 & F6 & F7 --> DL[("Decision Log")]
  F9 -. tolerance breach .-> F6
```

## 01 — Access request (Access Method Decision Table)

```mermaid
flowchart TD
  A([New Access Requests item]) --> T{User type}
  T -->|Service / shared account| X1[/"Rejected - Prohibited"/]:::bad
  T -->|Employee - view only| V[/"Closed - use Employee App"/]:::info
  T -->|Screen / kiosk| K[/"Closed - use published display page"/]:::info
  T -->|Employee - edit| L1{"M365 licence incl.<br/>SharePoint? (min F3)"}
  L1 -->|No| B1[/"Blocked - licence required"/]:::bad
  L1 -->|Yes| AP1{"Site primary owner<br/>approves?"}
  T -->|Site Owner / Author| L2{"SharePoint licence<br/>(E3 or equiv.)?"}
  L2 -->|No| B1
  L2 -->|Yes| P2{"Entra ID P2?"}
  P2 -->|No| B2[/"Blocked - Entra ID P2 required"/]:::bad
  P2 -->|Yes| AP2{"Line manager AND<br/>Project Manager approve?"}
  T -->|Long-term contractor| TB{"End date set and<br/>within 12 months?"}
  TB -->|No| X2[/"Rejected - not time-bound"/]:::bad
  TB -->|Yes| AP3{"Site owner AND<br/>InfoSec approve?"}
  AP3 -->|Yes| G[/"Invite guest, add to Guests group,<br/>register end date (read-only)"/]:::good
  T -->|Privileged admin| AP4{"InfoSec approves?"}
  AP4 -->|Yes| PIM[/"IT Ops creates PIM<br/>eligible assignment"/]:::good
  AP1 & AP2 -->|Yes| SG{"Target group synced<br/>from on-prem AD?"}
  SG -->|Yes| SD[/"Service Desk ticket:<br/>add to AD group"/]:::good
  SG -->|No| GR[/"Add to Entra group -> Granted"/]:::good
  AP1 & AP2 & AP3 & AP4 -->|No| R[/"Rejected + comments"/]:::bad
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

## 02 — Guest access expiry (daily)

```mermaid
flowchart TD
  A([Daily 06:00]) --> Q["Active guests ending<br/>within 14 days"]
  Q --> E{"End date passed?"}
  E -->|Yes| R[/"Remove from Guests group,<br/>mark Expired, tell sponsor + InfoSec"/]:::bad
  E -->|No| M{"Reminder already sent?"}
  M -->|No| N[/"Remind sponsor once;<br/>renewal = new access request"/]:::info
  M -->|Yes| Z([Nothing to do])
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

## 03 — Site provisioning

```mermaid
flowchart TD
  A([New Site Requests item]) --> V{"Two different, enabled,<br/>internal named owners +<br/>Owners/Members groups?"}
  V -->|No| X[/"Returned - ownership invalid"/]:::bad
  V -->|Yes| PM{"Project Manager approves?"}
  PM -->|No| R1[/"Rejected"/]:::bad
  PM -->|Yes| S{"External sharing or<br/>Highly Confidential?"}
  S -->|Yes| IS{"InfoSec approves?"}
  IS -->|No| R2[/"Rejected by InfoSec"/]:::bad
  IS -->|Yes| C
  S -->|No| C["Create team site (STS#3)"]
  C --> OK{"Site ready?"}
  OK -->|No| F[/"Provisioning failed -> PM"/]:::bad
  OK -->|Yes| RB["Runbook: groups only, secondary admin,<br/>sharing off unless approved,<br/>no custom script, sensitivity label"]
  RB --> REG[/"Add to Site Register<br/>(next access review +90 days), notify owners"/]:::good
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
```

## 04 — InfoPath triage (Replace / Retire, never as-is)

```mermaid
flowchart TD
  A([New InfoPath Register item]) --> U{"No submissions in 12 months,<br/>or Low criticality and fewer than 10?"}
  U -->|Yes| RT["Recommend Retire<br/>(export data to read-only archive)"]
  U -->|No| CX{"More than 10 rules, data connections,<br/>code-behind or repeating sections?"}
  CX -->|Yes| PA["Recommend Replace:<br/>Power Apps + Power Automate"]
  CX -->|No| SL["Recommend Replace:<br/>SharePoint List + Power Automate"]
  RT & PA & SL --> O{"Business owner accepts?"}
  O -->|Yes| D[/"Triaged; Decision Log; BA adds to backlog"/]:::good
  O -->|No| DS[/"Triage disputed -> BA agrees<br/>Replace or Retire with owner"/]:::bad
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
```

## 05 — File share disposition (selective migration)

```mermaid
flowchart TD
  A([New File Share Register item]) --> SD{"Integration marker, app back-end<br/>or generic account?"}
  SD -->|Yes| EX[/"Excluded - system dependent;<br/>IT Ops agrees remediate / archive /<br/>delete / move to non-SPO"/]:::bad
  SD -->|No| ST{"Unmodified for 3+ years?"}
  ST -->|Yes| AR{"Owner approves archive?"}
  AR -->|Yes| ARC[/"Archive - disposition agreed"/]:::info
  AR -->|No| MG
  ST -->|No| MG{"Owner AND Project Manager<br/>approve migration?"}
  MG -->|No| DR[/"Disposition required -> IT Ops"/]:::bad
  MG -->|Yes| PC{"Permission complexity High?"}
  PC -->|Yes| RM[/"Remediate permissions first"/]:::info
  PC -->|No| RD[/"Ready for migration"/]:::good
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

## 06 — Change control (tolerance-based authority)

```mermaid
flowchart TD
  A([New Change Log item]) --> T{"Schedule within ±5 days AND<br/>cost within ±£5,000 AND<br/>no material scope change?"}
  T -->|Yes| PM{"IT Project Manager decides"}
  T -->|No| SB{"Sponsor AND Portfolio<br/>Manager both approve?"}
  PM & SB -->|Approve| AP[/"Approved"/]:::good
  PM & SB -->|Reject| RJ[/"Rejected"/]:::bad
  AP & RJ --> DL[("Decision Log + notify raiser")]
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
```

## 07 — Wave readiness and sign-off

```mermaid
flowchart TD
  A([Wave Plan: Gate Status changed]) --> S{"Which gate?"}
  S -->|Readiness review requested| C{"All checks true and<br/>not in blockout?"}
  C -->|No| NR[/"Readiness failed:<br/>missing items -> PM"/]:::bad
  C -->|Yes| GO{"PM AND IT Ops approve?"}
  GO -->|Yes| G[/"Go - migration authorised"/]:::good
  GO -->|No| NG[/"No-go"/]:::bad
  S -->|Sign-off requested| EV{"ShareGate report AND<br/>validation checklist?"}
  EV -->|No| BL[/"Sign-off blocked - evidence missing"/]:::bad
  EV -->|Yes| SO{"Business owner AND<br/>PM sign off?"}
  SO -->|Yes| H[/"Signed off - hypercare;<br/>handover to IT Ops (BAU, no vendor ELS)"/]:::good
  SO -->|No| RM[/"Remediate: RAID, re-run passes"/]:::bad
  G & NG & H --> DL[("Decision Log")]
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
```

Readiness checks: prerequisites DEP001–DEP005, ShareGate licence, site
owners confirmed, permission baseline approved, digital spring clean, site
owner comms (2 weeks before), super users briefed (1 week before), Service
Desk briefed, peer-tenant window agreed.

## 08 — Access recertification (monthly; 90-day cycle per site)

```mermaid
flowchart TD
  A([1st of month 07:00]) --> D["Active sites with<br/>review due"]
  D --> O{"Primary owner<br/>account enabled?"}
  O -->|No| OR[/"Orphaned -> PM + IT Ops<br/>promote secondary owner"/]:::bad
  O -->|Yes| L["List Owners + Members groups,<br/>email owner"]
  L --> RC{"Owner recertifies?"}
  RC -->|Yes| OK[/"Logged; next review +90 days"/]:::good
  RC -->|No| RM[/"Logged; removals -> Service Desk"/]:::info
  A --> Q{"Jan / Apr / Jul / Oct?"}
  Q -->|Yes| P{"InfoSec confirms SharePoint Admin<br/>role is PIM-eligible only?"}
  P --> PL[("Access Review Log")]
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

## 09 — RAID weekly escalation

```mermaid
flowchart TD
  A([Monday 07:00]) --> F["Open RAID items that are High,<br/>overdue, unowned or<br/>forecast to exceed tolerance"]
  F --> N{"Any?"}
  N -->|No| Z([Nothing to send])
  N -->|Yes| PM[/"Digest -> Project Manager<br/>for weekly checkpoint"/]:::info
  PM --> T{"Any forecast to<br/>exceed tolerance?"}
  T -->|Yes| SP[/"Exception -> Sponsor + Portfolio<br/>(raise change request)"/]:::bad
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```
