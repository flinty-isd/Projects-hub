# 📊 SharePoint PM Dashboard

Two implementations of the same dashboard for tracking project status,
timeline, KPIs, and risks/issues, backed by SharePoint task and risk lists
via the Microsoft Graph API:

- **`/` (root)** — a Python/Streamlit version. See below.
- **`/aspx`** — a classic ASP.NET Web Forms (`.aspx`) version for IIS/on-prem
  hosting. See "ASP.NET Web Forms version" further down.

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

## ASP.NET Web Forms version

The `/aspx` folder is a classic ASP.NET Web Forms port of the same
dashboard (Overview, Timeline, KPIs, Risks & Issues), for teams that need
to host this on IIS/on-prem infrastructure rather than Streamlit.

**Important limitation:** classic Web Forms (`.aspx`) only runs on .NET
Framework under IIS on Windows — it cannot be built or run on Linux/macOS
or with the modern cross-platform `dotnet` CLI. This code has been
reviewed carefully but **has not been compiled or run**, since no Windows
build environment was available when it was written. Open it in Visual
Studio (File → Open → Web Site → select the `aspx` folder) or deploy it to
an IIS server to verify it builds before relying on it.

### Setup

1. **Open as a Website project.** `/aspx` is structured as a classic ASP.NET
   "Web Site" (not a Web Application with a `.csproj`) — App_Code compiles
   automatically, no project file needed. In Visual Studio: File → Open →
   Web Site.
2. **Add required assemblies.** The SharePoint integration needs
   `Microsoft.Identity.Client` (MSAL.NET) and `Newtonsoft.Json`. Install
   them via the NuGet Package Manager Console (`Install-Package
   Microsoft.Identity.Client`, `Install-Package Newtonsoft.Json`) against
   the site, or place the DLLs directly in `/aspx/bin`.
3. **Configure SharePoint credentials** in `aspx/Web.config` under
   `<appSettings>` (same Azure AD app registration steps as the Streamlit
   version above: register an app, grant it the `Sites.Read.All` Graph
   application permission with admin consent, create a client secret).
   Leave any value blank to run in demo mode with sample data. Don't
   commit real secrets to `Web.config` in production — use IIS/Azure App
   Service application settings instead.
4. Deploy to IIS (or run via Visual Studio's IIS Express) and browse to
   `Default.aspx`.

### Project structure

- `Default.aspx` / `Timeline.aspx` / `Kpis.aspx` / `Risks.aspx` — the four
  dashboard tabs, each a page + code-behind pair
- `Site.Master` — shared layout, nav tabs, and the demo/live/error banner
- `App_Code/SharePointClient.cs` — Microsoft Graph API auth (MSAL.NET) and
  list-fetching, mirroring `sharepoint_client.py` and `data_transform.py`
- `App_Code/Kpis.cs` — the same KPI calculations as `kpis.py`
- `App_Code/MockData.cs` — the same sample data as `mock_data.py`
- `App_Code/DashboardDataProvider.cs` — live-vs-demo-mode fallback and caching
- `App_Code/FilterState.cs` — persists the Overview tab's filters in
  Session so the Timeline/KPIs tabs can apply them too (each `.aspx` page
  is a separate request, unlike Streamlit's single shared process)

Charts use Google Charts (loaded from `gstatic.com`) and the timeline is a
simple CSS-bar Gantt — no server-side charting library dependency.
