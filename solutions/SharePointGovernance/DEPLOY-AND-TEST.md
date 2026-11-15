# Governance deployment and test guide (solution 1.5.0.0)

How to deploy the SharePoint governance flows, runbook, dashboard and SAM
policies to a test environment, test them, and then go live. Work through it
in order; each section says who does it.

Deploy from the **deployment kit** (`SharePointGovernance-DeploymentKit_1_5_0_0.zip`,
CI artifact *SharePointGovernance-DeploymentKit*, or `python tools/build_kit.py`).
It holds everything this guide refers to and a `MANIFEST.json` of SHA-256
checksums: check them before you start and keep the manifest with the test
evidence.

| Role | Does |
|---|---|
| IT PM | Runs the deployment and the tests |
| Verifier (not the IT PM) | Checks each test's evidence independently before sign-off |
| Named governance flow owner (and backup) | Owns the connections the flows run as (D-03: never a shared or service account) |
| IT Operations owner | Automation account, runbook, Sites.Selected grants, SAM policies |
| SharePoint service owner | Governance site, lists, Site Register data, approvals |
| InfoSec | Graph permissions, guest and privileged-role approvals |

## 1. Before you start

- [ ] **Environments**: a Power Platform **test** environment and the **production** BAU environment. Never test in Default.
- [ ] **Test site**: a copy of the IT Enterprise Governance site (or a test site collection), plus two or three throwaway test sites to provision and break.
- [ ] **Test people**: two internal test users who can act as site owners, one unlicensed or F3 user, one external test mailbox for a guest.
- [ ] **Licences**: the flow owner has Power Automate premium (HTTP with Entra ID and Azure Automation are premium). Confirm SAM covers each policy (restricted site creation needs SAM Plan 1).
- [ ] **Kit**: `SharePointGovernance-DeploymentKit_1_5_0_0.zip`; checksums match `MANIFEST.json`.

## 2. Deploy to test

### 2.1 Lists (SharePoint service owner)

1. On the test governance site, create the lists in `sharepoint/list-schema.json` (PnP.PowerShell, or by hand from the column guide in `sharepoint/csv/README.md`).
2. Check the Site Register has the **Urgent alert sent for** text column (`UrgentAlertKey`, flow 08), and the Guest Access Register has **Decision due by** (`DecisionDueBy`) and **Kept until** (`KeptUntil`) date columns (flow 02). On lists created before 1.5.0.0, add these by hand.
3. Load a **small** Site Register sample from `Site_Register.csv`: five or six rows for the test sites and test owners, not all 225. Include one site with no secondary owner, one with external sharing on, and one with no sensitivity label, so the digest has something to report.

### 2.2 Dashboard (IT PM)

```powershell
./provisioning/Provision-GovernanceDashboard.ps1 -GovernanceSiteUrl <test governance site URL> -Interactive
```

Check each panel shows its filtered view, not All Items.

### 2.3 Connections (named governance flow owner)

In the test environment, signed in as the named flow owner, create one connection each for:

| Connection | Notes |
|---|---|
| SharePoint | |
| Office 365 Outlook | Sends all emails, as the flow owner |
| Approvals | |
| HTTP with Microsoft Entra ID | Base resource and Azure AD resource URI both `https://graph.microsoft.com` |
| Azure Automation | |

### 2.4 Graph permissions (InfoSec approves)

For the HTTP with Entra ID connection: `User.Read.All`, `GroupMember.ReadWrite.All`, `User.Invite.All`, `RoleManagement.Read.Directory`.

### 2.5 Runbook (IT Operations owner)

1. Import `runbooks/Set-SiteGovernanceBaseline.ps1` into the test Automation account (PowerShell 7.2, PnP.PowerShell 2.x).
2. Add the Automation variable `TenantName`.
3. Turn on the account's system-assigned managed identity and give it the SharePoint Administrator role.

### 2.6 Import the solution (IT PM)

1. make.powerautomate.com → test environment → **Solutions → Import solution** → choose the .zip.
2. Map each of the five connection references to the connections from 2.3.
3. Leave the environment variables empty on the import screen; **Import**.
4. Open the solution → **Environment variables** and set the current values:

