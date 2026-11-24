# Enterprise PMO hub: deploy and test

Do every step on a **test site and a dev environment** first. Production
repeats the same steps from the same deployment kit (check its
`MANIFEST.json`), under the rules in the
[Power Platform deployment plan](../POWER-PLATFORM-DEPLOYMENT.md).

## 1. Site, lists and page

1. Create the PMO site (a communication site, e.g. `/sites/EnterprisePMO`) and
   set its regional time zone to **(UTC+00:00) Dublin, Edinburgh, Lisbon,
   London**. The flows treat date-only columns as UK local dates.
2. Run the script as a site owner:

   ```powershell
   ./provisioning/Provision-PMOHub.ps1 -SiteUrl https://<tenant>.sharepoint.com/sites/EnterprisePMO -Interactive `
       -LeadershipContacts <director-upn>, <head-of-pmo-upn>, <governance-lead-upn>
   ```

   Check: all 10 lists and libraries exist and versioning is on. *Tracked date
   (flow)* and *Tracked status (flow)* don't appear on the new or edit forms.
   *RAG rating* shows a coloured pill.
3. Finish the page by hand, following the steps the script prints (Quick
   Links, Power BI, commentary, People). Then make it the home page.
4. **Permissions.** Give the flow owner Edit on the site. Make PMO Trend
   Snapshots, PMO Date Push Log and PMO Digest History **read-only** for
   everyone else: break inheritance, grant Read to members and Edit to the
   flow owner only. They are the audit trail.
5. Add at least two rows to *PMO Workstreams* (Active = Yes).

## 2. Teams

1. Create, or choose, the **Executive PMO Steering Committee** channel and the
   **PMO Risk Advisory** channel. Add the flow owner to both teams.
2. Get each team ID and channel ID: in the channel, *... > Get link to
   channel*. The link contains `groupId=` and `/channel/19:...`. URL-decode the
   channel ID.

## 3. Import the solution

1. Under the **named PMO flow owner** (no service account, D-03), create
   connections for SharePoint, Microsoft Teams, Office 365 Outlook and
   Approvals.
2. Import `EnterprisePMO_<version>.zip` (Solutions > Import solution) and bind
   the four connection references.
3. Open the solution's **Environment variables** and set `PMOSiteUrl`,
   `PMOOwnerEmail`, the four Teams IDs, the approvers (`CRPMOApproverEmails`,
   `CRSteerCoApproverEmails`, `EscalationApproverEmails`), the change
   tolerances and, if you want copies, `SupportMailboxEmail`. Leave
   `DigestEnabled`, `EarlyWarningEnabled`, `CRApprovalsEnabled` and
   `EscalationAlertsEnabled` at No for now.
4. Turn on 03a and 03b first, then 05, 04, 01 and 02.

## 4. Tests

Run each test and record the result (pass / fail, run ID).

| # | Test | Expect |
|---|------|--------|
| T1 | New RAID item with a target date | Within 5 min, one 03a run. *Original baseline date* = target date, *Date pushes* = 0, no Push Log row. Exactly one run: the flow's own update doesn't start another |
| T2 | Move T1's target date 7 days later | One 03a run. Push Log row (+7 days, *Pushes of this item in window* = 1). *Date pushes* = 1. *Last date push* filled in. Baseline unchanged |
| T3 | Move it later again | Push Log row with *Pushes in window* = 2. *Date pushes* = 2 |
| T4 | Bring the date forward | 03a runs, no Push Log row, count unchanged |
| T5 | Edit only the Title | No 03a run (trigger condition false) |
| T6 | Set Status = Closed | *Closed on* = today. Reopen and close again: *Closed on* moves to the new date |
| T7 | Repeat T1–T6 on an Action item (03b, *Completed on*) | Same behaviour |
| T8 | Set `DigestEnabled` = Yes. Have one escalated RAID item with yesterday's target date and one Executive Board action due yesterday. Run 01 | One card in the Steering Committee channel with both items, owners and dates. A PMO Digest History row marked Posted |
| T9 | Run 01 again the same day | Nothing posted (the row already exists) |
| T10 | Item due **today** | Not in the digest. On the hub it shows amber *due soon*, not red |
| T11 | Nothing overdue | 01 posts nothing and writes no row |
| T12 | Set a wrong channel ID and run 01 (delete today's row first) | Row marked Failed, digest-not-posted email to `PMOOwnerEmail` |
| T13 | Run 02 with `EarlyWarningEnabled` = No | One PMO Trend Snapshots row per active workstream, with counts that match the lists. No card |
| T14 | Run 02 again | No new rows (one per workstream per week) |
| T15 | Delete this week's rows. Push one item twice (T2–T3) and create 3 risks in one workstream. Set `EarlyWarningEnabled` = Yes and run 02 | Score ≥ 2 for that workstream. Advisory card posted with the reason. *Advisory posted* = Yes |
| T16 | Break a flow (e.g. a wrong `PMOSiteUrl`) and run it | *Flow failed* email to `PMOOwnerEmail` with the failed step |
| T18 | Set `CRApprovalsEnabled` = Yes. New Timeline CR, schedule impact 5 days, budget 0 | CR-nnn allocated, Status *Under review - PMO*, route PMO. Approve: Status Approved, *Decided by* and note filled in, a *Decision Made* item in the Action and Decision Tracker (forum PMO, Completed), requester emailed |
| T19 | New Scope CR | PMO approval, then Status *Under review - Steering Committee* and a second approval. Reject at the Steering Committee: Rejected, decision logged with forum Steering Committee |
| T20 | New Budget CR over `CRBudgetTolerance`; the PMO rejects | *Returned to requester*, no decision logged, requester and PMO emailed |
| T21 | New CR; the requester sets Withdrawn before the PMO responds, then the PMO approves | Status stays Withdrawn, no decision logged |
| T22 | CR approval left unanswered (for the test, shorten the timeout in a dev copy) | *Decision overdue*, requester and PMO emailed |
| T23 | Tick *Request Executive Board escalation* on a RAID item, with a reason | Within 5 min *Escalation status* = Requested, and the approver gets the request with the details. Only one approval is sent, even though 03a also runs |
| T24 | Approve T23 with `EscalationAlertsEnabled` = Yes | *Escalated to Executive Board* = Yes, status Approved, decision note filled in, card in the Steering Committee channel, submitter and owner emailed. The item shows in *Executive escalations* on the hub |
| T25 | Request on another item; decline | Status Declined, the tick cleared, no flag set. Tick again: a new approval is sent |
| T26 | Hub section 5 | The open CRs and the escalation requests show, with outcome badges |
| T17 | Hub page | Each panel shows its view, and overdue dates show red with *overdue*. Comments are off. The page works on a phone |

## 5. Run checks (BAU)

- **Daily**: the PMO mailbox owner checks the run history of 01 and 03a/03b.
  The failure email only covers runs that started and then failed.
- **Weekly (Monday)**: check 02 wrote one snapshot per active workstream.

## Stopping and recovery

- **Stop all posting**: set `DigestEnabled` and `EarlyWarningEnabled` to No.
  The churn trackers keep recording and post nothing.
- **Digest failed**: fix the cause, delete today's *Failed* row in PMO Digest
  History, and resubmit the run.
- **Early warning failed part-way**: resubmit the run. Workstreams that
  already have a snapshot this week are skipped.
- **Change request stuck**: a request with *Decision overdue* is decided at
  the next Steering Committee. The PMO sets Status, *Decided by* and
  *Decision note* by hand and adds the *Decision Made* item. Requests created
  while `CRApprovalsEnabled` was No are never picked up: raise them again.
- **Escalation request stuck in Requested** (its run failed after the
  claim): set *Escalation status* back to *Not requested*. If the box is
  still ticked, flow 05 picks it up again on the next edit.
- **Churn tracker failed**: the next edit of the item retries it, because the
  tracked values weren't updated. For a date push that failed, the push is
  still detected on the next edit as long as the date stays later.
- **Turning a churn tracker off loses nothing**: when it's back on, the first
  edit of each item compares against the last tracked value.
