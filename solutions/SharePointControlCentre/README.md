# HPUK Project Control Centre (Tier 1 — native SharePoint, no SPFx)

Four modern SharePoint pages reporting on site migration and page delivery,
built entirely from native SharePoint — List web parts, Quick Chart web
parts, and column/view formatting JSON. No custom code, no SPFx package, no
Power Automate flow. This is Tier 1 of two: see
[Tier 2](#tier-2-later-only-if-tier-1-genuinely-isnt-enough) below for what a
Power Automate upgrade would add and why it isn't built yet.

| Page | What's native about it |
|---|---|
| Programme Control Centre | A Quick Chart (Migration Status distribution) plus four stacked List web parts standing in for a single "Attention Required" view — see [diagrams/page-layout.md](diagrams/page-layout.md#why-four-separate-exception-widgets-not-one-merged-table) for why it's four, not one |
| Migration | Residual migration only; same Quick Chart, filtered List web parts for Next 30 Days / Blocked-Amber / Remaining / Completed |
| People & Pages | The People page (`PAGE-001`) delivery stage shown as a progress bar via column formatting on `SP_PageDelivery`'s Delivery Status column — no SPFx stepper needed |
| Governance / Control Board | Two Quick Charts (RAID by RAG, Actions by RAG) plus the RAID/Actions/Decisions/Scope-changes/Snapshot-history List web parts |

## Layout

```
SharePointControlCentre/
├── sharepoint/
│   ├── list-schema.json              the 6 lists: SP_MigrationRegister (already live) + 5 new
│   └── column-formatting/
│       └── DeliveryStatus.json       the People & Pages progress bar
├── runbooks/
│   └── Set-ControlCentreLists.ps1    creates the 5 new lists from list-schema.json; patches
│                                      SP_MigrationRegister with any missing fields only
└── diagrams/
    └── page-layout.md                one Mermaid diagram per page, web part by web part
```

No `powerautomate/flows/`, `tools/`, or `solution-config.json` — there's
nothing to package into a Power Platform solution while Tier 1 has zero
flows. If Tier 2 happens, reuse `SharePointGovernance/tools/build_solution.py`
and `validate_flows.py` via their `--root` flag rather than duplicating them.

## Setup

1. **Create the lists.**
   ```powershell
   Install-Module PnP.PowerShell -Scope CurrentUser   # if not already installed
   .\runbooks\Set-ControlCentreLists.ps1 -SiteUrl "https://hutchisonports.sharepoint.com/sites/<your-site>"
   ```
   Safe to re-run — it only adds what's missing. `SP_MigrationRegister` is
   assumed to already exist (it's the list `HPUK_Migration_Register_Bulk_Update_1.xlsx`
   exports from); the script detects it and never recreates or renames it.

2. **Create the four modern pages** (Programme Control Centre, Migration,
   People & Pages, Governance) in Site Pages, and add the List web parts
   per [diagrams/page-layout.md](diagrams/page-layout.md), filtering/sorting
   each list's view as named there (e.g. a "Blocked or Amber Sites" view on
   `SP_MigrationRegister` filtered to `Migration Status = Blocked` or
   `Readiness RAG` in `(Amber, Red)`).

3. **Format the Delivery Status column.** On `SP_PageDelivery`, open the
   Delivery Status column's settings → *Format this column* → *Advanced
   mode* → paste [`sharepoint/column-formatting/DeliveryStatus.json`](sharepoint/column-formatting/DeliveryStatus.json).
   The 7 Delivery Status choices and their order in `list-schema.json` must
   match the JSON exactly — if either changes, update both together.

4. **Add the three Quick Chart web parts** by hand through the page editor
   (scripting Quick Chart's web part properties isn't reliable — this is a
   two-minute job each, done once):

   | Chart | List | Type | Group by | View filter |
   |---|---|---|---|---|
   | Migration Status distribution | `SP_MigrationRegister` | Bar | Migration Status | — |
   | RAID by RAG | `SP_RAID` | Donut | RAG | Status = Open |
   | Actions by RAG | `SP_Actions` | Donut | RAG | Status ne Closed |

## Tier 2 (later, only if Tier 1 genuinely isn't enough)

The one real native limitation: List and Quick Chart web parts each bind to
**one list at a time**, so there's no way to merge RAID + Actions + blocked
Migration sites + Decisions into a single "Attention Required" table or
chart without a Power Automate flow copying matching rows into one
consolidated list. Tier 1 deliberately doesn't build that flow — start with
the four stacked widgets, and only add the flow if control-board use shows
the stacked version is genuinely a problem in practice, not speculatively.

## Not in this solution

Per the Implementation Specification this is based on: a Copilot agent
(Agent Instructions document), and migrating the real
`HPUK_Migration_Register_Bulk_Update_1` workbook data into these lists.
Neither is a native-SharePoint-page question, so neither is addressed here.