| Variable | Test value |
|---|---|
| Governance site URL | The test governance site |
| Tenant root URL | `https://hphneu.sharepoint.com` |
| SharePoint service owner / InfoSec approver / IT Operations owner / Service Desk email | Test mailboxes you can read (not the real role mailboxes during testing) |
| Automation subscription ID / resource group / account name | The test Automation account |
| Site URL organisation code / location codes | Leave `hpuk` and `pof;har;ltp;ldn` |
| Remove expired guests automatically | **No** |
| Kept guest exception (days) | 30 |
| SharePoint service plans | Leave `SHAREPOINTDESKLESS;SHAREPOINTSTANDARD;SHAREPOINTENTERPRISE` unless IAM confirms others |
| Entra ID P2 service plans | Leave `AAD_PREMIUM_P2` |
| Send the monthly owner digest | **No** for now |
| Send all-clear digests | **No** (until the digest's coverage is accepted) |
| Send urgent site alerts | **No** for now |

5. If 1.2.0.0 or earlier was imported before, delete the unused **Access review interval (days)** variable.

### 2.7 Turn the flows on (IT PM)

In this order: **03**, **06**, then **01**, **02**, then **05**, then **07** and **08**. Flows 07 and 08 stay quiet until their switches are Yes (tests T15–T21).

### 2.8 SAM policies (IT Operations owner, InfoSec approves)

SAM policies don't all scope the same way, and the tenant is shared, so there is no single "test sites only" switch. Before changing any policy, record its current configuration and agree its scope with InfoSec, policy by policy:

- **Site attestation, ownership, inactive sites**: scope by the policy's own filters (site template, sensitivity, creation source, etc.) and run in notify or simulation mode. Check the planned scope report before turning on.
- **Data access governance reports**: read-only; safe to run tenant-wide.
- **Restricted site creation**: a **tenant setting** scoped by security groups and site types, not by site URL. It can't be confined to test sites: change it only as a planned production change, or test it in a separate tenant.
- **Restricted access control and Restricted Content Discovery**: set per site; test on a test site only.

Export the configuration before and after each change. See `SAM-POLICIES.md` for the settings.

## 3. Test

Record each result (pass, fail, notes) in the UAT log. For any fail, keep the flow run history and the `###RESULT###` line from the Automation job (G-10: success comes from evidence, not a flow saying it succeeded).

| ID | Area | Set up / do | Expected result |
|---|---|---|---|
| T01 | 03 Site request | New Site Requests item: alias `hpuk-pof-test-uat1`, two test owners, groups, General | Service owner approval; IT Ops asked for the Sites.Selected grant; site created; Automation job **Completed** with a `###RESULT###` line of `Success` including the read-back step; check on the site itself that groups, sharing and label are as requested; then Status *Provisioned* and a Site Register row |
| T02 | 03 Naming | Alias `HPUK-Test_UAT2` | Status *Returned - Naming standard*; requester emailed |
| T03 | 03 Ownership | Same person as primary and secondary owner | Status *Returned - Ownership invalid* |
| T04a | 03 Grant refused | IT Ops rejects the grant approval | *Provisioning failed*; service owner told; no Site Register row |
| T04b | 03 Grant missing | IT Ops approves but doesn't actually apply the grant | Job fails or result not Success (403); *Provisioning failed*; high-importance email to service owner and IT Ops with the job ID and errors; no Site Register row |
| T04c | 03 Partial baseline | Use a sensitivity label name that isn't published | Result not Success; *Provisioning failed*; the email lists the steps done, so the partial site can be corrected |
| T04d | 03 No result | Temporarily break the runbook's last line (test copy only) | Missing `###RESULT###` treated as failure: *Provisioning failed* |
| T05 | 01 Employee | Licensed test user, *Employee - edit / collaborate* | *Granted* (cloud group) or *Approved - awaiting AD group change* (synced group) |
| T06 | 01 No licence | Unlicensed test user, and a user whose SharePoint plan is assigned but **disabled** | Both *Blocked - Licence required* (only plans with status Success count) |
| T06b | 01 Graph failure | Temporarily remove the Graph permission from the test connection | Request stays *Submitted*; DecisionLog says the check failed; service owner and IT Ops emailed; no licensing verdict |
| T06c | 01 Disabled account | Request for a disabled or guest account as *Employee - edit / collaborate* | *Rejected*, with the reason in DecisionLog |
| T07 | 01 Contractor | *Long-term contractor*, end date 6 months ahead | *Rejected - Not time-bound* |
| T08 | 01 Contractor | Same, end date 30 days ahead, sponsor named | InfoSec approval; guest added to the site's Guests group; Guest Access Register row *Active* |
| T09 | 01 Prohibited | *Service / shared account* | *Rejected - Prohibited* |
| T10 | 01 Admin | *Privileged admin*, user without an active P2 plan | *Blocked - Entra ID P2 required* before any InfoSec approval is created; with P2, the InfoSec approval follows |
| T11 | 02 Reminder | Guest from T08: set end date to 10 days ahead, run flow 02 | One reminder to sponsor and owner; ReminderSent = Yes; no second reminder next day |
| T12 | 02 Expiry | Set end date to yesterday, run flow 02, owner rejects removal | *Kept - owner decision*; Kept until = today + 30; InfoSec told; guest not removed |
| T12b | 02 No decision | As T12 but nobody answers; set Decision due by to yesterday and run flow 02 | Escalation to service owner and InfoSec; Decision due by moves on 7 days; status stays pending and shows on the dashboard and digest |
| T12c | 02 Exception ends | Set Kept until to yesterday and run flow 02 | Owner asked to decide again (pending, new due date) |
| T13 | 05 File share | File Share Register item with Integration marker = Yes | *Excluded - system dependent*; IT Ops asked to agree |
| T14 | 06 Privileged | Run flow 06 by hand outside Jan/Apr/Jul/Oct | Does nothing (only acts in quarter months). The quarter-month branch is reworked separately (review R17) before it is tested |
| T15 | 07 Off | Switch No, run flow 07 by hand | No emails |
| T16 | 07 Digest | Switch Yes, run flow 07 by hand | The owner of the sample sites gets one email listing the orphaned site, the one-owner site, the sharing-on site, the no-label site and any kept guests, each with what to do, and saying it is a register check |
| T17 | 07 All clear | A test owner whose sites have no issues, with *Send all-clear digests* No, then Yes | No email while No; one all-clear (worded as a register check) when Yes. An owner with one clean and one orphaned site gets a digest, never an all-clear |
| T18 | 08 Off | Switch No; set a test site's Status to *Orphaned - owner inactive* | No email |
| T19 | 08 Orphaned | Switch Yes; set another test site's Status to *Orphaned - owner inactive* | One high-importance email to both owners and the service owner at the next trigger poll (every 5 minutes; not a delivery guarantee); *Urgent alert sent for* = `orphaned;` |
| T20 | 08 No repeat | Edit the same site's Department | No second email |
| T21 | 08 Cleared and HC | Set the site back to Active (column clears); then set Sensitivity Highly Confidential with sharing ExistingExternalUserSharingOnly | Second step: one email with InfoSec copied |
| T22 | Dashboard | Open Governance-Dashboard.aspx | Each panel shows its view and the items created in T01–T21; Status badges coloured with words |
| T23 | SAM | Attestation (notify only) on one test site | Owner receives the attestation email; nothing goes read-only |

**Exit criteria:**

- These tests can't be waived: T01, T04a–d, T06–T06c, T07–T10, T12–T12c, T19–T20. A failure blocks go-live until fixed and retested.
- Any other failure can be accepted only by the owner of that control (InfoSec/IAM for access and guests, records owner for retention, IT Operations for automation), recorded with an expiry date and a compensating control. The IT PM and service owner can't waive it alone.
- The verifier signs off each test against its evidence (run history, `###RESULT###` lines, list items, emails), with the kit's `MANIFEST.json`, the environment variable values and the test identities.

Review findings still open (R16 alert deduplication under concurrent edits, R17 privileged review, and the news P0 items) are tracked in the review action register and must be closed or formally accepted before production.

## 4. Go live (production)

1. Agree the date with the Control Board (plan: w/c 4 January 2027).
2. Repeat 2.1 to 2.7 in production with **real** values: the real governance site, role mailboxes and Automation account. Load the full Site Register (225 sites) after the owner emails have been checked.
3. Turn the flows on in the same order, with both switches still **No**.
4. Run the production smoke tests: T01 with a real request, T05 and T10 with real accounts, T22, and confirm a failure alert reaches the support mailbox.
5. Brief site owners (comms lead), then set **Send urgent site alerts** = Yes and, from the 1st of the next month, **Send the monthly owner digest** = Yes.
6. Configure the SAM policies in the order in `SAM-POLICIES.md`, notify-only until the Board approves enforcement.
7. Hand over to the SharePoint service owner's team: flows, connections (backup owner signed in), runbook, dashboard and this guide.

## 5. Stopping and recovery

Turning a flow off stops new runs. It doesn't undo what runs already did: sites created, group members added or removed, emails sent, list items written.

1. **Stop**: turn the affected flow off (or set its switch to No). Check its run history for runs still in progress, including ones waiting on an approval, and cancel them if they must not finish.
2. **Find side effects**: for each run since the problem started, list what it changed (site created, group change, register write, email). Flow 03's failure emails and the runbook's `###RESULT###` lines list the steps done.
3. **Reconcile**: correct each change deliberately, with the owner of that control agreeing (IAM/InfoSec for access, service owner for sites). Don't blindly re-grant access or delete sites; record what was changed back and why.
4. **Keep evidence**: run history, job output and the list item versions.
5. **Fix forward**: a lower solution version can't be imported over a higher one, so correct the flow, bump the version, rebuild the kit, retest the affected tests and import.

Note: with **Remove expired guests automatically** = Yes (only if the Board rules it, D-GSA-03), flow 02 removes guests without asking. With the default No, removals need an owner's decision.
