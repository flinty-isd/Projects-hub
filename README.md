# Projects Hub — InfoPath → Power Platform Migration

This repository tracks the migration of legacy Microsoft InfoPath forms to
**Power Apps**, **Power Automate**, and SharePoint/Dataverse data — see
[`docs/infopath-migration/`](docs/infopath-migration/README.md) for the
migration strategy, the per-form guide, and the target ALM architecture.

- [`docs/infopath-migration/`](docs/infopath-migration/README.md) — start here:
  why InfoPath is being retired, the replacement mapping, and the migration
  backlog.
- [`solutions/ITEquipmentRequest/`](solutions/ITEquipmentRequest/) — a fully
  worked example migration (SharePoint list schema, Power Apps canvas source,
  Power Automate flow) to copy for the next form.
- [`.github/workflows/power-platform-ci.yml`](.github/workflows/power-platform-ci.yml) —
  CI/CD pipeline that packs and deploys solutions from source.

## Blank Streamlit app template

The repository also still contains the original blank Streamlit template
(`streamlit_app.py`), kept for any lightweight internal tooling (e.g. a
migration-status dashboard) that may be built alongside the Power Platform work.

### How to run it on your own machine

1. Install the requirements

   ```
   $ pip install -r requirements.txt
   ```

2. Run the app

   ```
   $ streamlit run streamlit_app.py
   ```
