# Runbook: SharePoint Permissions Audit

Operational reference for running audits, rotating credentials, and
troubleshooting either version of this tool:

- **Streamlit app** (`streamlit_app.py`) — app-only auth via an Azure AD
  app registration, deployed as a web app.
- **Power Platform version** (`docs/power-platform-app.md`) — delegated
  auth via your own SharePoint access, native to Microsoft 365.

## Routine audit (either version)

1. Open the app (Streamlit URL, or the Power Apps mobile/web app).
2. Enter the target site URL and fetch current permissions.
3. Review the **site-level permissions** table and the **libraries/lists
   with unique permissions** table — the latter is usually the more
   interesting one, since it's where access silently diverges from the
   rest of the site.
4. Save this run as a snapshot (**Download as baseline snapshot** in
   Streamlit; **Save baseline** in Power Apps) so it can be diffed later.
5. To compare against a past state, load that earlier snapshot (upload the
   CSV in Streamlit; pick it from the dropdown in Power Apps) and review
   the **Added / Removed / Roles changed** results.

Recommended cadence: audit each site you're responsible for at a fixed
interval (e.g. monthly) and keep every snapshot — the value of "as is vs
as now" comparisons compounds over time as you build up a history.

## Credential rotation (Streamlit / Azure AD app registration)

The app registration's client secret expires (typically 6, 12, or 24
months depending on what was chosen at creation) and must be rotated
before then or the app stops authenticating.

1. In [entra.microsoft.com](https://entra.microsoft.com) → **App
   registrations** → find the app → **Certificates & secrets**.
2. Add a **new** client secret before deleting the old one (avoids a gap
   where neither secret is valid). Copy its value immediately.
3. Update the secret wherever it's stored:
   - Local `.streamlit/secrets.toml`
   - Streamlit Community Cloud → app **Settings → Secrets**
   - Any internal server's environment/secrets config
4. Confirm a fetch succeeds with the new secret.
5. Delete the old secret from the app registration.

Set a calendar reminder ~2 weeks before the secret's expiry date (visible
on the **Certificates & secrets** page) — there's no automatic warning
elsewhere.

## Access changes (Power Platform version)

Because the Power Automate flow runs as the signed-in user, permissions
audits are only as complete as that user's own access. If someone running
an audit stops seeing expected results (e.g. a library they used to see
unique permissions on), check whether their own SharePoint permissions on
that site changed — this isn't a symptom of the flow breaking.

## Troubleshooting

**Streamlit: `AADSTS...` error on "Authenticating..."**
The Azure AD app registration's credentials are wrong, or admin consent
wasn't granted. Re-check tenant ID/client ID/client secret, and in the
app registration's **API permissions**, confirm the SharePoint
`Sites.FullControl.All` (or `Sites.Read.All`) application permission shows
**Granted** (not just "Not granted") — a global or SharePoint admin has to
click **Grant admin consent**.

**Streamlit: `403 Forbidden` from the SharePoint REST API**
Consent was granted but the specific site is outside the scope of a
tenant-wide app permission that's since been restricted — some tenants
scope `Sites.FullControl.All`/`Sites.Selected` to particular sites. Check
whether your tenant uses **Sites.Selected** instead of the full-tenant
permission; if so, the app also needs to be explicitly granted access to
each site (via the Microsoft Graph `sites/{id}/permissions` endpoint or
SharePoint admin center), separately from the app registration's API
permission.

**Streamlit: `429 Too Many Requests` on a large site**
SharePoint is throttling — usually happens on sites with many lists. The
app doesn't currently retry on 429; re-run after a short pause. If this
happens often, it's worth adding retry-with-backoff to `sp_get()` in
`streamlit_app.py`.

**Power Automate: flow succeeds but returns no unique-permission
libraries, though you expect some**
Confirm the running user actually has enough access to see
`HasUniqueRoleAssignments` accurately (site Owner or Full Control) — a
Member/Visitor-level account can under-report broken inheritance.

**Power Automate: "Send an HTTP request to SharePoint" action shows a
validation error after pasting `flow-definition.json`**
Expected — see the caveats in `power-platform/README.md`. Re-open that one
action in the normal designer view, verify site address/method/URI/header
match what's documented, and save; you don't need to rebuild the rest of
the flow.

**Baseline comparison shows everything as "Added" even though nothing
changed**
The uploaded baseline CSV doesn't match the current site's rows — usually
because it was exported from a different site URL, or its `Login name`
column got altered (e.g. opened and re-saved in Excel, which can mangle
claims-encoded login names). Re-download a fresh baseline from the
original run rather than hand-editing snapshot CSVs.

## Decommissioning

If this tool is retired:

- **Streamlit**: delete the deployed app on Streamlit Community Cloud (or
  stop the internal server process), then delete the Azure AD app
  registration's client secret (or the whole registration) in Entra ID.
- **Power Platform**: delete the canvas app and the flow in
  [make.powerapps.com](https://make.powerapps.com)/
  [make.powerautomate.com](https://make.powerautomate.com), and delete or
  archive the `PermissionSnapshots` SharePoint list if the historical data
  isn't needed anymore.
