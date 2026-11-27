<#
.SYNOPSIS
    Checks, and with -Apply sets, the 7-year retention decision for the HPUK
    News and Other News sites.

.DESCRIPTION
    Intended state: one Microsoft Purview retention policy covering both news
    sites, with one rule that retains every page, attachment, archived notice
    and log item for 7 years (2,557 days) from when it was created. Nobody can
    permanently delete content inside that period: deleted items stay
    recoverable in the Preservation Hold library. By default nothing is
    deleted when the 7 years end (action Keep). KeepAndDelete is used only
    with -DeleteAfterRetention, which the records owner must have approved.

    The script compares the tenant with that intended state and prints a
    plan: what matches, what is missing and what differs. Without -Apply it
    changes nothing and exits with an error if anything differs, so it can be
    run as a check at any time.

    With -Apply it creates what is missing and adds missing site locations.
    It never changes an existing rule's duration, action or start date on its
    own: a rule that differs is reported, and changed only if you also pass
    -UpdateExistingRule. Every change needs -ApprovalReference (the records
    owner's decision reference, e.g. a Decision Log ID), which is written to
    the policy comment.

    After any change it reads the policy back and fails if a site is missing,
    a site is excluded, or distribution reports an error. Distribution can take
    up to 7 days: run again without -Apply until Distribution shows Success.

    News expiry (flow C1) never deletes anything: it moves expired posts to the
    News archive (ordinary pages, still readable).

.EXAMPLE
    # Check only (safe at any time)
    .\Set-NewsRetention.ps1 -HPUKNewsUrl $hpuk -OtherNewsUrl $other

.EXAMPLE
    # Create the policy as approved
    .\Set-NewsRetention.ps1 -HPUKNewsUrl $hpuk -OtherNewsUrl $other -Apply -ApprovalReference DL-NEWS-07

.NOTES
    Run as a Purview Compliance Administrator with ExchangeOnlineManagement 3.x:
      Connect-IPPSSession -UserPrincipalName <admin UPN>
    Migrated Notices Archive items count their 7 years from the Created date
    the migration tool preserves; check it carried over the original dates.
    Not yet run against a tenant.
#>
param(
    [Parameter(Mandatory)] [string] $HPUKNewsUrl,
    [Parameter(Mandatory)] [string] $OtherNewsUrl,
    [string] $PolicyName = 'HPUK News - retain 7 years',
    [switch] $DeleteAfterRetention,
    [switch] $Apply,
    [switch] $UpdateExistingRule,
    [string] $ApprovalReference
)

$ErrorActionPreference = 'Stop'
$days = 2557   # 7 years including leap days
$wantAction = if ($DeleteAfterRetention) { 'KeepAndDelete' } else { 'Keep' }
$wantStart = 'CreationAgeInDays'
$sites = @($HPUKNewsUrl.TrimEnd('/'), $OtherNewsUrl.TrimEnd('/'))
$plan = [System.Collections.Generic.List[string]]::new()
$problems = [System.Collections.Generic.List[string]]::new()

if ($Apply -and [string]::IsNullOrWhiteSpace($ApprovalReference)) {
    throw '-Apply needs -ApprovalReference: the records owner''s decision reference for this retention basis.'
}
function Norm([string] $u) { $u.TrimEnd('/').ToLowerInvariant() }
function Get-Policy { Get-RetentionCompliancePolicy -Identity $PolicyName -DistributionDetail -ErrorAction SilentlyContinue }

# ---- Compare ------------------------------------------------------------------
$policy = Get-Policy
$rules = @()
if (-not $policy) {
    $plan.Add("CREATE policy '$PolicyName' for: $($sites -join ', ')")
} else {
    $have = @($policy.SharePointLocation | ForEach-Object { Norm "$($_.Name)" })
    $excluded = @($policy.SharePointLocationException | ForEach-Object { Norm "$($_.Name)" })
    foreach ($s in $sites) {
        if ($excluded -contains (Norm $s)) { $problems.Add("Site is EXCLUDED from the policy: $s (remove the exclusion by hand after checking why it was added)") }
        if ($have -notcontains (Norm $s) -and $have -notcontains 'all') { $plan.Add("ADD location $s") }
        else { Write-Output "= location $s" }
    }
    $rules = @(Get-RetentionComplianceRule -Policy $PolicyName)
}

if ($rules.Count -gt 1) {
    $problems.Add("Policy has $($rules.Count) rules; expected one. Review them in Purview: $($rules.Name -join ', ')")
} elseif ($rules.Count -eq 1) {
    $r = $rules[0]
    $diff = @()
    if ("$($r.RetentionDuration)" -ne "$days")         { $diff += "duration $($r.RetentionDuration) (want $days)" }
    if ("$($r.RetentionComplianceAction)" -ne $wantAction) { $diff += "action $($r.RetentionComplianceAction) (want $wantAction)" }
    if ("$($r.ExpirationDateOption)" -ne $wantStart)   { $diff += "start $($r.ExpirationDateOption) (want $wantStart)" }
    if ($diff) {
        $msg = "Rule '$($r.Name)' differs: $($diff -join '; ')"
        if ($UpdateExistingRule) { $plan.Add("UPDATE $msg") } else { $problems.Add("$msg. Not changed: rerun with -UpdateExistingRule once the records owner approves") }
    } else { Write-Output "= rule '$($r.Name)': $wantAction for $days days from creation" }
} else {
    $plan.Add("CREATE rule: $wantAction for $days days from creation")
}

Write-Output ''
Write-Output 'Plan:'
if ($plan.Count -eq 0) { Write-Output '  nothing to change' } else { $plan | ForEach-Object { Write-Output "  $_" } }
if ($problems.Count) { Write-Output 'Problems:'; $problems | ForEach-Object { Write-Output "  ! $_" } }

if (-not $Apply) {
    if ($plan.Count -or $problems.Count) { throw 'The tenant does not match the intended retention. Nothing was changed (check only).' }
} else {
    if ($problems.Count) { throw 'Not applied: resolve the problems above first. Nothing was changed.' }
    $comment = "News and notices retention: 7 years from creation. Approved: $ApprovalReference."
    if (-not $policy) {
        New-RetentionCompliancePolicy -Name $PolicyName -Comment $comment -SharePointLocation $sites | Out-Null
        Write-Output "+ policy $PolicyName"
    } else {
        $missing = @($sites | Where-Object { $p = Norm $_; -not (@($policy.SharePointLocation | ForEach-Object { Norm "$($_.Name)" }) -contains $p) })
        if ($missing) {
            Set-RetentionCompliancePolicy -Identity $PolicyName -AddSharePointLocation $missing -Comment $comment | Out-Null
            Write-Output "+ locations $($missing -join ', ')"
        }
    }
    if ($rules.Count -eq 0) {
        New-RetentionComplianceRule -Name "$PolicyName rule" -Policy $PolicyName `
            -RetentionDuration $days -RetentionComplianceAction $wantAction -ExpirationDateOption $wantStart | Out-Null
        Write-Output "+ rule: $wantAction for $days days from creation"
    } elseif ($UpdateExistingRule -and $plan -match '^UPDATE') {
        Set-RetentionComplianceRule -Identity $rules[0].Name `
            -RetentionDuration $days -RetentionComplianceAction $wantAction -ExpirationDateOption $wantStart | Out-Null
        Write-Output "~ rule '$($rules[0].Name)' set to $wantAction for $days days from creation"
    }
}

# ---- Read back ---------------------------------------------------------------
$policy = Get-Policy
if (-not $policy) { throw "Read-back failed: policy '$PolicyName' not found." }
$have = @($policy.SharePointLocation | ForEach-Object { Norm "$($_.Name)" })
foreach ($s in $sites) {
    if ($have -notcontains (Norm $s) -and $have -notcontains 'all') { throw "Read-back: $s is not in the policy." }
}
$rule = @(Get-RetentionComplianceRule -Policy $PolicyName)
if ($rule.Count -ne 1 -or "$($rule[0].RetentionDuration)" -ne "$days" -or "$($rule[0].RetentionComplianceAction)" -ne $wantAction) {
    throw 'Read-back: the rule does not match the intended duration and action.'
}
Write-Output ''
Write-Output "Distribution: $($policy.DistributionStatus)"
if ("$($policy.DistributionStatus)" -match 'Error|Fail') {
    $policy.DistributionResults | ForEach-Object { Write-Output "  ! $_" }
    throw 'Distribution reports an error. Fix it in Purview (Retry distribution) and run this check again.'
}
if ("$($policy.DistributionStatus)" -ne 'Success') {
    Write-Output 'Distribution is still pending (up to 7 days). Run this script again without -Apply until it shows Success, then test a deletion (Testing: Retention).'
}
