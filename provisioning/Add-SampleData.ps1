<#
.SYNOPSIS
    Seeds the provisioned lists with the same sample rows the dashboards show in demo mode.

.DESCRIPTION
    Useful for verifying a live connection end to end before real data is entered:
    run this, point the dashboard at the site, and the numbers should match what
    demo mode showed.

    Person columns are set to real accounts, since SharePoint rejects names that
    don't resolve in the directory. Pass -People to spread rows across several
    users; by default every person column is set to the signed-in user.

    Dates in the sample rows are relative to today, so overdue/expiring rows stay
    overdue no matter when you run this.

.PARAMETER SiteUrl
    Full URL of the target site.

.PARAMETER ClientId
    Entra ID application client ID used for the interactive sign-in.

.PARAMETER People
    One or more UPNs/emails to assign across person columns, e.g.
    -People "ana@contoso.com","raj@contoso.com". Defaults to the signed-in user.

.PARAMETER Include
    Which list set to seed: Pm, Governance, or All (default).

.EXAMPLE
    .\Add-SampleData.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/ITGovernance" `
        -ClientId "0000..." -People "ana@contoso.com","raj@contoso.com"

.NOTES
    Adds rows; it does not clear existing ones. Re-running creates duplicates.
    This script has not been run against a live tenant -- review it before use.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $SiteUrl,

    [Parameter(Mandatory = $true)]
    [string] $ClientId,

    [string[]] $People,

    [ValidateSet('Pm', 'Governance', 'All')]
    [string] $Include = 'All'
)

$ErrorActionPreference = 'Stop'
Import-Module PnP.PowerShell

Write-Host "Connecting to $SiteUrl ..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

if (-not $People -or $People.Count -eq 0) {
    try {
        $me = Get-PnPProperty -ClientObject (Get-PnPContext).Web -Property CurrentUser
        $People = @($me.LoginName -replace '^i:0#\.f\|membership\|', '')
        Write-Host "No -People given; assigning everything to $($People[0])" -ForegroundColor DarkGray
    }
    catch {
        throw "Couldn't determine the signed-in user ($($_.Exception.Message)). Re-run with -People, e.g. -People 'you@contoso.com'."
    }
}

# Round-robin a person across rows so charts have more than one bar.
$script:personIndex = 0
function Next-Person {
    $person = $People[$script:personIndex % $People.Count]
    $script:personIndex++
    return $person
}

$today = (Get-Date).Date
function Days { param([int] $Offset) return $today.AddDays($Offset) }

function Add-Row {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string] $List,
        [Parameter(Mandatory = $true)][hashtable] $Values
    )
    if (-not $PSCmdlet.ShouldProcess($List, "Add item '$($Values['Title'])'")) { return }
    Add-PnPListItem -List $List -Values $Values | Out-Null
    Write-Host "    + $($Values['Title'])" -ForegroundColor DarkGray
}

