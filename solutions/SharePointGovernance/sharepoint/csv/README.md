# Governance list CSV templates

One CSV per list on the IT Enterprise Governance site. Headers are the
**internal column names** from `list-schema.json` (G-09), so a CSV lines up
with the list however the display names are set. Fill one row per item.

- People: email address (UPN) of a named, internal user (never a shared or service account, D-03).
- Dates: `yyyy-mm-dd`. Yes/No: `Yes` or `No`.
- Choice columns: use the values below exactly; the flows match on them.
- Group IDs: the Entra object ID (GUID) of the security group, not its name.
- Lookups and Site Register IDs: the item ID of the row in Site Register.

## Which to fill first

1. **Site_Register.csv**: every existing site (migrated sites, the news sites, the governance site). Flows 01, 02 and 06 only see sites listed here. Two news site rows are started: add owners, groups, sensitivity and NextAccessReview. Their URLs use upper case and `/teams/`, which doesn't meet G-08: record an exception in the Decision Log or rename them before launch.
2. **Guest_Access_Register.csv**: any contractor guests who already have access, with an end date no more than 90 days ahead.
3. **File_Share_Register.csv**: remaining file shares, if that work is still open.
4. **Decision_Log.csv**: earlier governance decisions you want on record.

Site Requests, Access Requests and Access Review Log are normally filled by people and flows as work happens; their CSVs are here for completeness and for bulk loads.

## Importing

Easiest: open the list, select **Edit in grid view**, and paste the rows from Excel (columns in the same order). Person and lookup columns may need picking by hand in the grid.
For larger loads use PnP.PowerShell, for example:

```powershell
Import-Csv .\Site_Register.csv | ForEach-Object {
    $v = @{}; $_.PSObject.Properties | Where-Object Value | ForEach-Object { $v[$_.Name] = $_.Value }
    Add-PnPListItem -List 'Site Register' -Values $v
}
```

Delete any empty columns from a row before importing; check Yes/No and dates import as expected on a test row first.

## Site Register (`Site_Register.csv`)

| Column | Display name | Required | Value |
|---|---|---|---|
| Title | Title | Yes | Site name, as shown in SharePoint |
| SiteTitle | Site title | Yes | text |
| SiteUrl | Site URL | Yes | text |
| Department | Department |  | text |
| PrimaryOwner | Primary owner | Yes | email address — Accountable owner. Must be a named, enabled, internal user. |
| SecondaryOwner | Secondary owner | Yes | email address — Must differ from the primary owner. |
| OwnersGroupId | Owners group (Entra object ID) | Yes | text |
| MembersGroupId | Members group (Entra object ID) | Yes | text |
| VisitorsGroupId | Visitors group (Entra object ID) |  | text |
| GuestsGroupId | Guests group (Entra object ID) |  | text — Cloud-only security group for scoped contractor guests. Required before any guest request for this site can be granted. |
| SharingCapability | External sharing | Yes | one of: Disabled | ExistingExternalUserSharingOnly |
| Sensitivity | Sensitivity | Yes | one of: General | Confidential | Highly Confidential |
| Status | Status | Yes | one of: Active | Orphaned - owner inactive | Read-only | Archived |
| LastAccessReview | Last access review |  | yyyy-mm-dd |
| NextAccessReview | Next access review | Yes | yyyy-mm-dd |

## Site Requests (`Site_Requests.csv`)

| Column | Display name | Required | Value |
|---|---|---|---|
| Title | Title | Yes | Site name the requester wants |
| SiteAlias | URL alias | Yes | text — Lower case [org]-[location]-[department]-[site], e.g. hpuk-pof-finance-payroll (PID v4.2 G-08). Flow 03 returns requests that don't follow it. |
| Purpose | Purpose | Yes | text |
| Department | Department | Yes | text |
| Requester | Requester | Yes | email address |
| PrimaryOwner | Primary owner | Yes | email address |
| SecondaryOwner | Secondary owner | Yes | email address |
| OwnersGroupId | Owners group (Entra object ID) | Yes | text |
| MembersGroupId | Members group (Entra object ID) | Yes | text |
| VisitorsGroupId | Visitors group (Entra object ID) |  | text |
| GuestsGroupId | Guests group (Entra object ID) |  | text |
| ExternalSharingRequired | External sharing required |  | Yes or No — Yes routes the request to InfoSec as well as the SharePoint service owner. |
| Sensitivity | Sensitivity | Yes | one of: General | Confidential | Highly Confidential |
| Status | Status | Yes | one of: Submitted | Provisioned | Provisioning failed | Rejected | Returned - Ownership invalid | Returned - Naming standard |
| SiteUrl | Provisioned URL |  | text |
| DecisionLog | Decision log |  | text |

