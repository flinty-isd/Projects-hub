# SharePoint list provisioning

Scripts that create the SharePoint lists both dashboards read, with the
exact internal column names the code expects.

| Script | Purpose |
| --- | --- |
| `Provision-SharePointLists.ps1` | Creates the lists and columns. Idempotent — safe to re-run. |
| `Add-SampleData.ps1` | Optionally seeds the lists with the same rows demo mode shows, to verify a live connection. |

> **Not yet run against a live tenant.** These were written without access
> to a SharePoint environment and have not been executed or syntax-checked.
> Read them before running, and use `-WhatIf` for a dry run first.

## Why internal names matter

SharePoint derives a column's *internal* name from its display name at
creation time, percent-encoding anything unusual. A column you create in
the browser called "Assigned To" ends up with the internal name
`Assigned_x0020_To` — and since the dashboards query Graph by internal
name (`AssignedTo`), that column silently reads back empty.

The script always creates a field with a space-free internal name and
sets the friendly display name as a second step, so the browser shows
"Assigned To" while Graph still sees `AssignedTo`. If you create these
lists by hand instead, create each column with the no-space name first,
then rename it.

## Prerequisites

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
```

**Authentication:** since PnP.PowerShell 2.x, the old multi-tenant PnP
Management Shell app is no longer available, so `-ClientId` is required.
Either register an app once per tenant:

```powershell
Register-PnPEntraIDApp -ApplicationName "PnP Provisioning" -Tenant contoso.onmicrosoft.com -Interactive
```

or reuse the client ID of an existing app registration that has delegated
SharePoint permissions. That client ID is what you pass as `-ClientId`
below. It is for *running these scripts*; it is separate from the
app-only registration the dashboards themselves use at runtime (which
needs the `Sites.Read.All` **application** permission).

You need permission to create lists on the target site — site owner or
site collection administrator.

## Usage

Dry run first:

```powershell
.\Provision-SharePointLists.ps1 `
    -SiteUrl "https://contoso.sharepoint.com/sites/ITGovernance" `
    -ClientId "00000000-0000-0000-0000-000000000000" `
    -WhatIf
```

Then for real. Use `-Include` to create only one dashboard's lists:

```powershell
# Both sets (default)
.\Provision-SharePointLists.ps1 -SiteUrl $url -ClientId $id

# Just the PM dashboard's Tasks + Risks
.\Provision-SharePointLists.ps1 -SiteUrl $url -ClientId $id -Include Pm

# Just the governance lists
.\Provision-SharePointLists.ps1 -SiteUrl $url -ClientId $id -Include Governance
```

Optionally seed sample rows. Person columns need accounts that resolve in
your directory, so pass real UPNs — dates are relative to today, so
overdue and expiring rows stay overdue whenever you run it:

```powershell
.\Add-SampleData.ps1 -SiteUrl $url -ClientId $id `
    -People "ana@contoso.com","raj@contoso.com"
