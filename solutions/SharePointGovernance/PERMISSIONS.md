# Permission and action matrix (draft for review R12)

**Status: draft.** This is what the governance (1.8.0.0) and news (1.5.0.0)
solutions need, taken from the flows and scripts in this repository. InfoSec,
IAM and the SharePoint tenant owner must review it, approve or replace the
tenant-level rights marked **Exception**, and keep the evidence listed under
*Proving it* before production (gate: before production activation).

## 1. Identities

| Identity | Kind | Used by | Rights | Scope | Status |
|---|---|---|---|---|---|
| Governance flow owner (named IT Operations person) and backup | Named user (D-03) | Flows 01–08 connections | See §2 | Governance site; Graph delegated | To name |
| News flow owner (named) and backup | Named user | C1, C2, C3a, C3b connections | Edit on Site Pages (both news sites) and Delivery Log; Read on Comms Distribution; Send As on the Communications mailbox; member of each port Teams channel | Two news sites | To name |
| Azure Automation managed identity | Managed identity (the only sanctioned non-named identity, G-01) | Baseline runbook (flow 03) | Sites.Selected, granted per new site URL by IT Ops (G-04) | One grant per site, in the grant register | **Exception**: the guide also gives it **SharePoint Administrator** for the tenant-level step (secondary admin, sharing). Needs InfoSec approval or a narrower route |
| Provisioning admin (person running Provision-NewsSites.ps1) | Named admin, at run time | News provisioning | Site collection admin on both news sites, via an Entra app with Sites.FullControl.All and TermStore.ReadWrite.All (delegated with `-Interactive`, or app-only) | Two news sites | **Exception** if app-only: tenant-wide Sites.FullControl.All. Prefer `-Interactive` with delegated rights |
| Purview compliance admin | Named admin, at run time | Set-NewsRetention.ps1 | Compliance Administrator (retention policies) | Two news sites | Role holder to confirm |
| Deployment app registration | Service principal | Proposed managed pipeline only (not built) | System Customizer in each Power Platform environment; no SharePoint access | Power Platform | Proposal; InfoSec to confirm outside D-03 |

## 2. Governance flow owner: what each flow does with which right

The HTTP with Microsoft Entra ID connection uses **delegated** Graph
permissions: a call succeeds only if the flow owner could do it themselves.

| Flow | Action | API / connector | Permission | Writes? |
|---|---|---|---|---|
| 01 | Read requester's account state and licences | Graph `users/{id}`, `licenseDetails` | User.Read.All | No |
| 01 | Add a member or owner to the site's Members/Owners group (cloud groups only) | Graph `groups/{id}/members/$ref` | GroupMember.ReadWrite.All | **Yes** |
| 01 | Invite a guest; add to the site's Guests group | Graph `invitations`, `groups/{id}/members/$ref` | User.Invite.All, GroupMember.ReadWrite.All | **Yes** |
| 02 | Remove an expired guest from the Guests group (after owner Approve, or automatically only if GuestAutoRemoval = Yes) | Graph `groups/{id}/members/{id}/$ref` DELETE | GroupMember.ReadWrite.All | **Yes** |
| 03 | Check both owners' accounts | Graph `users/{id}` | User.Read.All | No |
| 03 | Create the site | SharePoint `SPSiteManager/create` | Site creation (SAM restricted site creation allows the flow owner) | **Yes** |
| 03 | Start the baseline runbook | Azure Automation | Automation Job Operator on the governance account | **Yes** (via the managed identity) |
| 06 | Read SharePoint Administrator assignments and eligibility | Graph `roleManagement/directory/role*ScheduleInstances` | RoleManagement.Read.Directory | No |
| 01–08 | Read and write governance lists; send emails; approvals | SharePoint, Outlook, Approvals | Edit on the governance lists; own mailbox | **Yes** (lists, email) |

## 3. What a requester can influence

| Input | Who sets it | Used for | Control |
|---|---|---|---|
| Target site (Access Requests) | Requester picks a Site Register row | Group IDs come from the **Site Register**, not the request | Site Register edit rights: service owner team only (check it is not editable by requesters) |
| OwnersGroupId, MembersGroupId, VisitorsGroupId, GuestsGroupId (Site Requests) | **Requester** | The runbook binds these groups to the new site | **Gap:** a requester could enter an unrelated group's ID. Proposed: flow 03 reads each group's name and type from Graph and shows them in the service owner's approval; the runbook refuses groups that aren't security groups or are on-premises synced where not expected |
| GuestEmail, AccessEndDate (Access Requests) | Requester | Guest invitation, 90-day limit | InfoSec approval; end date ≤ 90 days enforced by flow 01 |
| Comms Distribution rows (news) | Configuration maintainers only | Where news is sent | List restricted by Provision-NewsSites.ps1; the flow identity can only read it |

## 4. Site and content boundaries

| Boundary | Intended | How it's set | Checked by |
|---|---|---|---|
| New governed sites | Owners/Members/Visitors are the requested security groups; guests read-only via the Guests group in Visitors; sharing as approved; custom script off; label applied | Baseline runbook with read-back (Partial = failure) | T01, T04b–d |
| News sites | Readers: scoped HPUK reader group in Visitors (never Everyone except external users); publishers in Members | Provision-NewsSites.ps1 | The script now reports broad claims and individual grants as drift (it does not remove them) |
| Restricted news lists | Notices Archive: maintainers edit, readers read. Comms Distribution: maintainers edit, flow owner reads. Delivery Log: maintainers and flow owner edit | Provision-NewsSites.ps1 (`-RepairPermissions` to re-apply) | Script check on every run |
| Expired news posts | Drafts visible only to editors | Site Pages versioning (major and minor, draft security) | News README Testing: Expiry |
| Videos and attachments | Inherit the site's permissions; audience targeting is **not** a permission | Site permissions | Reader boundary test (below) |

## 5. Proving it (closure evidence for R12)

- Export the Graph consent for the HTTP with Entra ID connection, and the managed identity's role assignments and Sites.Selected grants, and file them with the grant register.
- Run T01 and keep the runbook's read-back: groups, sharing, label, and the Guests group in Visitors.
- Effective-access check on each news site: Provision-NewsSites.ps1 reports no drift; an account outside the HPUK reader group (a tenant peer) can't open a page, an attachment in Notices and Attachments, or a video in News Videos by direct link.
- On a test Site Request, enter an unrelated group's ID: the approval must make that visible to the service owner (after the proposed change), and the service owner rejects it.
- InfoSec signs off the two **Exception** rows (SharePoint Administrator for the managed identity; Sites.FullControl.All if provisioning runs app-only), or names the narrower route.
