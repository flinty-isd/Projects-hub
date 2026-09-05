# Target Architecture

```
                       ┌─────────────────────────┐
                       │      SharePoint list      │
                       │  (replaces InfoPath XML)  │
                       └───────────▲───────────────┘
                                   │ Patch / SubmitForm
                       ┌───────────┴───────────────┐
   End user  ───────►  │   Power Apps canvas app     │
                       │ (replaces InfoPath form UI) │
                       └───────────┬───────────────┘
                                   │ item created/modified
                       ┌───────────▼───────────────┐
                       │   Power Automate cloud flow │
                       │ (replaces InfoPath rules/   │
                       │  data connections/workflow) │
                       └───────────┬───────────────┘
                                   │ approvals, email, updates
                       ┌───────────▼───────────────┐
                       │  Approvers / Outlook / Teams │
                       └─────────────────────────────┘
```

## Environments

Use the standard three-tier Power Platform environment strategy:

| Environment | Purpose | Solution type |
|---|---|---|
| Dev | Individual/shared development environment, unmanaged solution | Unmanaged |
| Test/UAT | Automated deploy target from CI on every merge to `main` | Managed |
| Prod | Promoted manually (or via a release approval) from Test | Managed |

## ALM pipeline

Repository layout mirrors what `pac solution` works with:

```
solutions/<SolutionName>/
  sharepoint/list-schema.json   # source of truth for list columns (applied via PnP/Graph, not part of the Dataverse solution zip)
  powerapps/src/                # pac canvas source (.pa.yaml), unpacked
  powerautomate/flows/*.json    # flow definitions, unpacked
```

`.github/workflows/power-platform-ci.yml`:

1. **On pull request**: pack the unmanaged solution from source (`pac solution pack`)
   to validate it builds cleanly, and run solution checker
   (`microsoft/powerplatform-actions@checker`).
2. **On merge to `main`**: pack as a **managed** solution and import into the
   Test/UAT environment (`microsoft/powerplatform-actions@import-solution`).
3. **Promotion to Prod** is a manual `workflow_dispatch` run of the same import
   step pointed at the Prod environment secret, so production releases are a
   deliberate action.

## Secrets required (repository or environment secrets)

| Secret | Purpose |
|---|---|
| `POWER_PLATFORM_SP_APP_ID` | Service principal (or user) app ID for `pac auth` |
| `POWER_PLATFORM_SP_CLIENT_SECRET` | Service principal secret |
| `POWER_PLATFORM_TENANT_ID` | Azure AD tenant ID |
| `POWER_PLATFORM_TEST_URL` | Test/UAT environment URL |
| `POWER_PLATFORM_PROD_URL` | Prod environment URL |

These are placeholders — nothing in this repo can authenticate to a real tenant
until an admin creates the service principal and adds these secrets.