if ($Include -in @('Pm', 'All')) {
    Write-Host "`nSeeding Tasks..." -ForegroundColor Green
    $tasks = @(
        @{ Title = 'Define project charter';    Status = 'Done';        Start = -60; Due = -51; Pct = 1.0; Priority = 'High' },
        @{ Title = 'Stakeholder kickoff';       Status = 'Done';        Start = -51; Due = -47; Pct = 1.0; Priority = 'High' },
        @{ Title = 'Requirements gathering';    Status = 'In Progress'; Start = -47; Due = -29; Pct = 0.8; Priority = 'High' },
        @{ Title = 'Site migration plan';       Status = 'In Progress'; Start = -41; Due = -15; Pct = 0.5; Priority = 'Medium' },
        @{ Title = 'Content inventory';         Status = 'In Progress'; Start = -36; Due = -20; Pct = 0.6; Priority = 'Medium' },
        @{ Title = 'Permissions mapping';       Status = 'Not Started'; Start = -25; Due = -10; Pct = 0.0; Priority = 'Medium' },
        @{ Title = 'Pilot migration batch';     Status = 'Not Started'; Start = -15; Due = -5;  Pct = 0.0; Priority = 'High' },
        @{ Title = 'User training sessions';    Status = 'Not Started'; Start = -10; Due = 6;   Pct = 0.0; Priority = 'Low' },
        @{ Title = 'Cutover checklist';         Status = 'Not Started'; Start = -29; Due = -25; Pct = 0.0; Priority = 'High' },
        @{ Title = 'Post-migration validation'; Status = 'Not Started'; Start = 2;   Due = 11;  Pct = 0.0; Priority = 'Medium' }
    )
    foreach ($t in $tasks) {
        Add-Row -List 'Tasks' -Values @{
            Title           = $t.Title
            Status          = $t.Status
            AssignedTo      = (Next-Person)
            StartDate       = (Days $t.Start)
            DueDate         = (Days $t.Due)
            PercentComplete = $t.Pct
            Priority        = $t.Priority
        }
    }

    Write-Host "Seeding Risks..." -ForegroundColor Green
    $risks = @(
        @{ Title = 'Legacy list templates not supported'; Severity = 'High';   Status = 'Open';      Desc = 'Custom InfoPath forms have no direct SharePoint Online equivalent.' },
        @{ Title = 'Tenant storage quota';                Severity = 'Medium'; Status = 'Open';      Desc = 'Combined library size may exceed default site quota.' },
        @{ Title = 'Third-party workflow add-in';         Severity = 'High';   Status = 'Open';      Desc = 'Nintex workflows need to be rebuilt in Power Automate.' },
        @{ Title = 'User adoption resistance';            Severity = 'Low';    Status = 'Mitigated'; Desc = 'Early training sessions well received in pilot group.' },
        @{ Title = 'Downtime during cutover';             Severity = 'Medium'; Status = 'Open';      Desc = 'Cutover window needs off-hours scheduling.' }
    )
    foreach ($r in $risks) {
        Add-Row -List 'Risks' -Values @{
            Title       = $r.Title
            Severity    = $r.Severity
            Owner       = (Next-Person)
            Status      = $r.Status
            Description = $r.Desc
        }
    }
}

