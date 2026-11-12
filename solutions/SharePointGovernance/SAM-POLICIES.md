# SharePoint Advanced Management (SAM) policies

From governance solution **1.2.0.0**, SharePoint Advanced Management does the
site reviews that flow 06 used to do (D-GSA-08: SAM native controls instead of
custom flows and PowerShell). This sheet is what IT configures in the
**SharePoint admin centre → Policies**, and what the Control Board approves.

Flows 01 (access requests), 02 (guest expiry, owner decides), 03 (site
provisioning and baseline runbook) and 05 (file shares) are unchanged. Flow 06
now only runs the quarterly privileged-role review.

## Before configuring

1. **Licensing.** Confirm with IT that the tenant's SAM licence covers each
   policy below. Restricted site creation needs SAM Plan 1; the PID records E5
   including SAM, but check the specific features.
2. **Board approval of enforcement (G-11).** Making an unattested site
   read-only, then archiving it, is an automatic action. Owners are notified
   first, so it isn't silent, but the Board approves it explicitly. Until it
   does, set enforcement to **notify only**.
3. **Owners in place.** The ownership and attestation policies email site
   owners, so load the Site Register and fix single-owner sites first (144 in
   the October extract).

## Policies

| # | Policy (admin centre) | Replaces | Scope | Settings | Notifies | Enforcement |
|---|---|---|---|---|---|---|
| S1 | **Site attestation** | Flow 06 90-day site access review | All SharePoint sites in the Site Register; exclude the root and system sites (App Catalog, Search, Content Type Hub, My) | Every **3 months** (keeps the PID's 90-day cycle) | Site owners; copy SharePoint service owner | **Notify only** until the Board approves; then read-only after non-response, archive (Microsoft 365 Archive) after the read-only period |
| S2 | **Site ownership** | Flow 06 ownerless-site detection | All sites | Minimum **2 owners** (primary and secondary, D-03 named users) | Existing owner; SharePoint service owner when none is left | Notify only |
| S3 | **Inactive sites** | New | All sites; start with the 83 "Wave 1 – Stale Sites" | No activity for **6 months** | Site owners | Notify only; archive or delete by owner decision, recorded in the Decision Log |
| S4 | **Data access governance reports** and **site access reviews** | Manual oversharing checks | Whole tenant | Reports: sharing links, "Everyone except external users", sensitivity labels. Send site access reviews to owners of flagged sites | Site owners (through site access review) | None: owners act, InfoSec follows up |
| S5 | **Restricted site creation** | Gap: anyone could create sites outside flow 03 | Tenant | Only the governance flow's named owner and SharePoint admins can create sites | n/a | Blocks other creation |
| S6 | **Restricted access control** and **Restricted Content Discovery** | Runbook RCD (G-03) for named sites | HR (Wave 5), Police & Security, Control Board and Executive sites | Access limited to the site's security group; content hidden from org-wide search and Copilot | n/a | Enforced |

**Not changed:** the tenant's built-in guest expiry setting stays **off**.
Turning it on removes guest access automatically, which conflicts with G-11.
Flow 02 keeps the owner-decides step until the Board decides D-GSA-03.

## Order

1. S4 reports first: they show where the 161 sites with external sharing
   stand. Start with the 8 Police & Security sites.
2. S5 and S6.
3. S2 (ownership), once secondary owners are loaded.
4. S1 (attestation) in notify-only mode; switch on enforcement after Board
   approval.
5. S3 (inactive sites).

## Decision Log entry (draft for the Control Board)

| Field | Value |
|---|---|
| Title | DL-GSA-08 |
| Category | Access |
| Decision | Adopt SharePoint Advanced Management native controls for site access reviews, ownership and inactive sites (D-GSA-08, Option: SAM native). Flow 06 is reduced to the quarterly privileged-role review |
| Options considered | A: keep custom flows and PowerShell (flow 06, RB-11, Flow 31). B: SAM native controls (recommended). C: SAM for reporting only, flows for action |
| Risk | Medium (Board decision) |
| Decided by | Control Board (Ian Lowe, Pete Simmons) |
| Decision date | *(Board date)* |
| Rationale | SAM is licensed (E5) and supported by Microsoft; it removes custom code to maintain and covers ownerless and inactive sites, oversharing and restricted access, which the flows didn't. Attestation every 3 months keeps the 90-day review. Enforcement (read-only, archive) starts only when the Board approves it (G-11). Built-in guest expiry stays off pending D-GSA-03 |

## Upgrading the solution

Import **SharePointGovernance_1_2_0_0.zip** over 1.1.x. The import replaces
flow 06 with the privileged-role review. The `ReviewIntervalDays`
environment variable is no longer used; delete it from the solution by hand
if you want it gone (an unmanaged upgrade doesn't remove it).
