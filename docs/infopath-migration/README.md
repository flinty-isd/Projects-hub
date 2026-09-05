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

## Why source-control the solution?

Power Apps and Power Automate assets live in a Power Platform environment by default,
not in git. We use the [Power Platform CLI](https://learn.microsoft.com/power-platform/developer/cli/introduction)
(`pac`) to export/unpack solutions into readable text (YAML/JSON) so they can be
code-reviewed, diffed, and deployed through GitHub Actions like any other code —
see [`architecture.md`](./architecture.md#alm-pipeline) and
[`.github/workflows/power-platform-ci.yml`](../../.github/workflows/power-platform-ci.yml).

## Migration backlog

Track each legacy form as it moves through the pipeline. Add a row per form as they
are identified (fill in once real InfoPath forms are inventoried):

| Form name | Current host | Status | Solution folder |
|-----------|--------------|--------|------------------|
| IT Equipment Request | SharePoint on-prem list + InfoPath | ✅ Migrated (example) | `solutions/ITEquipmentRequest` |
| _(add next form here)_ | | 🔲 Not started | |

To add a new form, copy the `solutions/ITEquipmentRequest` folder structure and
follow `migration-guide.md`.