## Access Requests (`Access_Requests.csv`)

| Column | Display name | Required | Value |
|---|---|---|---|
| Title | Title | Yes | Short summary, e.g. "Edit access to Finance Payroll" |
| Requester | Requester | Yes | email address — The person who needs access, or the sponsor for a contractor. |
| UserType | User type / scenario | Yes | one of: Employee - view only | Employee - edit / collaborate | Site Owner / Author | Long-term contractor | Screen / kiosk / display | Privileged admin | Service / shared account — Rows of the Access Method Decision Table. 'Service / shared account' exists so the request is rejected and recorded, not silently dropped. |
| TargetSite | Site | Yes | ID of the Site Register row |
| BusinessJustification | Business justification | Yes | text |
| LineManager | Line manager |  | email address — Required for Site Owner / Author requests. |
| GuestEmail | Guest email |  | text — Long-term contractor only. |
| AccessEndDate | Access end date |  | yyyy-mm-dd — Long-term contractor only. No more than 90 days ahead (PID v4.2, 8.4). |
| Status | Status | Yes | one of: Submitted | Granted | Approved - awaiting AD group change | Approved - PIM eligible assignment pending | Blocked - Licence required | Blocked - Entra ID P2 required | Closed - Use Employee App | Closed - Use published display page | Rejected | Rejected - Not time-bound | Rejected - Prohibited | Rejected - Unknown access type |
| ApprovedAccessMethod | Approved access method |  | text |
| DecisionLog | Decision log |  | text |

## Guest Access Register (`Guest_Access_Register.csv`)

| Column | Display name | Required | Value |
|---|---|---|---|
| Title | Title | Yes | Guest email address |
| GuestUserId | Guest user (Entra object ID) | Yes | text |
| GroupId | Guest group (Entra object ID) | Yes | text |
| SiteId | Site Register ID | Yes | number |
| Sponsor | Sponsor | Yes | email address |
| AccessEndDate | Access end date | Yes | yyyy-mm-dd |
| AccessRequestId | Access request ID |  | number |
| Status | Status | Yes | one of: Active | Removal pending owner decision | Kept - owner decision | Expired - access removed | Revoked |
| ReminderSent | Expiry reminder sent |  | Yes or No |
| RemovedOn | Removed on |  | yyyy-mm-dd |

## Access Review Log (`Access_Review_Log.csv`)

| Column | Display name | Required | Value |
|---|---|---|---|
| Title | Title | Yes | Review name, e.g. "Q4 2026 review - hpuk-pof-finance-payroll" |
| SiteId | Site Register ID |  | number — Empty for privileged-role reviews. |
| Outcome | Outcome | Yes | text — Approve or Reject, as returned by the approval. |
| Reviewer | Reviewer |  | text |
| Comments | Comments |  | text |
| AccessCount | People/groups with access |  | number |

## File Share Register (`File_Share_Register.csv`)

| Column | Display name | Required | Value |
|---|---|---|---|
| Title | Title | Yes | Share path, e.g. \\fileserver\finance |
| ShareOwner | Share owner | Yes | email address |
| SizeGB | Size (GB) |  | number |
| LastModified | Last modified |  | yyyy-mm-dd |
| IntegrationMarker | Integration marker |  | Yes or No |
| GenericAccountPresent | Generic/service account present |  | Yes or No |
| ApplicationBackEnd | Application back-end |  | Yes or No |
| PermissionComplexity | Permission complexity | Yes | one of: Low | Medium | High |
| TargetSiteUrl | Proposed target site |  | text |
| Disposition | Disposition |  | one of: Migrate to SharePoint Online | Excluded - system dependent | Archive | Remediate | Delete | Move to non-SharePoint platform |
| Status | Status | Yes | one of: Registered | Awaiting owner decision | Disposition required | Disposition agreed | Approved - permissions remediation before migration | Ready for migration | Migrated |
| DecisionLog | Decision log |  | text |

## Decision Log (`Decision_Log.csv`)

| Column | Display name | Required | Value |
|---|---|---|---|
| Title | Title | Yes | Decision reference, zero-padded (G-08), e.g. DL001 |
| Category | Category | Yes | one of: InfoPath | File share | Access |
| Decision | Decision | Yes | text |
| DecidedBy | Decided by | Yes | text |
| DecisionDate | Decision date | Yes | yyyy-mm-dd |
| Rationale | Rationale |  | text |
