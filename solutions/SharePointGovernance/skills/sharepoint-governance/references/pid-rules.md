# PID v4.2 rules and SAM policies for BAU governance

## Contents
1. Guardrails G-01 to G-14
2. Site request checklist
3. Access request checklist (Appendix A)
4. Guest access
5. File share disposition
6. Approval tiers and roles
7. SharePoint Advanced Management policies

## 1. Guardrails (PID v4.2 §6.4)

| Ref | Rule | In practice |
|---|---|---|
| G-01 | Named identity only; no service or shared accounts (D-03) | Flows run under named owners with backups; the runbook uses the Automation managed identity, the only sanctioned non-named identity |
| G-02 | DenyAddAndCustomizePages ON tenant-wide | No custom script; PnP page cmdlets and JSON formatting are the approved routes |
| G-03 | Restricted Content Discovery has no Graph endpoint | RCD by SAM / PowerShell with SharePoint Administrator rights |
| G-04 | Sites.Selected grants are per site | Every new site URL needs its own grant, applied by IT Ops and recorded in the grant register, before the baseline runbook runs |
| G-05 | FullWidth sections don't take Text web parts | Provisioned pages use OneColumn sections |
| G-06 | Embed web part sandboxes HTML, ES5 only | Link dashboards from Site Assets |
| G-07 | Branding | Re-baselining to Brand Guidelines V6 |
| G-08 | Naming | RefIDs zero-padded (R001, A001, DS001). URLs `sites/[org]-[location]-[department]-[site]`, lower case, org `hpuk`, location `pof`, `har`, `ltp`, `ldn`. Existing migrated sites under `/teams/` or with short aliases are covered by a recorded exception |
| G-09 | Verified schema is authoritative | Re-verify internal column names by CSV export before wiring a flow |
| G-10 | Independent verification | Success comes from the jobs log and result object, never a flow's or agent's claim |
| G-11 | No silent revocation outside four critical classes | Access decisions stay with site owners; SAM enforcement (read-only, archive) needs Board approval |
| G-12 | Every finding carries its evidence | URL, principal, level, timestamp and job ID |
| G-13 | Scope is the allowlist | A site outside Provisioning_Allowlist is out of scope, never assumed compliant |
| G-14 | Runbooks are read-and-report by default | Writes only for critical classes, logged first |

## 2. Site request checklist (flow 03)

1. **Alias (G-08):** lower case; at least four hyphen-separated parts; first
   `hpuk`; second `pof`, `har`, `ltp` or `ldn`; then department and site,
   e.g. `hpuk-pof-finance-payroll`. Fail → *Returned - Naming standard*.
2. **Two owners:** different, enabled, internal named users; no service,
   shared, generic or guest accounts (D-03). Fail → *Returned - Ownership
   invalid*. The SAM ownership policy also expects two owners.
3. **Groups:** OwnersGroupId and MembersGroupId are security groups, never
   individuals.
4. **Purpose:** clear, and no existing site for it in the Site Register.
5. **Sensitivity label:** General, Confidential or Highly Confidential,
   published in Purview (else the runbook fails). Highly Confidential needs
   InfoSec; consider SAM restricted access control and Restricted Content
   Discovery.
6. **External sharing:** `Disabled` by default. If required, InfoSec approves
   and it is limited to `ExistingExternalUserSharingOnly`. Never "Anyone".
7. **Approvals:** service owner for every site; InfoSec too for external
   sharing or Highly Confidential.
8. **After approval:** IT Ops applies the Sites.Selected grant (G-04), then
   the runbook applies sharing, custom script off, secondary admin, groups
   and label. *Provisioned* or *Provisioning failed*. SAM restricted site
   creation means flow 03 is the only route to a new site.

## 3. Access request checklist (Appendix A)

