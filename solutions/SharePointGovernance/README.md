# SharePoint Online governance flows

Power Automate flows that enforce the governance controls in the
**SharePoint Migration PID v3.1** (April 2026) and the **SharePoint Site
Migration Planner**, both in the *SharePoint migration* Drive folder.

| # | Flow | Trigger | Governance control it enforces | Source |
|---|------|---------|-------------------------------|--------|
| 01 | [Access request](powerautomate/flows/01-Access-Request.json) | New *Access Requests* item | Access Method Decision Table: service/shared accounts prohibited, view-only via Employee App, licence (F3/E3) and Entra ID P2 checks, time-bound guests, PIM for admins, group-based grants | PID 2.3.1, Appendix |
| 02 | [Guest access expiry](powerautomate/flows/02-Guest-Access-Expiry.json) | Daily 06:00 | Contractor guest access is time-bound and reviewed | PID Appendix |
| 03 | [Site provisioning](powerautomate/flows/03-Site-Provisioning.json) | New *Site Requests* item | Sites created to agreed governance with assigned owners and permission groups; external sharing off by default | PID 2.2, 5.3, 6.5, 7.1 |
| 04 | [InfoPath triage](powerautomate/flows/04-InfoPath-Triage.json) | New *InfoPath Register* item | InfoPath is never migrated as-is; each form is triaged Replace or Retire | PID 2.3.1 |
| 05 | [File share disposition](powerautomate/flows/05-FileShare-Disposition.json) | New *File Share Register* item | Selective, case-by-case file share migration; integration/system-dependent shares excluded | PID 2.3.1 |
| 06 | [Change control](powerautomate/flows/06-Change-Control.json) | New *Change Log* item | Change Authority by tolerance (time ±5 days, cost ±£5,000, scope) | PID 5.5, 8.1 |
| 07 | [Wave readiness & sign-off](powerautomate/flows/07-Wave-Readiness-and-Signoff.json) | *Wave Plan* Gate Status changed | Wave readiness checklist, blockout window, end-of-wave sign-off with ShareGate evidence, handover to BAU | PID 5.2, 5.7, 10 |
| 08 | [Access recertification](powerautomate/flows/08-Access-Recertification.json) | Monthly, 1st, 07:00 | Periodic review of site owners and privileged groups; orphaned-site detection | PID 6.5 |
| 09 | [RAID escalation](powerautomate/flows/09-RAID-Weekly-Escalation.json) | Weekly, Monday 07:00 | Weekly RAID review; escalation where tolerance is forecast to be exceeded | PID 5.4 |

Process diagrams for every flow are in
[`diagrams/governance-flows.md`](diagrams/governance-flows.md) (rendered by
GitHub).

## Layout

```
SharePointGovernance/
├── powerautomate/flows/   flow definitions (Workflow Definition Language JSON)
├── sharepoint/            list-schema.json: the 11 governance lists the flows use
├── runbooks/              Set-SiteGovernanceBaseline.ps1 (Azure Automation, called by flow 03)
├── diagrams/              Mermaid process diagrams
└── tools/                 validate_flows.py: static checks run in CI
```

## Roles

The flows address roles through parameters, not names, so changes of staff
only change the environment variables. The current holders, from the PID:

| Parameter | Role | Holder (PID v3.1) |
|-----------|------|-------------------|
| `ProjectManagerEmail` | IT Project Manager, day-to-day Change Authority | David Flint |
| `InfoSecApproverEmail` | Security & Architecture (InfoSec) | Ian Lowe |
| `SponsorEmail` | Project Sponsor | Ian Lowe |
| `PortfolioManagerEmail` | IT Project Portfolio Manager | Pete Simmons |
| `ITOpsOwnerEmail` | IT Operations, post-migration support owner | Carl Sharman |
| `BusinessAnalystEmail` | Internal Knowledge Expert / BA | Nigel Bell |
| `ServiceDeskEmail` | Service Desk shared mailbox (receives fulfilment tickets) | — |

The Sponsor and InfoSec roles are currently the same person. For changes that
exceed tolerance, flow 06 still asks for both Sponsor and Portfolio approval,
so two people always decide.

## Deploying

1. **Lists**: create a governance site (for example `/sites/SPOGovernance`)
   and create the lists in `sharepoint/list-schema.json` with PnP.PowerShell.
   Bulk-load *Site Register*, *InfoPath Register*, *File Share Register*,
   *Wave Plan* and *RAID Log* from the Migration Planner and the
   InfoPath / file share assessments. That loading is what triggers flows 04
   and 05 for each existing item, so stage it.
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
   (`GovernanceSiteUrl`, `TenantRootUrl`, the role mailboxes above, the
   Automation account IDs, and for flow 07 `BlockoutStart` / `BlockoutEnd`).
6. Turn the flows on in this order: 03 and 08 (sites), then 01 and 02
   (access), then 04–07 and 09.

## Behaviour worth knowing

- **Synced AD groups**: permissions use the federated AD security groups
  (DEP003). These are mastered on-premises and cannot be changed from the
  cloud, so for synced groups flows 01 and 08 raise a Service Desk ticket
  instead of changing membership. Cloud-only groups (including each site's
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
