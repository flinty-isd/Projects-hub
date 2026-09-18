# 🔐 SharePoint Permissions Audit

A Streamlit app that shows the **current** permissions on a SharePoint site:
site-level role assignments plus any document libraries/lists that have
broken inheritance and carry their own unique permissions.

### Prerequisites

An Azure AD (Entra ID) app registration with the **SharePoint** (not Graph)
application permission `Sites.FullControl.All` (or `Sites.Read.All` for
read-only access), admin-consented in your tenant. You'll need its tenant ID,
client ID, and a client secret.

### How to run it on your own machine

1. Install the requirements

   ```
   $ pip install -r requirements.txt
   ```

2. Run the app

   ```
   $ streamlit run streamlit_app.py
   ```

3. In the sidebar, enter the tenant ID, client ID, client secret, and the
   SharePoint site URL (e.g. `https://contoso.sharepoint.com/sites/Marketing`),
   then click **Fetch current permissions**.

   Credentials can also be supplied via `.streamlit/secrets.toml` as
   `TENANT_ID`, `CLIENT_ID`, and `CLIENT_SECRET` instead of typing them in
   each run.