if ($Include -in @('Governance', 'All')) {
    Write-Host "`nSeeding Policies..." -ForegroundColor Green
    $policies = @(
        @{ Title = 'Information Security Policy';   Cat = 'Security';     Status = 'Approved';     Ver = '3.2'; Last = -171; Next = 194 },
        @{ Title = 'Acceptable Use Policy';         Cat = 'Security';     Status = 'Approved';     Ver = '2.1'; Last = -299; Next = 66 },
        @{ Title = 'Data Classification Standard';  Cat = 'Data';         Status = 'Under Review'; Ver = '1.8'; Last = -436; Next = -71 },
        @{ Title = 'Data Retention Schedule';       Cat = 'Data';         Status = 'Approved';     Ver = '4.0'; Last = -227; Next = 138 },
        @{ Title = 'Change Management Policy';      Cat = 'Operations';   Status = 'Approved';     Ver = '2.4'; Last = -363; Next = 2 },
        @{ Title = 'Incident Response Plan';        Cat = 'Operations';   Status = 'Under Review'; Ver = '3.0'; Last = -457; Next = -92 },
        @{ Title = 'Third-Party Risk Standard';     Cat = 'Vendor';       Status = 'Approved';     Ver = '1.3'; Last = -203; Next = 162 },
        @{ Title = 'Cloud Hosting Standard';        Cat = 'Architecture'; Status = 'Draft';        Ver = '0.9'; Last = $null; Next = 32 },
        @{ Title = 'Access Control Standard';       Cat = 'Security';     Status = 'Approved';     Ver = '2.7'; Last = -381; Next = -16 },
        @{ Title = 'Business Continuity Policy';    Cat = 'Operations';   Status = 'Expired';      Ver = '1.5'; Last = -879; Next = -515 },
        @{ Title = 'AI Usage Guidelines';           Cat = 'Architecture'; Status = 'Draft';        Ver = '0.4'; Last = $null; Next = 93 },
        @{ Title = 'Software Licensing Policy';     Cat = 'Vendor';       Status = 'Approved';     Ver = '1.1'; Last = -312; Next = 53 }
    )
    foreach ($p in $policies) {
        $values = @{
            Title      = $p.Title
            Category   = $p.Cat
            Owner      = (Next-Person)
            Status     = $p.Status
            Version    = $p.Ver
            NextReview = (Days $p.Next)
        }
        if ($null -ne $p.Last) { $values['LastReviewed'] = (Days $p.Last) }
        Add-Row -List 'Policies' -Values $values
    }

    Write-Host "Seeding Controls..." -ForegroundColor Green
    $controls = @(
        @{ Id = 'A.5.1';    Title = 'Policies for information security'; Fw = 'ISO 27001'; Status = 'Compliant';     Assessed = -142 },
        @{ Id = 'A.8.2';    Title = 'Privileged access rights';          Fw = 'ISO 27001'; Status = 'Partial';       Assessed = -142 },
        @{ Id = 'A.8.16';   Title = 'Monitoring activities';             Fw = 'ISO 27001'; Status = 'Non-Compliant'; Assessed = -184 },
        @{ Id = 'A.5.30';   Title = 'ICT readiness for continuity';      Fw = 'ISO 27001'; Status = 'Non-Compliant'; Assessed = -269 },
        @{ Id = 'ID.AM-1';  Title = 'Physical devices inventoried';      Fw = 'NIST CSF';  Status = 'Compliant';     Assessed = -120 },
        @{ Id = 'PR.AC-4';  Title = 'Access permissions managed';        Fw = 'NIST CSF';  Status = 'Partial';       Assessed = -120 },
        @{ Id = 'DE.CM-1';  Title = 'Network monitored';                 Fw = 'NIST CSF';  Status = 'Compliant';     Assessed = -120 },
        @{ Id = 'RS.RP-1';  Title = 'Response plan executed';            Fw = 'NIST CSF';  Status = 'Not Assessed';  Assessed = $null },
        @{ Id = 'CC6.1';    Title = 'Logical access controls';           Fw = 'SOC 2';     Status = 'Compliant';     Assessed = -165 },
        @{ Id = 'CC7.2';    Title = 'System monitoring';                 Fw = 'SOC 2';     Status = 'Partial';       Assessed = -165 },
        @{ Id = 'CC8.1';    Title = 'Change management';                 Fw = 'SOC 2';     Status = 'Compliant';     Assessed = -165 },
        @{ Id = 'APO12';    Title = 'Managed risk';                      Fw = 'COBIT';     Status = 'Partial';       Assessed = -212 },
        @{ Id = 'BAI06';    Title = 'Managed IT changes';                Fw = 'COBIT';     Status = 'Compliant';     Assessed = -212 },
        @{ Id = 'DSS05';    Title = 'Managed security services';         Fw = 'COBIT';     Status = 'Not Assessed';  Assessed = $null }
    )
    foreach ($c in $controls) {
        $values = @{
            Title     = $c.Title
            ControlId = $c.Id
            Framework = $c.Fw
            Owner     = (Next-Person)
            Status    = $c.Status
        }
        if ($null -ne $c.Assessed) { $values['LastAssessed'] = (Days $c.Assessed) }
        Add-Row -List 'Controls' -Values $values
    }

    Write-Host "Seeding AuditFindings..." -ForegroundColor Green
    $findings = @(
        @{ Title = 'Privileged accounts lack MFA enforcement'; Sev = 'Critical'; Src = 'External Audit';  Status = 'In Remediation'; Raised = -137; Due = -46 },
        @{ Title = 'Log retention below 12-month requirement'; Sev = 'High';     Src = 'External Audit';  Status = 'Open';           Raised = -137; Due = -29 },
        @{ Title = 'DR test not performed in last 12 months';  Sev = 'High';     Src = 'Internal Audit';  Status = 'Open';           Raised = -191; Due = -61 },
        @{ Title = 'Orphaned accounts in legacy AD OU';        Sev = 'Medium';   Src = 'Internal Audit';  Status = 'In Remediation'; Raised = -178; Due = 31 },
        @{ Title = 'Vendor security reviews incomplete';       Sev = 'Medium';   Src = 'Self-Assessment'; Status = 'Open';           Raised = -110; Due = 62 },
        @{ Title = 'Change tickets missing rollback plans';    Sev = 'Medium';   Src = 'Internal Audit';  Status = 'Closed';         Raised = -295; Due = -182 },
        @{ Title = 'Security awareness below target';          Sev = 'Low';      Src = 'Self-Assessment'; Status = 'Open';           Raised = -90;  Due = 93 },
        @{ Title = 'Asset inventory missing cloud workloads';  Sev = 'High';     Src = 'Internal Audit';  Status = 'Closed';         Raised = -350; Due = -183 },
        @{ Title = 'Encryption not applied to backups';        Sev = 'Critical'; Src = 'Internal Audit';  Status = 'Open';           Raised = -59;  Due = -10 }
    )
    foreach ($f in $findings) {
        Add-Row -List 'AuditFindings' -Values @{
            Title      = $f.Title
            Severity   = $f.Sev
            Source     = $f.Src
            Owner      = (Next-Person)
            Status     = $f.Status
            RaisedDate = (Days $f.Raised)
            DueDate    = (Days $f.Due)
        }
    }

    Write-Host "Seeding RiskRegister..." -ForegroundColor Green
    $govRisks = @(
        @{ Title = 'Ransomware impacting core file services'; Cat = 'Security';    Treat = 'Mitigate'; Status = 'Open';      L = 3; I = 5 },
        @{ Title = 'Unsupported legacy ERP platform';         Cat = 'Technology';  Treat = 'Mitigate'; Status = 'Open';      L = 4; I = 4 },
        @{ Title = 'Key person dependency in network team';   Cat = 'Operational'; Treat = 'Mitigate'; Status = 'Open';      L = 4; I = 3 },
        @{ Title = 'Cloud cost overrun vs. approved budget';  Cat = 'Financial';   Treat = 'Accept';   Status = 'Monitored'; L = 3; I = 2 },
        @{ Title = 'Data residency breach in SaaS tooling';   Cat = 'Compliance';  Treat = 'Transfer'; Status = 'Open';      L = 2; I = 5 },
        @{ Title = 'Shadow IT procurement outside governance';Cat = 'Compliance';  Treat = 'Mitigate'; Status = 'Open';      L = 4; I = 2 },
        @{ Title = 'Single-region hosting for tier-1 apps';   Cat = 'Technology';  Treat = 'Mitigate'; Status = 'Open';      L = 2; I = 4 },
        @{ Title = 'Third-party breach via integration partner'; Cat = 'Vendor';   Treat = 'Transfer'; Status = 'Closed';    L = 2; I = 4 }
    )
    foreach ($r in $govRisks) {
        Add-Row -List 'RiskRegister' -Values @{
            Title      = $r.Title
            Category   = $r.Cat
            Owner      = (Next-Person)
            Treatment  = $r.Treat
            Status     = $r.Status
            Likelihood = $r.L
            Impact     = $r.I
        }
    }

    Write-Host "Seeding PolicyExceptions..." -ForegroundColor Green
    $exceptions = @(
        @{ Title = 'Legacy SFTP without MFA';              Ref = 'Access Control Standard';      Status = 'Active';  Expiry = 31 },
        @{ Title = 'Local admin rights for design team';   Ref = 'Acceptable Use Policy';        Status = 'Active';  Expiry = 123 },
        @{ Title = 'Unencrypted archive tapes in transit'; Ref = 'Data Classification Standard'; Status = 'Active';  Expiry = 16 },
        @{ Title = 'Direct DB access for reporting tool';  Ref = 'Access Control Standard';      Status = 'Expired'; Expiry = -121 },
        @{ Title = 'Extended patch window for ERP';        Ref = 'Change Management Policy';     Status = 'Pending'; Expiry = 154 },
        @{ Title = 'Non-standard VPN client';              Ref = 'Information Security Policy';  Status = 'Active';  Expiry = 183 }
    )
    foreach ($x in $exceptions) {
        Add-Row -List 'PolicyExceptions' -Values @{
            Title       = $x.Title
            PolicyRef   = $x.Ref
            RequestedBy = (Next-Person)
            Approver    = (Next-Person)
            Status      = $x.Status
            ExpiryDate  = (Days $x.Expiry)
        }
    }
}

Write-Host "`nDone. The dashboards should now show the same figures as demo mode." -ForegroundColor Yellow
Disconnect-PnPOnline