| User type | Approved method | Account | Licence | P2 | Allowed | Status if it doesn't fit |
|---|---|---|---|---|---|---|
| Staff without a Microsoft licence | Employee App (Base8 CMS) | none | none | no | view published documents | *Closed - Use Employee App* |
| Employee, view / edit | Site via security group | named | F3/E3 with SharePoint | no | read/write | *Blocked - Licence required* |
| Site owner / author | Owner/Author role | named | E3 or equivalent | yes | create, edit, publish | service owner is second approver |
| Long-term contractor | Entra ID guest, scoped | guest | no | no | read-only by default | *Rejected - Not time-bound* without an end date ≤ 90 days |
| Screen / kiosk | Published page, display mode | none | no | no | display only | *Closed - Use published display page* |
| Privileged admin | PIM-eligible role | named | licensed | yes | privileged | *Blocked - Entra ID P2 required* without P2; else *Approved - PIM eligible assignment pending*; InfoSec approves |
| Service / shared account | not permitted (D-03) | — | — | — | none | *Rejected - Prohibited* |

Anyone who signs in needs a named account and a licence with SharePoint
(minimum F3). Plans containing SHAREPOINT count; P2 is AAD_PREMIUM_P2. Synced
AD groups (DEP003) are changed by the Service Desk → *Approved - awaiting AD
group change*. Unknown user type → *Rejected - Unknown access type*.

## 4. Guest access

- 90 days maximum per grant, named Sponsor, MFA, read-only by default;
  renewal is a new request. InfoSec approves.
- Guests ending within 14 days are reviewed weekly.
- On the end date flow 02 asks the owner or sponsor (G-11): Approve →
  *Expired - access removed*; Reject → *Kept - owner decision*, InfoSec told.
  Automatic removal only if the Board rules it (D-GSA-03,
  `GuestAutoRemoval` = Yes).
- The tenant's built-in guest expiry setting stays **off** until D-GSA-03:
  it removes access without the owner deciding.

## 5. File share disposition (flow 05)

Case by case only. Exclude integration, application back-end or
generic-account shares (*Excluded - system dependent*; IT Ops agrees). High
permission complexity → *Approved - permissions remediation before
migration*. The service owner approves migrations; the share owner decides
disposition.

## 6. Approval tiers and roles

- David Flint (IT PM): changes within tolerance; low-risk decisions after IT
  approval, reported to the Board.
- Control Board (Ian Lowe, Pete Simmons): beyond tolerance, scope change,
  Medium and High risk, risk acceptance, SAM enforcement.
- Design Authority: permission breaks, baseline, template and brand changes.
- SharePoint service owner: new sites, file share migrations, second
  approver for owners; provisioning failures; SAM ownership alerts.
- InfoSec (Ian Lowe): guests, privileged roles, external sharing, Highly
  Confidential; quarterly admin-role review; oversharing follow-up.
- IT Operations (Carl Sharman): Sites.Selected grants, PIM assignments,
  excluded shares, SAM policy configuration, daily run check.
- Service Desk: AD group changes and removals for synced groups.
- Nigel Bell: site owner communications.

## 7. SharePoint Advanced Management policies (D-GSA-08)

| Policy | Covers | Settings | Who acts |
|---|---|---|---|
| Site attestation | 90-day site access review | Every 3 months; owners confirm the site is needed and owners, members, permissions and sharing are right | Site owners; enforcement (read-only, then archive) only after Board approval |
| Site ownership | Ownerless sites | Minimum 2 owners | Owner or service owner names a replacement through a request |
| Inactive sites | Unused sites | No activity for 6 months | Owner decides keep, archive or delete; recorded in the Decision Log |
| Data access governance reports + site access reviews | Oversharing (sharing links, Everyone, labels) | Tenant-wide reports; reviews delegated to owners | Owners fix; InfoSec follows up |
| Restricted site creation | Sites made outside flow 03 | Only the flow's named owner and admins | IT Ops |
| Restricted access control + Restricted Content Discovery | Sensitive sites (HR, Police & Security, Board, Executive) | Access limited to the site's group; hidden from org-wide search and Copilot | IT Ops, InfoSec approves the list |

Licensing: confirm each feature is covered; restricted site creation needs
SAM Plan 1.
