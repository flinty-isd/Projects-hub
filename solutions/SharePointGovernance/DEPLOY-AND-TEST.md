# Governance deployment and test guide (solution 1.4.0.0)

How to deploy the SharePoint governance flows, runbook, dashboard and SAM
policies to a test environment, test them, and then go live. Work through it
in order; each section says who does it.

| Role | Does |
|---|---|
| IT PM | Runs the deployment, the tests and the sign-off |
| Named governance flow owner (and backup) | Owns the connections the flows run as (D-03: never a shared or service account) |
| IT Operations owner | Automation account, runbook, Sites.Selected grants, SAM policies |
| SharePoint service owner | Governance site, lists, Site Register data, approvals |
| InfoSec | Graph permissions, guest and privileged-role approvals |

## 1. Before you start

- [ ] **Environments**: a Power Platform **test** environment and the **production** BAU environment. Never test in Default.
- [ ] **Test site**: a copy of the IT Enterprise Governance site (or a test site collection), plus two or three throwaway test sites to provision and break.
- [ ] **Test people**: two internal test users who can act as site owners, one unlicensed or F3 user, one external test mailbox for a guest.
- [ ] **Licences**: the flow owner has Power Automate premium (HTTP with Entra ID and Azure Automation are premium). Confirm SAM covers each policy (restricted site creation needs SAM Plan 1).
- [ ] **Package**: `SharePointGovernance_1_4_0_0.zip` (Actions → *Governance flows* → artifact, or `python tools/build_solution.py`).

## 2. Deploy to test

### 2.1 Lists (SharePoint service owner)

1. On the test governance site, create the lists in `sharepoint/list-schema.json` (PnP.PowerShell, or by hand from the column guide in `sharepoint/csv/README.md`).
2. Check the Site Register has the **Urgent alert sent for** text column, internal name `UrgentAlertKey` (needed by flow 08).
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
| Send the monthly owner digest | **No** for now |
| Send all-clear digests | Yes |
| Send urgent site alerts | **No** for now |

5. If 1.2.0.0 or earlier was imported before, delete the unused **Access review interval (days)** variable.

### 2.7 Turn the flows on (IT PM)

In this order: **03**, **06**, then **01**, **02**, then **05**, then **07** and **08**. Flows 07 and 08 stay quiet until their switches are Yes (tests T15–T21).

### 2.8 SAM policies (IT Operations owner)

SAM policies are tenant-wide, so in test scope them to the test sites only, notify-only. Follow `SAM-POLICIES.md` for settings.

## 3. Test

Record each result (pass, fail, notes) in the UAT log. For any fail, keep the flow run history and the `###RESULT###` line from the Automation job (G-10: success comes from evidence, not a flow saying it succeeded).

| ID | Area | Set up / do | Expected result |
|---|---|---|---|
| T01 | 03 Site request | New Site Requests item: alias `hpuk-pof-test-uat1`, two test owners, groups, General | Service owner approval; IT Ops asked for the Sites.Selected grant; site created; runbook result `Success`; Status *Provisioned*; site added to the Site Register |
| T02 | 03 Naming | Alias `HPUK-Test_UAT2` | Status *Returned - Naming standard*; requester emailed |
| T03 | 03 Ownership | Same person as primary and secondary owner | Status *Returned - Ownership invalid* |
| T04 | 03 Grant missing | Approve a request but don't apply the Sites.Selected grant | Runbook 403; Status *Provisioning failed*; service owner emailed |
| T05 | 01 Employee | Licensed test user, *Employee - edit / collaborate* | *Granted* (cloud group) or *Approved - awaiting AD group change* (synced group) |
| T06 | 01 No licence | Unlicensed test user | *Blocked - Licence required* |
| T07 | 01 Contractor | *Long-term contractor*, end date 6 months ahead | *Rejected - Not time-bound* |
| T08 | 01 Contractor | Same, end date 30 days ahead, sponsor named | InfoSec approval; guest added to the site's Guests group; Guest Access Register row *Active* |
| T09 | 01 Prohibited | *Service / shared account* | *Rejected - Prohibited* |
| T10 | 01 Admin | *Privileged admin*, user without P2 | *Blocked - Entra ID P2 required* |
| T11 | 02 Reminder | Guest from T08: set end date to 10 days ahead, run flow 02 | One reminder to sponsor and owner; ReminderSent = Yes; no second reminder next day |
| T12 | 02 Expiry | Set end date to yesterday, run flow 02, owner rejects removal | *Kept - owner decision*; InfoSec told; guest not removed |
| T13 | 05 File share | File Share Register item with Integration marker = Yes | *Excluded - system dependent*; IT Ops asked to agree |
| T14 | 06 Privileged | Run flow 06 by hand outside Jan/Apr/Jul/Oct | Does nothing (only acts in quarter months). In January: InfoSec approval with active and eligible counts; Access Review Log row |
| T15 | 07 Off | Switch No, run flow 07 by hand | No emails |
| T16 | 07 Digest | Switch Yes, run flow 07 by hand | The owner of the sample sites gets one email listing the one-owner site, the sharing-on site and the no-label site, each with what to do |
| T17 | 07 All clear | A test owner whose sites have no issues | One all-clear email |
| T18 | 08 Off | Switch No; set a test site to *Orphaned - owner inactive* | No email |
| T19 | 08 Orphaned | Switch Yes; set another test site to Orphaned | One high-importance email to both owners and the service owner within about 5 minutes; *Urgent alert sent for* = `orphaned;` |
| T20 | 08 No repeat | Edit the same site's Department | No second email |
| T21 | 08 Cleared and HC | Set the site back to Active (column clears); then set Sensitivity Highly Confidential with sharing ExistingExternalUserSharingOnly | Second step: one email with InfoSec copied |
| T22 | Dashboard | Open Governance-Dashboard.aspx | Each panel shows its view and the items created in T01–T21; Status badges coloured with words |
| T23 | SAM | Attestation (notify only) on one test site | Owner receives the attestation email; nothing goes read-only |

**Exit criteria:** every test passes, or a fail is logged with an owner and agreed by the IT PM and service owner as not blocking.

## 4. Go live (production)

1. Agree the date with the Control Board (plan: w/c 4 January 2027).
2. Repeat 2.1 to 2.7 in production with **real** values: the real governance site, role mailboxes and Automation account. Load the full Site Register (225 sites) after the owner emails have been checked.
3. Turn the flows on in the same order, with both switches still **No**.
4. Run one smoke test: T01 with a real request, then T22.
5. Brief site owners (comms lead), then set **Send urgent site alerts** = Yes and, from the 1st of the next month, **Send the monthly owner digest** = Yes.
6. Configure the SAM policies in the order in `SAM-POLICIES.md`, notify-only until the Board approves enforcement.
7. Hand over to the SharePoint service owner's team: flows, connections (backup owner signed in), runbook, dashboard and this guide.

## 5. Rollback

- **A flow misbehaves**: turn that flow off in the solution. The others carry on.
- **Too many emails**: set the digest or urgent-alert switch to No; nothing else changes.
- **Whole release**: turn all governance flows off. A lower solution version can't be imported over a higher one, so fix forward: correct the flow, bump the version, rebuild and import.
- Nothing in these flows removes access without a person deciding (G-11), so turning flows off loses no data.
