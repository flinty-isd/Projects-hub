# SharePoint Permissions Audit — Power Platform version

A Microsoft-native alternative to the Streamlit app (`streamlit_app.py`) in
this repo, built entirely from **Power Automate** + **Power Apps**. No
Python, no separate hosting, no Azure AD app registration/client secret —
it uses the signed-in user's own SharePoint access, and runs natively in
the **Power Apps mobile app** on iOS/Android.

This isn't a file this repo can run — Power Apps/Power Automate resources
live in your Power Platform environment, not in git. Follow these steps in
[make.powerautomate.com](https://make.powerautomate.com) and
[make.powerapps.com](https://make.powerapps.com) to build it.

## Prerequisites

- A Power Apps/Power Automate license available in your Microsoft 365 tenant
  (the standard SharePoint connector is included in most Microsoft 365 plans).
- Your own account needs **Full Control** (or "Manage Permissions") on any
  site you want to audit — the flow runs as you, not as an app-only service
  account.

## 1. Storage: a SharePoint list for snapshots

Create a SharePoint list called **PermissionSnapshots** (in any site you
control, e.g. a team site) with these columns:

| Column | Type |
|---|---|
| Title | Single line of text (used as a snapshot label) |
| SiteUrl | Single line of text |
| Scope | Single line of text (e.g. `Site: Marketing` or `Library: Contracts`) |
| Principal | Single line of text |
| LoginName | Single line of text |
| Roles | Single line of text |
| SnapshotDate | Date and time |

This list holds every "as is" snapshot you save, so comparisons work across
any two points in time.

## 2. Power Automate flow: `Get SharePoint Permissions`

Create an **Instant cloud flow**, trigger: **Power Apps (V2)**.

Add one text input parameter: `SiteUrl`.

Steps:

1. **Initialize variable** `AllPermissions` — Array, value `[]`
2. **Send an HTTP request to SharePoint**
   - Site Address: `Enter custom value` → `@{triggerBody()['text']}` (the `SiteUrl` input)
   - Method: `GET`
   - Uri: `_api/web?$select=Title,HasUniqueRoleAssignments`
   - Headers: `Accept: application/json;odata=nometadata`
3. **Parse JSON** on the body of step 2, with a schema generated from a sample response (use "Generate from sample" and paste a real response, or use `{"Title":"","HasUniqueRoleAssignments":false}`)
4. **Send an HTTP request to SharePoint** (site-level role assignments)
   - Site Address: same as step 2
   - Uri: `_api/web/roleassignments?$expand=Member,RoleDefinitionBindings`
5. **Parse JSON** on step 4's body (schema from sample — it's the standard SharePoint REST `roleassignments` shape)
6. **Apply to each** over the parsed `value` array from step 5:
   - **Append to array variable** `AllPermissions`:
     ```
     {
       "Scope": concat("Site: ", body('Parse_JSON_Web')?['Title']),
       "Principal": items('Apply_to_each')?['Member']?['Title'],
       "LoginName": items('Apply_to_each')?['Member']?['LoginName'],
       "Roles": join(select(items('Apply_to_each')?['RoleDefinitionBindings'], 'Name'), ', ')
     }
     ```
7. **Send an HTTP request to SharePoint** (list the lists)
   - Uri: `_api/web/lists?$select=Title,Id,HasUniqueRoleAssignments,Hidden`
8. **Parse JSON** on step 7's body
9. **Filter array**: From step 8's `value`, condition `HasUniqueRoleAssignments is equal to true` AND `Hidden is equal to false`
10. **Apply to each** over the filtered array from step 9:
    1. **Send an HTTP request to SharePoint**
       - Uri: `_api/web/lists(guid'@{items('Apply_to_each_2')?['Id']}')/roleassignments?$expand=Member,RoleDefinitionBindings`
    2. **Parse JSON** on that body
    3. **Apply to each** over its `value`, **Append to array variable** `AllPermissions`:
       ```
       {
         "Scope": concat("Library: ", items('Apply_to_each_2')?['Title']),
         "Principal": items('Apply_to_each_3')?['Member']?['Title'],
         "LoginName": items('Apply_to_each_3')?['Member']?['LoginName'],
         "Roles": join(select(items('Apply_to_each_3')?['RoleDefinitionBindings'], 'Name'), ', ')
       }
       ```
11. **Respond to a Power App or flow**: return `AllPermissions` (Array output named `permissions`)

> Premium alternative: if you'd rather match the Python version's app-only
> auth (a service account/app registration instead of your own delegated
> permissions), swap the "Send an HTTP request to SharePoint" actions for
> the premium **HTTP with Azure AD** connector, pointed at
> `https://{tenant}.sharepoint.com` using the same app registration
> described in the main README. This needs Premium/per-flow licensing.

## 3. Power Apps canvas app: `SharePoint Permissions Audit`

Create a **blank canvas app** (tablet layout works best, but it runs fine
on phone too). Add the `PermissionSnapshots` SharePoint list and the
`Get SharePoint Permissions` flow as data sources.

### HomeScreen

- `txtSiteUrl` (Text input) — placeholder "Site URL"
- `btnFetch` (Button) — `OnSelect`:
  ```
  Set(
      varCurrent,
      'Get SharePoint Permissions'.Run(txtSiteUrl.Text)
  );
  ClearCollect(colCurrent, varCurrent.permissions);
  Navigate(ResultsScreen)
  ```

### ResultsScreen

- `galSite` (Gallery) — `Items: Filter(colCurrent, StartsWith(Scope, "Site:"))`
- `galLibraries` (Gallery) — `Items: Filter(colCurrent, StartsWith(Scope, "Library:"))`
- `txtSnapshotLabel` (Text input) — label for this snapshot (e.g. "Q3 audit")
- `btnSaveBaseline` (Button) — `OnSelect`:
  ```
  ForAll(
      colCurrent,
      Patch(
          PermissionSnapshots,
          Defaults(PermissionSnapshots),
          {
              Title: txtSnapshotLabel.Text,
              SiteUrl: txtSiteUrl.Text,
              Scope: Scope,
              Principal: Principal,
              LoginName: LoginName,
              Roles: Roles,
              SnapshotDate: Now()
          }
      )
  )
  ```
- `ddBaseline` (Dropdown) — `Items: Distinct(Filter(PermissionSnapshots, SiteUrl = txtSiteUrl.Text), Title)`
- `btnCompare` (Button) — `OnSelect`:
  ```
  ClearCollect(
      colBaseline,
      Filter(PermissionSnapshots, Title = ddBaseline.Selected.Value, SiteUrl = txtSiteUrl.Text)
  );
  ClearCollect(
      colAdded,
      Filter(
          colCurrent,
          IsBlank(LookUp(colBaseline, Scope = ThisRecord.Scope && LoginName = ThisRecord.LoginName))
      )
  );
  ClearCollect(
      colRemoved,
      Filter(
          colBaseline,
          IsBlank(LookUp(colCurrent, Scope = ThisRecord.Scope && LoginName = ThisRecord.LoginName))
      )
  );
  ClearCollect(
      colChanged,
      AddColumns(
          Filter(
              colCurrent,
              !IsBlank(LookUp(colBaseline, Scope = ThisRecord.Scope && LoginName = ThisRecord.LoginName)) &&
              LookUp(colBaseline, Scope = ThisRecord.Scope && LoginName = ThisRecord.LoginName).Roles <> ThisRecord.Roles
          ),
          "BaselineRoles",
          LookUp(colBaseline, Scope = ThisRecord.Scope && LoginName = ThisRecord.LoginName).Roles
      )
  );
  Navigate(ComparisonScreen)
  ```

### ComparisonScreen ("as is" vs "as now")

- `galAdded` (Gallery, green accent) — `Items: colAdded`
- `galRemoved` (Gallery, red accent) — `Items: colRemoved`
- `galChanged` (Gallery, amber accent) — `Items: colChanged`, showing `Principal`, `BaselineRoles → Roles`

## 4. Using it on iOS

Publish the app, then open the **Power Apps** mobile app (App Store) on
your iPhone/iPad, sign in with your work account, and the app appears in
your list — no separate URL or hosting to manage, and it inherits your
organization's existing conditional access/MFA policies automatically.

## Trade-offs vs. the Streamlit version

| | Streamlit (`streamlit_app.py`) | Power Platform (this doc) |
|---|---|---|
| Auth | App-only (client secret) | Delegated (your own SharePoint access) by default |
| Hosting | Needs a host (Streamlit Cloud / server) | Runs in Microsoft 365 tenant, no separate hosting |
| iOS access | Any browser | Native Power Apps mobile app |
| Licensing | Free (Streamlit Cloud) | Requires Power Apps/Automate entitlement (usually included, but check premium connector needs) |
| Editing | Code, version-controlled here | Built/edited in Power Apps/Automate Studio (can be exported as a solution for source control separately) |
