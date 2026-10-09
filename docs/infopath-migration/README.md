# InfoPath Migration Program

Microsoft retired InfoPath (mainstream support ended 2021, InfoPath Forms Services in
SharePoint on-prem/online is being phased out). This directory tracks the effort to
replace remaining InfoPath forms with supported Microsoft 365 tooling:

| InfoPath capability            | Replacement                                   |
|---------------------------------|-----------------------------------------------|
| Form design / data entry UI     | **Power Apps** (canvas app)                   |
| Business logic, rules, workflow | **Power Automate** (cloud flow)                |
| Data storage (XML/InfoPath list)| **SharePoint list** or **Dataverse table**    |
| Publishing to a SharePoint lib  | Power Apps embedded on a SharePoint page/list |
| Form approvals / routing        | Power Automate approvals connector            |

## Contents

- [`migration-guide.md`](./migration-guide.md) — step-by-step process for converting
  one InfoPath form into a Power Apps + Power Automate solution.
- [`architecture.md`](./architecture.md) — target architecture and ALM approach.
- [`../../solutions/ITEquipmentRequest`](../../solutions/ITEquipmentRequest) — a
  fully worked example migration (source-controlled, ready to `pac` push into an
  environment) that new migrations can be copied from.
- [`../../solutions/AssetManagementDisposal`](../../solutions/AssetManagementDisposal) —
  a second example covering a two-list solution with a compliance gate (asset
  register + disposal request approval, blocking disposal of data-bearing
  assets without a data-wipe certificate).
- [`../../solutions/HolidayRequest`](../../solutions/HolidayRequest) — a third
  example covering a balance-tracked approval (leave request checked against
  a remaining-entitlement calculation before it's routed to a manager, with
  the approved days booked to a shared calendar).

## Why source-control the solution?

Power Apps and Power Automate assets live in a Power Platform environment by default,
not in git. We use the [Power Platform CLI](https://learn.microsoft.com/power-platform/developer/cli/introduction)
(`pac`) to export/unpack solutions into readable text (YAML/JSON) so they can be
code-reviewed, diffed, and deployed through GitHub Actions like any other code —
see [`architecture.md`](./architecture.md#alm-pipeline) and
[`.github/workflows/power-platform-ci.yml`](../../.github/workflows/power-platform-ci.yml).

## Migration backlog

A full inventory of the organization's 43 live InfoPath forms has been received
(`form-inventory.csv`, `workflow-inventory.csv` — parsed from
`InfoPath_Form_Detailed_Summary_2.xlsx`, totals cross-checked against the
source spreadsheet's own TOTALS row). This replaces the placeholder backlog —
see [`triage.md`](./triage.md) for the full list, complexity metrics, and a
priority tiering by rebuild effort.

**Totals across all 43 forms:** 188 pages, 4,296 fields, 3,771 rules, 3,040
conditions, 10,199 actions, 280 estimated rebuild-days for the forms
themselves, plus 41 associated SharePoint workflows totalling 195 estimated
rebuild-hours.

### Status of forms already prototyped in this repo

| Form name | In real inventory? | Status | Solution folder |
|-----------|---------------------|--------|------------------|
| Holiday Request | ✅ yes — 3 pages, 38 fields, 29 rules, 63 actions, **no workflow listed** | ⚠️ Prototype built *before* the real inventory arrived — simplified (~10 fields vs. 38 real) and adds an approval flow the real form doesn't have. Needs revisiting against the real field list. | `solutions/HolidayRequest` |
| Asset Disposal Request | ✅ yes — 8 pages, 202 fields, 314 rules, 882 actions, 1 workflow (**30 hours** to rebuild — the single most complex workflow in the inventory) | ⚠️ Prototype built as "Asset Management & Disposal" *before* the real inventory arrived — far simpler than the real form (202 fields vs. ~10 modeled). This is one of the hardest forms in the whole set; treat the prototype as a starting pattern only. | `solutions/AssetManagementDisposal` |
| IT Equipment Request | ❌ not in the real inventory | Generic example built before any real form list was available. Closest real analogs are `Mobile Device Hardware`, `Mobile Device SIM Only`, and `New Employee IDACs Request`. | `solutions/ITEquipmentRequest` |

To migrate a new form from the real inventory: copy the
`solutions/ITEquipmentRequest` folder structure and follow
`migration-guide.md`, using the row in `form-inventory.csv` /
`workflow-inventory.csv` for that form to size the work — but note the CSV
only has field/rule *counts*, not the actual field names, types, or rule
logic. **The next concrete step for any given form is extracting its real
field list and rules from the `.xsn` template** (or a walkthrough of the live
form), since the summary alone isn't enough to rebuild it faithfully.

