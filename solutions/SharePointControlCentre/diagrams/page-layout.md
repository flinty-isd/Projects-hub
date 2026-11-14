# Control Centre page layout — native web parts only

One diagram per modern SharePoint page. Every box is a native out-of-the-box
web part (List web part, Quick Chart web part, or a Text/banner web part) -
nothing here is custom code. "List (view: X)" means a List web part bound to
that list, showing the named filtered view; "Quick Chart" means grouped/counted
from that list's own data, added manually through the page editor (see
[`../README.md`](../README.md) for the exact setup and why it isn't scripted).

```mermaid
flowchart TD
  subgraph PCC["Programme Control Centre"]
    direction TB
    B1["Banner: 209 sites complete baseline.<br/>LMS complete, not a blocker."]
    Q1["Quick Chart: Migration Status distribution<br/>(SP_MigrationRegister, group by Migration Status)"]
    L1["List: Blocked/Amber Sites<br/>(SP_MigrationRegister)"]
    L2["List: Overdue Actions<br/>(SP_Actions)"]
    L3["List: Red/Amber RAID<br/>(SP_RAID)"]
    L4["List: Pending Decisions<br/>(SP_Decisions)"]
    L5["List: Next 30 Days<br/>(SP_MigrationRegister)"]
    B1 --> Q1 --> L1
    L1 --- L2
    L3 --- L4
    L2 --> L3
    L4 --> L5
  end
```

```mermaid
flowchart TD
  subgraph MIG["Migration"]
    direction TB
    B2["Banner: LMS complete, not shown as a blocker here"]
    Q2["Quick Chart: Migration Status distribution<br/>(SP_MigrationRegister)"]
    M1["List: Next 30 Days<br/>(SP_MigrationRegister)"]
    M2["List: Blocked/Amber Sites<br/>(SP_MigrationRegister)"]
    M3["List: Remaining Sites<br/>(SP_MigrationRegister)"]
    M4["List: Completed Sites<br/>(SP_MigrationRegister)"]
    B2 --> Q2 --> M1
    M1 --- M2
    M3 --- M4
    M2 --> M3
  end
```

```mermaid
flowchart TD
  subgraph PPL["People & Pages"]
    direction TB
    B3["Banner: People is PAGE-001,<br/>a controlled deliverable, not an LMS blocker"]
    S1["List: Page Backlog, filtered to PAGE-001<br/>(SP_PageDelivery), Delivery Status column<br/>formatted as a stepper - see<br/>sharepoint/column-formatting/DeliveryStatus.json"]
    P1["List: Priority Queue<br/>(SP_PageDelivery, Critical/High, not Complete)"]
    P2["List: Ownership Gaps<br/>(SP_PageDelivery, Content/Delivery Owner blank)"]
    P3["List: Page Backlog, full<br/>(SP_PageDelivery, Out of Scope / Scope Change)"]
    B3 --> S1 --> P1
    P1 --- P2
    P2 --> P3
  end
```

```mermaid
flowchart TD
  subgraph GOV["Governance / Control Board"]
    direction TB
    B4["Banner: Control Board meeting landing page"]
    Q3["Quick Chart: RAID by RAG (SP_RAID, Status = Open)"]
    Q4["Quick Chart: Actions by RAG (SP_Actions, Status ne Closed)"]
    G1["List: Red/Amber RAID<br/>(SP_RAID)"]
    G2["List: Overdue Actions<br/>(SP_Actions)"]
    G3["List: Pending Decisions<br/>(SP_Decisions)"]
    G4["List: Scope Changes<br/>(SP_PageDelivery)"]
    G5["List: Weekly Snapshot History<br/>(SP_ProjectUpdates, sorted desc)"]
    B4 --> Q3 --> G1
    Q4 --> G2
    G1 --- G2
    G3 --- G4
    G2 --> G3
    G4 --> G5
  end
```

## Why four separate exception widgets, not one merged table

Both the List web part and the Quick Chart web part bind to **one list at a
time** - there's no native way to blend SP_RAID + SP_Actions +
SP_MigrationRegister + SP_Decisions into a single table or chart. Tier 1
accepts that and stacks the equivalent native widgets side by side instead,
as shown above. A true merged view would need a Power Automate flow copying
matching rows into one consolidated list - not built here; see
[`../README.md`](../README.md#tier-2) if that becomes worth the extra
plumbing.