```

`Add-SampleData.ps1` adds rows without clearing existing ones, so running
it twice creates duplicates.

If the two dashboards live on **different sites**, run the script once per
site with the matching `-Include`.

## What gets created

### PM dashboard — `/` (Streamlit) and `/aspx`

**Tasks**

| Internal name | Display | Type | Values |
| --- | --- | --- | --- |
| `Title` | Task | Text | built-in |
| `Status` | Status | Choice | Not Started, In Progress, Done |
| `AssignedTo` | Assigned To | Person | |
| `StartDate` | Start Date | Date | |
| `DueDate` | Due Date | Date | |
| `PercentComplete` | % Complete | Number (percentage) | 0–1, where 0.5 = 50% |
| `Priority` | Priority | Choice | High, Medium, Low |

**Risks**

| Internal name | Display | Type | Values |
| --- | --- | --- | --- |
| `Title` | Risk | Text | built-in |
| `Severity` | Severity | Choice | High, Medium, Low |
| `Owner` | Owner | Person | |
| `Status` | Status | Choice | Open, Mitigated, Closed |
| `Description` | Description | Multi-line text | |

### IT Governance — `/governance-aspx`

**Policies**

| Internal name | Display | Type | Values |
| --- | --- | --- | --- |
| `Title` | Policy | Text | built-in |
| `Category` | Category | Choice | Security, Data, Operations, Vendor, Architecture |
| `Owner` | Owner | Person | |
| `Status` | Status | Choice | Draft, Under Review, Approved, Expired |
| `Version` | Version | Text | |
| `LastReviewed` | Last Reviewed | Date | |
| `NextReview` | Next Review | Date | drives the currency rate |

**Controls**

| Internal name | Display | Type | Values |
| --- | --- | --- | --- |
| `Title` | Control Description | Text | built-in |
| `ControlId` | Control ID | Text | e.g. `A.8.2` |
| `Framework` | Framework | Choice | ISO 27001, NIST CSF, SOC 2, COBIT |
| `Owner` | Owner | Person | |
| `Status` | Status | Choice | Compliant, Partial, Non-Compliant, Not Assessed |
| `LastAssessed` | Last Assessed | Date | |

**AuditFindings**

| Internal name | Display | Type | Values |
| --- | --- | --- | --- |
| `Title` | Finding | Text | built-in |
| `Severity` | Severity | Choice | Critical, High, Medium, Low |
| `Source` | Source | Choice | Internal Audit, External Audit, Self-Assessment |
| `Owner` | Owner | Person | |
| `Status` | Status | Choice | Open, In Remediation, Closed |
| `RaisedDate` | Raised Date | Date | |
| `DueDate` | Due Date | Date | drives the overdue count |

**RiskRegister**

| Internal name | Display | Type | Values |
| --- | --- | --- | --- |
| `Title` | Risk | Text | built-in |
| `Category` | Category | Choice | Security, Technology, Operational, Compliance, Vendor, Financial |
| `Owner` | Owner | Person | |
| `Treatment` | Treatment | Choice | Mitigate, Accept, Transfer, Avoid |
| `Status` | Status | Choice | Open, Monitored, Closed |
| `Likelihood` | Likelihood (1-5) | Number | 1–5 |
| `Impact` | Impact (1-5) | Number | 1–5 |

**PolicyExceptions**

| Internal name | Display | Type | Values |
| --- | --- | --- | --- |
| `Title` | Exception | Text | built-in |
| `PolicyRef` | Against Policy | Text | |
| `RequestedBy` | Requested By | Person | |
| `Approver` | Approver | Person | |
| `Status` | Status | Choice | Pending, Active, Expired |
| `ExpiryDate` | Expires | Date | drives the 90-day expiry warning |

## Values the dashboards treat specially

Changing these choice values means changing the matching code:

- **Task/finding "done"** — `Done`, `Completed`, `Closed`, and (findings
  only) `Resolved` count as closed; everything else counts as open.
  Matching is case-insensitive.
- **Control compliance rate** — `Compliant` ÷ (all controls except
  `Not Assessed`). Adding a new status counts it against you unless you
  also update `GovernanceKpis.ComplianceRate`.
- **Risk score** — `Likelihood × Impact`; 15+ is high/extreme. Risks with
  status `Closed` are excluded from the high-risk count and heat map.
- **Policy currency** — a policy is current when `NextReview` is in the
  future. A blank `NextReview` counts as *not* current.
- **Exception expiry** — only `Active` exceptions are counted, and the
  warning window is 90 days (`ExpiryWindowDays` in `Exceptions.aspx.cs`).

## After provisioning

Point each dashboard at the site and lists:

- Streamlit — `.streamlit/secrets.toml` (`tasks_list`, `risks_list`)
- PM Web Forms — `aspx/Web.config`
- Governance — `governance-aspx/Web.config` (`PoliciesList`,
  `ControlsList`, `FindingsList`, `RisksList`, `ExceptionsList`)

If you rename a list, update the corresponding setting. The dashboards
fall back to demo data and show the Graph error in a banner rather than
crashing, so a name mismatch is visible rather than silent.
