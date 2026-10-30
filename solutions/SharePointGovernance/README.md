# SharePoint Online governance flows (BAU)

Power Automate flows that keep enforcing the SharePoint Online governance
controls after migration, as part of business-as-usual (BAU) service
operation. The controls come from the **SharePoint Migration PID**, now
**v4.2** (16/09/2026), which is the policy reference. Project-only controls
(change control against project tolerances, wave gates, RAID escalation)
ended with the migration and are not included.

| # | Flow | Trigger | Governance control it enforces | Source |
|---|------|---------|-------------------------------|--------|
| 01 | [Access request](powerautomate/flows/01-Access-Request.json) | New *Access Requests* item | Access Method Decision Table: service/shared accounts prohibited (D-03), staff without a licence to the Base8 CMS in the Employee App, licence (F3/E3) and Entra ID P2 checks, guests time-bound to 90 days, PIM for admins, group-based grants | PID v4.2 2.3.1, 8.4, Appendix A |
| 02 | [Guest access expiry](powerautomate/flows/02-Guest-Access-Expiry.json) | Daily 06:00 | Contractor guest access is time-bound and reviewed; removal decided by the site owner unless the Board makes it automatic (G-11) | PID v4.2 8.4, G-11 |
| 03 | [Site provisioning](powerautomate/flows/03-Site-Provisioning.json) | New *Site Requests* item | Naming standard (G-08), two named owners, permission groups, external sharing off by default; per-site Sites.Selected grant (G-04) before the baseline runbook | PID v4.2 5.3, 6.4, 8.4 |
| 05 | [File share disposition](powerautomate/flows/05-FileShare-Disposition.json) | New *File Share Register* item | Remaining file shares move to SharePoint case by case only; integration/system-dependent shares excluded | PID v4.2 2.3.1 |
| 06 | [Access recertification](powerautomate/flows/06-Access-Recertification.json) | Monthly, 1st, 07:00 | 90-day review of site access, orphaned-site detection, quarterly review of privileged admin roles | PID v4.2 8.4 |

**Flow 04 (InfoPath triage) was retired on 25 October 2026.** Microsoft
removed InfoPath Forms Services on 14/07/2026, and PID v4.2 triages forms
with the Criticality Decision Tree (Category A/B) through the programme's
Flow 8. If flow 04 was imported earlier, delete it from the environment by
hand: an unmanaged upgrade doesn't remove it.

**Overlap with the programme's automation.** PID v4.2 §7 also has Flow 7 +
RB-3 (site provisioning) and Flows 27–33 (attestation, privileged access,
guest checks). Flows 03 and 06 overlap them; the Control Board decides which
owns each control (D-GSA-02, D-GSA-05, D-GSA-08).

Process diagrams for every flow are in
[`diagrams/governance-flows.md`](diagrams/governance-flows.md) (rendered by
GitHub).

## Layout

```
SharePointGovernance/
├── powerautomate/flows/   flow definitions (Workflow Definition Language JSON)
├── sharepoint/            list-schema.json: the 7 governance lists; csv/ holds import templates
├── runbooks/              Set-SiteGovernanceBaseline.ps1 (Azure Automation, called by flow 03)
├── diagrams/              Mermaid process diagrams
├── branding/              theme, Status column formatting, site pages: browser script or Copilot prompts
├── solution-config.json   solution name, version, publisher, environment variables
└── tools/                 validate_flows.py (static checks), build_solution.py (packager),
                           build_formatters.py + build_site_kit.py (branding generators)
```

## Roles

The flows address roles through parameters, not names, so a change of staff
only changes an environment variable.

| Parameter | Role | What it receives |
|-----------|------|------------------|
| `SharePointServiceOwnerEmail` | SharePoint service owner | Approves new sites and file share migrations; second approver for Site Owner / Author access; receives provisioning failures and orphaned-site alerts |
| `InfoSecApproverEmail` | Security & Architecture (InfoSec) | Approves guest access, privileged admin roles, and sites with external sharing or Highly Confidential content; quarterly admin-role review |
| `ITOpsOwnerEmail` | IT Operations owner | Applies and registers the Sites.Selected grant for each new site (flow 03); creates PIM assignments; agrees dispositions for excluded file shares and permission remediation; orphaned-site alerts |
| `ServiceDeskEmail` | Service Desk shared mailbox | Fulfilment tickets: AD group changes and access removals |

The SharePoint service owner role is new for BAU, so set it to whoever IT
names as service owner. A shared mailbox or distribution list is better than
one person's address: approvals still reach someone during absences.

## Deploying

