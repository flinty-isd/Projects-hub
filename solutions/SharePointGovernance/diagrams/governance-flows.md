# SharePoint governance flows — process diagrams

One diagram per flow in `../powerautomate/flows/`. Flow 04 (InfoPath
triage) was retired on 25 October 2026 (PID v4.2: InfoPath retired, triage by
the Criticality Decision Tree). Each diagram shows the
decision the flow enforces and who approves it. Green ends are grants or
approvals, red ends are blocks or rejections. Role names map to people in
[`../README.md`](../README.md#roles).

## Overview

```mermaid
flowchart LR
  subgraph Access["Access & identity"]
    F1["01 Access request"] --> F2["02 Guest expiry"]
    F3["03 Site provisioning"] --> F6["06 Access recertification"]
    F1 -. grants via .-> SR[("Site Register")]
    F3 --> SR
    F6 --> SR
  end
  subgraph Content["Content disposition"]
    F5["05 File share disposition"]
  end
  subgraph Board["Governance decisions"]
    F7["07 Board paper approval"] --> DL[("Decision Log")]
  end
```

## 01 — Access request (Access Method Decision Table)

```mermaid
flowchart TD
  A([New Access Requests item]) --> T{User type}
  T -->|Service / shared account| X1[/"Rejected - Prohibited"/]:::bad
  T -->|No Microsoft licence| V[/"Closed - use Base8 CMS<br/>in the Employee App"/]:::info
  T -->|Screen / kiosk| K[/"Closed - use published display page"/]:::info
  T -->|Employee - edit| L1{"M365 licence incl.<br/>SharePoint? (min F3)"}
  L1 -->|No| B1[/"Blocked - licence required"/]:::bad
  L1 -->|Yes| AP1{"Site primary owner<br/>approves?"}
  T -->|Site Owner / Author| L2{"SharePoint licence<br/>(E3 or equiv.)?"}
  L2 -->|No| B1
  L2 -->|Yes| P2{"Entra ID P2?"}
  P2 -->|No| B2[/"Blocked - Entra ID P2 required"/]:::bad
  P2 -->|Yes| AP2{"Line manager AND<br/>service owner approve?"}
  T -->|Long-term contractor| TB{"End date set and<br/>within 90 days?"}
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
  E -->|Yes| AR{"GuestAutoRemoval = Yes?<br/>(Board ruling, D-GSA-03)"}
  AR -->|Yes| R[/"Remove from Guests group,<br/>mark Expired, tell sponsor, owner + InfoSec"/]:::bad
  AR -->|No| OD{"Site owner or sponsor<br/>confirms removal? (G-11)"}
  OD -->|Yes| R
  OD -->|No| K[/"Kept - owner decision;<br/>InfoSec told, new request needed"/]:::info
  E -->|No| M{"Reminder already sent?"}
  M -->|No| N[/"Remind sponsor + owner once;<br/>renewal = new access request (90 days max)"/]:::info
  M -->|Yes| Z([Nothing to do])
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

## 03 — Site provisioning

```mermaid
flowchart TD
  A([New Site Requests item]) --> NM{"Alias follows<br/>[org]-[location]-[dept]-[site]? (G-08)"}
  NM -->|No| XN[/"Returned - naming standard"/]:::bad
  NM -->|Yes| V{"Two different, enabled,<br/>internal named owners +<br/>Owners/Members groups?"}
  V -->|No| X[/"Returned - ownership invalid"/]:::bad
  V -->|Yes| SO{"Service owner approves?"}
  SO -->|No| R1[/"Rejected"/]:::bad
  SO -->|Yes| S{"External sharing or<br/>Highly Confidential?"}
  S -->|Yes| IS{"InfoSec approves?"}
  IS -->|No| R2[/"Rejected by InfoSec"/]:::bad
  IS -->|Yes| C
  S -->|No| C["Create team site (STS#3)"]
  C --> OK{"Site ready?"}
  OK -->|No| F[/"Provisioning failed -> service owner"/]:::bad
  OK -->|Yes| GT{"IT Ops applies + registers<br/>Sites.Selected grant? (G-04)"}
  GT -->|No| F2[/"Provisioning failed - no grant,<br/>baseline not applied"/]:::bad
  GT -->|Yes| RB["Runbook (managed identity): groups only,<br/>secondary admin, sharing off unless approved,<br/>no custom script, sensitivity label; ###RESULT###"]
  RB --> REG[/"Add to Site Register<br/>(next access review +90 days), notify owners"/]:::good
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
  ST -->|No| MG{"Owner AND service owner<br/>approve migration?"}
  MG -->|No| DR[/"Disposition required -> IT Ops"/]:::bad
  MG -->|Yes| PC{"Permission complexity High?"}
  PC -->|Yes| RM[/"Remediate permissions first"/]:::info
  PC -->|No| RD[/"Ready for migration"/]:::good
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```

## 06 — Access recertification (monthly; 90-day cycle per site)

```mermaid
flowchart TD
  A([1st of month 07:00]) --> D["Active sites with<br/>review due"]
  D --> O{"Primary owner<br/>account enabled?"}
  O -->|No| OR[/"Orphaned -> service owner + IT Ops<br/>promote secondary owner"/]:::bad
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

## 07 — Board paper approval (TAB or BAU governance forum)

```mermaid
flowchart TD
  A([New Board Approval Requests item]) --> C{"Decision requested, https links,<br/>approvers set for the forum?"}
  C -->|No| R[/"Returned - incomplete<br/>presenter told"/]:::bad
  C -->|Yes| IR["In review"]
  IR --> AP{"Every forum member responds<br/>(28 days)"}
  AP -->|Not all responded| EX[/"Expired - no decision<br/>presenter and service owner told"/]:::bad
  AP -->|Any Reject| RJ[/"Rejected"/]:::bad
  AP -->|Any Approve with conditions| AC[/"Approved with conditions"/]:::info
  AP -->|All Approve| OK[/"Approved"/]:::good
  RJ --> DL[("Decision Log<br/>category Board paper")]
  AC --> DL
  OK --> DL
  classDef good fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef bad fill:#fee2e2,stroke:#b91c1c,color:#7f1d1d
  classDef info fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
```
