# 📊 SharePoint dashboards

Two dashboards over SharePoint list data — a **PM dashboard** (project status,
timeline, KPIs, risks/issues) and an **IT Governance site** (policies, control
compliance, audit findings, risk register, exceptions).

## Native mode — the chosen route

Both dashboards render **natively inside SharePoint**. Nothing to host, no
Azure AD app registration, and SharePoint's own permissions apply.

1. **`/provisioning`** — PnP PowerShell that creates the seven lists, with the
   exact internal column names everything else expects. Plus a sample-data
   seeder.
2. **`/sharepoint-modern`** — JSON column/view formatting (status pills, a
   `% Complete` progress bar, red past-due dates, amber expiry warnings, a
   heat-coloured risk score) and PnP scripts that apply it and build the two
   modern pages.

```powershell
.\provisioning\Provision-SharePointLists.ps1 -SiteUrl $url -ClientId $id
.\sharepoint-modern\Apply-Formatting.ps1     -SiteUrl $url -ClientId $id
.\sharepoint-modern\Provision-ModernPages.ps1 -SiteUrl $url -ClientId $id -Publish
```

Each folder's README has the detail, including what native mode gives up
(the Gantt timeline and the 5×5 heat-map grid — see the "Charts" notes in
`sharepoint-modern/README.md`).

**[`DEPLOYMENT.md`](DEPLOYMENT.md)** is the runbook for a real M365 tenant:
prerequisites and permissions, site layout, dry run and verification,
promoting dev → test → prod, unattended pipeline runs, and how Microsoft
Fabric and Copilot agents layer on top of the same lists.

## Hosted app implementations

Kept as an alternative for anyone who needs the custom charts and the Gantt, or
who wants the data outside SharePoint's own rendering. It falls back to demo
data when no credentials are configured, so it renders immediately.

- **`/` (root)** — Python/Streamlit PM dashboard, and the `pytest` suite and
  CI that run against it. See "Streamlit version" below.

## Streamlit version

### How to run it locally

1. Install the requirements

   ```
   $ pip install -r requirements.txt
   ```

2. Run the app

   ```
   $ streamlit run streamlit_app.py
   ```

Without any SharePoint credentials configured, the app runs in **demo
mode** with sample project data, so you can explore the UI immediately.

### Connecting to live SharePoint data

The dashboard reads two SharePoint lists — a **Tasks** list and a
**Risks** list — via the Microsoft Graph API, using an app-only
(client-credentials) connection.

1. **Register an Azure AD app** (Azure Portal → App registrations → New
   registration).
2. Under **API permissions**, add a Microsoft Graph **Application**
   permission: `Sites.Read.All`, then click **Grant admin consent**.
3. Under **Certificates & secrets**, create a client secret and copy its
   value immediately (it's only shown once).
4. Note your **Tenant ID**, the app's **Client ID**, and the client
   secret.
5. Copy `.streamlit/secrets.toml.example` to `.streamlit/secrets.toml`
   (already gitignored — never commit real secrets) and fill in:
   - `tenant_id`, `client_id`, `client_secret` from steps 2–4
   - `site_hostname` (e.g. `contoso.sharepoint.com`) and `site_path`
     (e.g. `/sites/YourProjectSite`) for your SharePoint site
   - `tasks_list` / `risks_list` — the display names (or list IDs) of
     your Tasks and Risks lists
6. Restart the app. If credentials are valid, it switches from demo mode
   to live data automatically; if a Graph call fails, the app falls back
   to demo data and shows the error instead of crashing.

**List field mapping:** the dashboard expects standard field names
(`Title`, `Status`, `AssignedTo`, `StartDate`, `DueDate`,
`PercentComplete`, `Priority` for tasks; `Title`, `Severity`, `Owner`,
`Status`, `Description` for risks). If your lists use different internal
column names, edit `TASK_FIELD_MAP` / `RISK_FIELD_MAP` in
`data_transform.py` to match (find internal names via Graph Explorer:
`GET /sites/{site-id}/lists/{list-id}/columns`).

When deploying to Streamlit Community Cloud, set the same keys under the
app's **Secrets** settings instead of committing a `secrets.toml` file.

### Project structure

- `streamlit_app.py` — the dashboard UI (Overview, Timeline, KPIs, Risks tabs)
- `sharepoint_client.py` — Microsoft Graph API auth and list-fetching
- `data_transform.py` — maps raw Graph list items to normalized DataFrames
- `kpis.py` — pure functions computing dashboard metrics
- `mock_data.py` — sample data used in demo mode and in tests

### Running tests

```
$ pip install -r requirements-dev.txt
$ pytest
```