1. **Lists**: create the lists in `sharepoint/list-schema.json` on the
   **IT Enterprise Governance** site, where PID v4.2 holds the governance and
   security lists (D-GSA-07, Option A). Use PnP.PowerShell.
   Bulk-load *Site Register* (templates and column guide in
   [`sharepoint/csv/`](sharepoint/csv/README.md)) with every existing site (owners, security
   groups, and a `NextAccessReview` date spread over the next 90 days so
   reviews don't all land in one month). Load only the file shares still
   outstanding after migration into *File Share Register*. Each loaded item
   triggers flow 05, so load in batches the owners can handle.
2. **Connections**: in the target environment create a connection for
   SharePoint, Office 365 Outlook, Approvals, **HTTP with Microsoft Entra
   ID** (base resource and Azure AD resource URI both
   `https://graph.microsoft.com`) and Azure Automation, each signed in as the
   **named governance flow owner** (see the
   [deployment plan](../POWER-PLATFORM-DEPLOYMENT.md#identities)). No
   service or shared account (D-03).
3. **Graph permissions** for the HTTP with Entra ID connection:
   `User.Read.All`, `GroupMember.ReadWrite.All`, `User.Invite.All`,
   `RoleManagement.Read.Directory`.
4. **Runbook**: import `runbooks/Set-SiteGovernanceBaseline.ps1` into the
   Automation account with PnP.PowerShell 2.x on the PowerShell 7.2 runtime,
   and add the variable `TenantName`. It signs in with the account's
   **system-assigned managed identity** (DEP005 closed on this basis). Give
   the identity the SharePoint Administrator role for the tenant-level step,
   as for the RCD runbook (G-03, DEP007). Site access comes from a
   **Sites.Selected** grant per site URL: flow 03 asks IT Operations to apply
   and register it for each new site before the runbook runs (G-04).
5. **Import the solution** (see [Importing](#importing) below), then set
   the environment variables in the solution.
6. Turn the flows on in this order: 03 and 06 (sites), then 01 and 02
   (access), then 05.
7. **Ownership**: hand the flows and their connections to the SharePoint
   service owner's team in the BAU support model (runbook / KB), so they
   don't depend on a project account.

## Importing

The flows are imported as one unmanaged Power Platform solution.

**Get the package.** Either download it from GitHub (Actions → *Governance
flows* → latest run on `main` → artifact *SharePointGovernance-solution*), or
build it locally:

```
python solutions/SharePointGovernance/tools/build_solution.py
```

This writes `solutions/SharePointGovernance/dist/SharePointGovernance_<version>.zip`.

**Import it.**

1. Go to [make.powerautomate.com](https://make.powerautomate.com) and pick
   the BAU environment (top right). Use a dev or test environment first.
2. **Solutions → Import solution → Browse**, choose the .zip, **Next**.
3. **Connections**: for each of the five connection references, pick the
   connection you created in step 2 of Deploying.
4. **Environment variables**: none is mandatory at import, so you can leave
   the boxes on this screen empty. After the import, open the solution →
   **Environment variables**, where each is listed by its title, and set the
   **Current value** of every variable whose description starts "Set after
   import". These are the governance
   site URL, the tenant root URL, the four role mailboxes, the three
   Automation account values, the review interval (90 days by default), the
   site naming codes (`SiteOrgCode`, default `hpuk`, pending ruling C-03;
   `SiteLocationCodes`, default `pof;har;ltp;ldn`) and `GuestAutoRemoval`
   (default No; see below).
5. **Import**. It takes a minute or two.
6. Set the environment variables (step 4), then open the solution and turn
   each flow on (they import switched off), in
   the order given in Deploying step 6. A flow that won't turn on shows the
   connection or setting it's missing.

**Updating.** Change the flows, bump `version` in `solution-config.json`,
rebuild and import again. The flow IDs are fixed, so the import upgrades the
existing flows instead of adding copies. Your connection and environment
variable values are kept.

**Not yet tried against a real tenant.** The package follows the standard
solution format, but it hasn't been imported anywhere yet. If the import
reports a specific error, the fix belongs in `tools/build_solution.py`, so
every future build includes it.

## Behaviour worth knowing

- **Guest expiry and G-11**: PID v4.2 allows no silent revocation outside
  four critical classes. With `GuestAutoRemoval` = No (the default), flow 02
  asks the site owner or sponsor on the end date: Approve removes the guest,
  Reject keeps access, records *Kept - owner decision* and tells InfoSec.
  Set it to Yes only if the Control Board rules expired guest access a
  critical class (D-GSA-03).
- **Naming standard**: flow 03 returns any request whose alias isn't lower
  case `[org]-[location]-[department]-[site]` with a known location code
  (G-08), as *Returned - Naming standard*.

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
