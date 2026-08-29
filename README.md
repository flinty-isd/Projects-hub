# 📊 SharePoint PM Dashboard

A Streamlit dashboard for tracking project status, timeline, KPIs, and
risks/issues, backed by SharePoint task and risk lists via the Microsoft
Graph API.

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
