# Permission and action matrix (draft for review R12)

**Status: draft.** This is what the governance (1.9.0.0) and news (1.7.0.0)
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
| OwnersGroupId, MembersGroupId, VisitorsGroupId, GuestsGroupId (Site Requests) | **Requester** | The runbook binds these groups to the new site | From 1.9.0.0 flow 03 looks each group up in Graph before any approval: a group that doesn't exist, isn't a security group, is a Microsoft 365 group, or (for Guests) is synced from AD returns the request. The approval shows each group's name and type, so the service owner can see an unrelated group. A real but unrelated security group still depends on the service owner noticing it (T03b): **residual risk, accepted** (§6) |
| GuestEmail, AccessEndDate (Access Requests) | Requester | Guest invitation, 90-day limit | InfoSec approval; end date ≤ 90 days enforced by flow 01 |
| Comms Distribution rows (news) | Configuration maintainers only | Where news is sent | List restricted by Provision-NewsSites.ps1; the flow identity can only read it |

## 4. Site and content boundaries

| Boundary | Intended | How it's set | Checked by |
|---|---|---|---|
| New governed sites | Owners/Members/Visitors are the requested security groups; guests read-only via the Guests group in Visitors; sharing as approved; custom script off; label applied | Baseline runbook with read-back (Partial = failure): label present and correct, secondary admin, groups, no individual users | T01, T03b, T04b–d |
| News sites | Readers: scoped HPUK reader group in Visitors (never Everyone except external users); publishers in Members | Provision-NewsSites.ps1 | The script now reports broad claims and individual grants as drift (it does not remove them) |
| Restricted news lists | Notices Archive: maintainers edit, readers read. Comms Distribution: maintainers edit, flow owner reads. Delivery Log: maintainers and flow owner edit | Provision-NewsSites.ps1 (`-RepairPermissions` to re-apply) | Script check on every run |
| Expired news posts | Drafts visible only to editors | Site Pages versioning (major and minor, draft security) | News README Testing: Expiry |
| Videos and attachments | Inherit the site's permissions; audience targeting is **not** a permission | Site permissions | Reader boundary test (below) |

## 5. Proving it (closure evidence for R12)

- Export the Graph consent for the HTTP with Entra ID connection, and the managed identity's role assignments and Sites.Selected grants, and file them with the grant register.
- Run T01 and keep the runbook's read-back: groups, sharing, label, and the Guests group in Visitors.
- Effective-access check on each news site: Provision-NewsSites.ps1 reports no drift; an account outside the HPUK reader group (a tenant peer) can't open a page, an attachment in Notices and Attachments, or a video in News Videos by direct link.
- On a test Site Request, enter an unrelated but real security group's ID (T03b): the approval shows that group's name and type, and the service owner rejects it.
- InfoSec signs off the two **Exception** rows (SharePoint Administrator for the managed identity; Sites.FullControl.All if provisioning runs app-only), or names the narrower route.

## 6. Residual risk: an unrelated security group on a Site Request

Flow 03 proves each requested group exists and is a security group of the
right kind, and shows its name and type in the approval. It can't prove the
group *belongs* to the site being requested: a requester could name a real
security group that serves something else, and only the service owner (and
InfoSec for Highly Confidential or shared sites) would notice. The project
chose (23 November 2026) to accept this rather than add a naming standard or
group-ownership check, subject to InfoSec's agreement below.

**What the approver checks:** every group named in the approval is the one
for this site's team (its name matches the site or department and its
purpose); none is a broad or privileged group (all-staff, department-wide,
admin or service groups); none is already used by another site in the Site
Register unless that sharing is intended. If in doubt, reject and ask the
requester.

**Decision Log entry (draft for InfoSec and the Control Board)**

| Field | Value |
|---|---|
| Title | DL-GOV-R12a |
| Category | Access |
| Decision | Accept that flow 03 relies on the service owner's approval (and InfoSec's where required) to spot a real but unrelated security group on a Site Request. No automatic naming or ownership check is added |
| Options considered | A: group names must start with the site alias, and groups already bound to another site are refused. B: a site owner must be an Entra owner of each cloud group, plus the reuse check. C: reuse check and an InfoSec deny list only. D: accept the residual risk (chosen) |
| Compensating controls | Flow 03 refuses missing, non-security, Microsoft 365 and (for Guests) AD-synced groups; the approval lists each group's name and type; T03b proves it; the runbook reads back the bound groups; SAM site access reviews and attestation (S1, S4) put group membership in front of owners every quarter; flow 07 lists site issues monthly |
| Risk | Low to Medium (InfoSec to confirm) |
| Accepted by | InfoSec (Ian Lowe); recorded for the Control Board |
| Review | At the first quarterly SAM attestation after go-live, or sooner if a wrong group is found on any site |
| Decision date | *(InfoSec date)* |
