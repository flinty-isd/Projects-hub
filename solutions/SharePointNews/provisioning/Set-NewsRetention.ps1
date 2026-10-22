<#
.SYNOPSIS
    Applies the 7-year retention decision to the HPUK News and Other News sites.

.DESCRIPTION
    Creates a Microsoft Purview retention policy covering both news sites:
    every page, attachment, archived notice and log item is retained for
    7 years (2,557 days) from when it was created. Nobody can permanently
    delete content inside that period: deleted items stay recoverable in the
    Preservation Hold library.

    By default nothing is deleted automatically when the 7 years end. Use
    -DeleteAfterRetention only if the records owner confirms that content
    should be removed at the end of the period.

    News expiry (flow C1) never deletes anything: it only takes posts out of
    the current news views.

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
    [switch] $DeleteAfterRetention
)

$ErrorActionPreference = 'Stop'
$days = 2557   # 7 years including leap days

$policy = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $policy) {
    New-RetentionCompliancePolicy -Name $PolicyName `
        -Comment 'News and notices retention: 7 years from creation (Communications decision).' `
        -SharePointLocation $HPUKNewsUrl, $OtherNewsUrl | Out-Null
    Write-Output "+ policy $PolicyName"
} else {
    Set-RetentionCompliancePolicy -Identity $PolicyName -AddSharePointLocation $HPUKNewsUrl, $OtherNewsUrl `
        -ErrorAction SilentlyContinue | Out-Null
    Write-Output "= policy $PolicyName exists; locations checked"
}

if (-not (Get-RetentionComplianceRule -Policy $PolicyName -ErrorAction SilentlyContinue)) {
    $action = if ($DeleteAfterRetention) { 'KeepAndDelete' } else { 'Keep' }
    New-RetentionComplianceRule -Name "$PolicyName rule" -Policy $PolicyName `
        -RetentionDuration $days -RetentionComplianceAction $action -ExpirationDateOption CreationAgeInDays | Out-Null
    Write-Output "+ rule: $action for $days days from creation"
}

Write-Output 'Policy distribution to the sites can take up to 7 days. Check its status in the Purview portal.'
