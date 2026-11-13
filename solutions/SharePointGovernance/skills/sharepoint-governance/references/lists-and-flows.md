# Governance lists and flows (IT Enterprise Governance site)

## Lists (status values are exact; flows depend on them)

**Site Register:** Title, SiteTitle, SiteUrl, Department, PrimaryOwner,
SecondaryOwner, OwnersGroupId, MembersGroupId, VisitorsGroupId,
GuestsGroupId, SharingCapability (Disabled | ExistingExternalUserSharingOnly),
Sensitivity (General | Confidential | Highly Confidential), Status (Active |
Orphaned - owner inactive | Read-only | Archived), LastAccessReview and
NextAccessReview (optional since 1.2.0.0: site reviews are SAM attestations).

**Site Requests:** SiteAlias, Purpose, Department, Requester, PrimaryOwner,
SecondaryOwner, OwnersGroupId, MembersGroupId, VisitorsGroupId,
GuestsGroupId, ExternalSharingRequired, Sensitivity, Status (Submitted |
Provisioned | Provisioning failed | Rejected | Returned - Ownership invalid |
Returned - Naming standard), SiteUrl, DecisionLog.

**Access Requests:** Requester, UserType (Employee - view only | Employee -
edit / collaborate | Site Owner / Author | Long-term contractor | Screen /
kiosk / display | Privileged admin | Service / shared account), TargetSite
(lookup to Site Register), BusinessJustification, LineManager, GuestEmail,
AccessEndDate, Status (Submitted | Granted | Approved - awaiting AD group
change | Approved - PIM eligible assignment pending | Blocked - Licence
required | Blocked - Entra ID P2 required | Closed - Use Employee App |
Closed - Use published display page | Rejected | Rejected - Not time-bound |
Rejected - Prohibited | Rejected - Unknown access type),
ApprovedAccessMethod, DecisionLog.

**Guest Access Register:** Title (guest email), GuestUserId, GroupId,
SiteId, Sponsor, AccessEndDate, AccessRequestId, Status (Active | Removal
pending owner decision | Kept - owner decision | Expired - access removed |
Revoked), ReminderSent, RemovedOn.

**Access Review Log:** quarterly privileged-role reviews only (flow 06):
SiteId (empty), Outcome, Reviewer, Comments, AccessCount.

**File Share Register:** Title (share path), ShareOwner, SizeGB,
LastModified, IntegrationMarker, GenericAccountPresent, ApplicationBackEnd,
PermissionComplexity (Low | Medium | High), TargetSiteUrl, Disposition,
Status (Registered | Awaiting owner decision | Disposition required |
Disposition agreed | Approved - permissions remediation before migration |
Ready for migration | Migrated), DecisionLog.

**Decision Log:** Title (DL001…), Category (InfoPath | File share | Access),
Decision, DecidedBy, DecisionDate, Rationale.

## Flows (solution 1.3.0.0)

| Flow | Trigger | Does |
|---|---|---|
| 01 Access request | new Access Requests item | applies the access table; licence and P2 checks via Graph; guest ≤ 90 days; PIM for admins; Service Desk ticket for synced AD groups |
| 02 Guest access expiry | daily 06:00 | reminder 14 days before; on the end date asks owner or sponsor (G-11); removes only on Approve unless GuestAutoRemoval = Yes |
| 03 Site provisioning | new Site Requests item | naming, two owners, groups; service owner (and InfoSec) approval; asks IT Ops for the Sites.Selected grant; creates the site; calls the baseline runbook |
| 05 File share disposition | new File Share Register item | excludes system-dependent shares; routes remediation; service owner approval |
| 06 Quarterly privileged role review | monthly, acts Jan/Apr/Jul/Oct | InfoSec confirms SharePoint Administrator is PIM-eligible only; logs to Access Review Log |
| 07 Monthly site owner digest | monthly, 1st, 08:00 | one email per owner: one-owner sites, sharing on or unconfirmed, no label, guests ending in 30 days or awaiting decision, open access requests; all-clear otherwise; notify only; off until OwnerDigestEnabled = Yes |

Site access reviews, ownerless and inactive sites, and oversharing are SAM
policies, not flows (see pid-rules.md §7). Flow 04 was retired 25/10/2026.

## Common failures

| Symptom | Likely cause | Confirm | Fix / who |
|---|---|---|---|
| Runbook Errors mention 401/403/Forbidden | No Sites.Selected grant for that URL (G-04) | grant register; job output | IT Ops applies the grant; re-run the runbook |
| Site *Provisioned* but no label | label not published, or name mismatch | runbook throws "not published" | Purview admin publishes; re-run |
| *Provisioning failed* soon after approval | site not ready in SPSiteManager, or runbook job failed | flow run history; Automation job | re-run when ready |
| *Returned - Naming standard* unexpectedly | upper case, wrong org/location code, fewer than 4 parts | compare alias to G-08 | requester corrects and resubmits |
| *Blocked - Licence required* for a licensed user | no SharePoint plan, or user not found | assigned plans | licensing; or Employee App |
| Group change didn't happen | group synced from AD (DEP003) | group source in Entra | Service Desk changes it on-premises |
| Owner says site went read-only | SAM attestation not completed and enforcement on | SAM attestation report | owner attests; service owner restores if within policy |
| SAM ownership alert | fewer than 2 owners (owner left or disabled) | Entra account; Site Register | service owner names a replacement via request |
| Flow stops with a connection error | named owner's connection expired or owner left | flow connections | backup owner re-authenticates; never a shared account |

The runbook's last output line is `###RESULT###{json}` with Status, SiteUrl,
Steps and Errors. Partial success is failure (PID 7.4).
