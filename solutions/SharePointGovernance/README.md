# SharePoint Online governance flows (BAU)

Power Automate flows that keep enforcing the SharePoint Online governance
controls after migration, as part of business-as-usual (BAU) service
operation. The controls come from the **SharePoint Migration PID v3.1**
(April 2026), which remains the policy reference. Project-only controls
(change control against project tolerances, wave gates, RAID escalation)
ended with the migration and are not included.

| # | Flow | Trigger | Governance control it enforces | Source |
|---|------|---------|-------------------------------|--------|
| 01 | [Access request](powerautomate/flows/01-Access-Request.json) | New *Access Requests* item | Access Method Decision Table: service/shared accounts prohibited, view-only via Employee App, licence (F3/E3) and Entra ID P2 checks, time-bound guests, PIM for admins, group-based grants | PID 2.3.1, Appendix |
| 02 | [Guest access expiry](powerautomate/flows/02-Guest-Access-Expiry.json) | Daily 06:00 | Contractor guest access is time-bound and reviewed | PID Appendix |
| 03 | [Site provisioning](powerautomate/flows/03-Site-Provisioning.json) | New *Site Requests* item | New sites follow the agreed governance, with assigned owners and permission groups; external sharing off by default | PID 5.3, 6.5, 7.1 |
| 04 | [InfoPath triage](powerautomate/flows/04-InfoPath-Triage.json) | New *InfoPath Register* item | Remaining InfoPath forms are never moved as-is; each is triaged Replace or Retire | PID 2.3.1 |
| 05 | [File share disposition](powerautomate/flows/05-FileShare-Disposition.json) | New *File Share Register* item | Remaining file shares move to SharePoint case by case only; integration/system-dependent shares excluded | PID 2.3.1 |
| 06 | [Access recertification](powerautomate/flows/06-Access-Recertification.json) | Monthly, 1st, 07:00 | 90-day review of site access, orphaned-site detection, quarterly review of privileged admin roles | PID 6.5 |

Process diagrams for every flow are in
[`diagrams/governance-flows.md`](diagrams/governance-flows.md) (rendered by
GitHub).

## Layout

```
SharePointGovernance/
├── powerautomate/flows/   flow definitions (Workflow Definition Language JSON)
├── sharepoint/            list-schema.json: the 8 governance lists the flows use
├── runbooks/              Set-SiteGovernanceBaseline.ps1 (Azure Automation, called by flow 03)
├── diagrams/              Mermaid process diagrams
└── tools/                 validate_flows.py: static checks run in CI
```

## Roles

The flows address roles through parameters, not names, so a change of staff
only changes an environment variable.

| Parameter | Role | What it receives |
|-----------|------|------------------|
| `SharePointServiceOwnerEmail` | SharePoint service owner | Approves new sites and file share migrations; second approver for Site Owner / Author access; receives provisioning failures, InfoPath triage outcomes and disputes, and orphaned-site alerts |
| `InfoSecApproverEmail` | Security & Architecture (InfoSec) | Approves guest access, privileged admin roles, and sites with external sharing or Highly Confidential content; quarterly admin-role review |
| `ITOpsOwnerEmail` | IT Operations owner | Creates PIM assignments; agrees dispositions for excluded file shares and permission remediation; orphaned-site alerts |
| `ServiceDeskEmail` | Service Desk shared mailbox | Fulfilment tickets: AD group changes and access removals |

The SharePoint service owner role is new for BAU, so set it to whoever IT
names as service owner. A shared mailbox or distribution list is better than
one person's address: approvals still reach someone during absences.

## Deploying

1. **Lists**: create a governance site (for example `/sites/SPOGovernance`)
   and create the lists in `sharepoint/list-schema.json` with PnP.PowerShell.
   Bulk-load *Site Register* with every existing site (owners, security
   groups, and a `NextAccessReview` date spread over the next 90 days so
   reviews don't all land in one month). Load only the InfoPath forms and
   file shares still outstanding after migration into *InfoPath Register* and
   *File Share Register*. Each loaded item triggers flow 04 or 05, so load in
   batches the owners can handle.
2. **Connections**: create connection references for SharePoint, Office 365
   Outlook, Approvals, **HTTP with Microsoft Entra ID** (resource
   `https://graph.microsoft.com`) and Azure Automation, each owned by a
   service principal or a dedicated licensed flow-owner account. This is
   the one place a non-personal identity is used, and it never gets
   SharePoint content access.
3. **Graph permissions** for the HTTP with Entra ID connection:
   `User.Read.All`, `GroupMember.ReadWrite.All`, `User.Invite.All`,
   `RoleManagement.Read.Directory`.
4. **Runbook**: import `runbooks/Set-SiteGovernanceBaseline.ps1` into the
   Automation account with PnP.PowerShell 2.x on the PowerShell 7.2 runtime.
   Add the variables `PnPClientId`, `TenantName`, `TenantId` and the
   certificate `PnPAppCertificate` for the PnP Enterprise App (DEP005). The
   app needs `Sites.FullControl.All` (SharePoint) and
   `InformationProtectionPolicy.Read.All` (Graph).
5. **Import the flows** into a solution and set the environment variables
   (`GovernanceSiteUrl`, `TenantRootUrl`, the role mailboxes above, and the
   Automation account IDs).
6. Turn the flows on in this order: 03 and 06 (sites), then 01 and 02
   (access), then 04 and 05.
7. **Ownership**: hand the flows and their connections to the SharePoint
   service owner's team in the BAU support model (runbook / KB), so they
   don't depend on a project account.

## Behaviour worth knowing

- **Synced AD groups**: permissions use the federated AD security groups
  (DEP003). These are mastered on-premises and cannot be changed from the
  cloud, so for synced groups flow 01 raises a Service Desk ticket
  instead of changing membership, and flow 06 sends all access removals to
  the Service Desk. Cloud-only groups (including each site's
  Guests group) are changed directly through Graph.
- **Licence checks** read the user's licence service plans through Graph. Any
  plan whose name contains `SHAREPOINT` counts (SHAREPOINTDESKLESS for F3,
  SHAREPOINTENTERPRISE for E3/E5). Entra ID P2 is detected by
  `AAD_PREMIUM_P2`. If the user can't be found, the request is blocked rather
  than failing the flow.
- **Site creation** checks `SPSiteManager` reports the site as ready before
  applying the baseline. The runbook throws if the requested sensitivity label
  isn't published. Check the Automation job output if a site shows
  *Provisioned* but the label is missing.
- **Choice values** the flows write are checked against the list schema by
  `tools/validate_flows.py`, so a renamed status fails CI rather than failing
  silently at run time.

## Validating changes

```
python solutions/SharePointGovernance/tools/validate_flows.py
```

This checks for duplicate action names, `runAfter`/`body()`/`outputs()`
references to missing actions, undeclared parameters and variables, list
columns missing from `list-schema.json`, and choice values that aren't
defined. It runs in CI on every change under this folder.
