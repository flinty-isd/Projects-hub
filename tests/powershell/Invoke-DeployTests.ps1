<#
.SYNOPSIS
    Runs the provisioning and formatting scripts against a stubbed PnP.PowerShell
    and asserts what they did.

.DESCRIPTION
    There is no SharePoint tenant in CI, so ./modules/PnP.PowerShell stands in for
    the real module: it records every cmdlet call and keeps enough state (lists,
    fields, views, pages) for the scripts' "create it only if missing" branches to
    take both paths.

    That is enough to catch the failures that actually bite on a deploy -- a script
    that doesn't parse, a field created on a list that doesn't exist yet, formatting
    aimed at a column nobody provisioned, malformed JSON handed to SharePoint, or a
    re-run that duplicates instead of no-opping.

    What it cannot catch: anything about the real Graph/CSOM API surface. Parameter
    names that don't exist on the real cmdlets, permissions, throttling, and the
    List web part property shape all still need a live tenant.

.PARAMETER SyntaxOnly
    Parse every .ps1 in the repo and stop. No script execution.

.EXAMPLE
    pwsh ./tests/powershell/Invoke-DeployTests.ps1
#>

[CmdletBinding()]
param(
    [switch] $SyntaxOnly
)

$ErrorActionPreference = 'Stop'

$here     = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $here '../..')

$script:Failures = 0
$script:Checks   = 0

function Assert-That {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)] $Actual,
        [Parameter(Mandatory = $true)] $Expected
    )
    $script:Checks++
    if ($Actual -eq $Expected) {
        Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor Green
    }
    else {
        $script:Failures++
        Write-Host ("  FAIL  {0}: expected '{1}', got '{2}'" -f $Name, $Expected, $Actual) -ForegroundColor Red
    }
}

function Get-Calls {
    param([int] $Since, [string] $Cmdlet)
    if ($global:PnPCalls.Count -le $Since) { return @() }
    $slice = $global:PnPCalls[$Since..($global:PnPCalls.Count - 1)]
    if ($Cmdlet) { return @($slice | Where-Object { $_.Cmdlet -eq $Cmdlet }) }
    return @($slice)
}

# ---------------------------------------------------------------- syntax ----

Write-Host "`n== Syntax ==" -ForegroundColor Cyan
$scripts = Get-ChildItem -Path $repoRoot -Filter *.ps1 -Recurse |
           Where-Object { $_.FullName -notlike "*$([IO.Path]::DirectorySeparatorChar)tests$([IO.Path]::DirectorySeparatorChar)*" }
$syntaxErrors = 0
foreach ($s in $scripts) {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($s.FullName, [ref]$null, [ref]$errors) | Out-Null
    if ($errors.Count) {
        $syntaxErrors++
        Write-Host "  FAIL  $($s.Name)" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "        line $($_.Extent.StartLineNumber): $($_.Message)" }
    }
}
Assert-That 'all scripts parse' $syntaxErrors 0

if ($SyntaxOnly) {
    Write-Host "`nSyntax only. $script:Checks checks, $script:Failures failed."
    exit ($script:Failures -gt 0 ? 1 : 0)
}

# ------------------------------------------------------------------ setup ----

$env:PSModulePath = (Join-Path $here 'modules') + [IO.Path]::PathSeparator + $env:PSModulePath
Import-Module PnP.PowerShell -Force

$url = 'https://contoso.sharepoint.com/sites/Dashboards'
$id  = '00000000-0000-0000-0000-000000000000'

$expectedLists = @('Tasks','Risks','Policies','Controls','AuditFindings','RiskRegister','PolicyExceptions')

# ----------------------------------------------------- provision the lists ----

Write-Host "`n== Provision-SharePointLists.ps1 ==" -ForegroundColor Cyan
$mark = $global:PnPCalls.Count
& (Join-Path $repoRoot 'provisioning/Provision-SharePointLists.ps1') -SiteUrl $url -ClientId $id 6>$null | Out-Null

Assert-That 'lists created' (Get-Calls $mark 'New-PnPList').Count $expectedLists.Count
foreach ($l in $expectedLists) {
    Assert-That "list '$l' exists" $global:PnPLists.ContainsKey($l) $true
}

# Internal names must never contain a space -- a column created as "Assigned To"
# becomes Assigned_x0020_To, which every client would then read back as empty.
$spaced = @(Get-Calls $mark 'Add-PnPField' | Where-Object { $_.Data.InternalName -match '\s' })
Assert-That 'no spaces in internal names' $spaced.Count 0

# Columns the dashboards and formatters depend on by name.
foreach ($pair in @(
    @{ List = 'Tasks';            Field = 'AssignedTo' },
    @{ List = 'Tasks';            Field = 'PercentComplete' },
    @{ List = 'Tasks';            Field = 'DueDate' },
    @{ List = 'RiskRegister';     Field = 'Likelihood' },
    @{ List = 'RiskRegister';     Field = 'Impact' },
    @{ List = 'AuditFindings';    Field = 'DueDate' },
    @{ List = 'Policies';         Field = 'NextReview' },
    @{ List = 'PolicyExceptions'; Field = 'ExpiryDate' }
)) {
    Assert-That "$($pair.List).$($pair.Field) provisioned" `
        $global:PnPLists[$pair.List].Fields.ContainsKey($pair.Field) $true
}

# Choice values the KPI logic special-cases.
$controlStatus = (Get-Calls $mark 'Add-PnPField' |
    Where-Object { $_.Data.List -eq 'Controls' -and $_.Data.InternalName -eq 'Status' }).Data.Choices
Assert-That "Controls.Status offers 'Not Assessed'" ($controlStatus -contains 'Not Assessed') $true
Assert-That "Controls.Status offers 'Compliant'"    ($controlStatus -contains 'Compliant')    $true

# ------------------------------------------------------------- formatting ----

Write-Host "`n== Apply-Formatting.ps1 ==" -ForegroundColor Cyan
$mark = $global:PnPCalls.Count
& (Join-Path $repoRoot 'sharepoint-modern/Apply-Formatting.ps1') -SiteUrl $url -ClientId $id 6>$null | Out-Null

$formatterFiles = @(Get-ChildItem -Path (Join-Path $repoRoot 'sharepoint-modern/formatting') -Filter *.json)
$columnFmt = Get-Calls $mark 'Set-PnPField'
$viewFmt   = Get-Calls $mark 'Set-PnPView'

Assert-That 'every formatter file applied' ($columnFmt.Count + $viewFmt.Count) $formatterFiles.Count
Assert-That 'RiskScore calculated column created' (Get-Calls $mark 'Add-PnPFieldFromXml').Count 1

# Formatting silently skips a column that was never provisioned, so an
# unexplained shortfall above would be a real mismatch between the two folders.
$badJson = 0
foreach ($c in @($columnFmt) + @($viewFmt)) {
    $json = $c.Data.Values['CustomFormatter']
    if (-not $json) { $badJson++; continue }
    try { $null = $json | ConvertFrom-Json } catch { $badJson++ }
}
Assert-That 'all formatter payloads are valid JSON' $badJson 0

# ------------------------------------------------------------------ pages ----

Write-Host "`n== Provision-ModernPages.ps1 ==" -ForegroundColor Cyan
$mark = $global:PnPCalls.Count
& (Join-Path $repoRoot 'sharepoint-modern/Provision-ModernPages.ps1') -SiteUrl $url -ClientId $id -Publish 6>$null | Out-Null

Assert-That 'pages created'    (Get-Calls $mark 'Add-PnPPage').Count 2
Assert-That 'list web parts'   (Get-Calls $mark 'Add-PnPPageWebPart').Count 7
Assert-That 'pages published'  @(Get-Calls $mark 'Set-PnPPage' | Where-Object { $_.Data.Publish }).Count 2

$unresolved = @(Get-Calls $mark 'Add-PnPPageWebPart' | Where-Object { -not $_.Data.Properties.selectedListId })
Assert-That 'every web part bound to a list' $unresolved.Count 0

# ------------------------------------------------------------ sample data ----

Write-Host "`n== Add-SampleData.ps1 ==" -ForegroundColor Cyan
$mark = $global:PnPCalls.Count
& (Join-Path $repoRoot 'provisioning/Add-SampleData.ps1') -SiteUrl $url -ClientId $id -People 'ana@contoso.com' 6>$null | Out-Null

$rows = Get-Calls $mark 'Add-PnPListItem'
Assert-That 'sample rows seeded' ($rows.Count -gt 0) $true
foreach ($l in $expectedLists) {
    Assert-That "rows seeded into $l" (@($rows | Where-Object { $_.Data.List -eq $l }).Count -gt 0) $true
}

# PercentComplete is stored 0-1, not 0-100. Getting this wrong makes the
# progress bars disagree with every other surface.
$outOfRange = @($rows |
    Where-Object { $_.Data.List -eq 'Tasks' -and $null -ne $_.Data.Values['PercentComplete'] } |
    Where-Object { [double]$_.Data.Values['PercentComplete'] -gt 1 })
Assert-That 'PercentComplete values are 0-1' $outOfRange.Count 0

# Likelihood and Impact drive the risk score; 1-5 each.
$badScale = @($rows |
    Where-Object { $_.Data.List -eq 'RiskRegister' } |
    Where-Object {
        [int]$_.Data.Values['Likelihood'] -lt 1 -or [int]$_.Data.Values['Likelihood'] -gt 5 -or
        [int]$_.Data.Values['Impact']     -lt 1 -or [int]$_.Data.Values['Impact']     -gt 5
    })
Assert-That 'Likelihood/Impact within 1-5' $badScale.Count 0

# ------------------------------------------------------------ idempotency ----

Write-Host "`n== Re-run is a no-op ==" -ForegroundColor Cyan
$mark = $global:PnPCalls.Count
& (Join-Path $repoRoot 'provisioning/Provision-SharePointLists.ps1') -SiteUrl $url -ClientId $id 6>$null | Out-Null
Assert-That 'no lists recreated'  (Get-Calls $mark 'New-PnPList').Count  0
Assert-That 'no fields recreated' (Get-Calls $mark 'Add-PnPField').Count 0

$mark = $global:PnPCalls.Count
& (Join-Path $repoRoot 'sharepoint-modern/Apply-Formatting.ps1') -SiteUrl $url -ClientId $id 6>$null | Out-Null
Assert-That 'RiskScore not recreated' (Get-Calls $mark 'Add-PnPFieldFromXml').Count 0

# ------------------------------------------------------------------- auth ----

Write-Host "`n== Certificate auth ==" -ForegroundColor Cyan
$mark = $global:PnPCalls.Count
& (Join-Path $repoRoot 'sharepoint-modern/Apply-Formatting.ps1') `
    -SiteUrl $url -ClientId $id -Tenant 'contoso.onmicrosoft.com' `
    -CertificateThumbprint 'ABC123' 6>$null | Out-Null
$connect = @(Get-Calls $mark 'Connect-PnPOnline')[0]
Assert-That 'certificate auth is not interactive' $connect.Data.Interactive $false

$mark = $global:PnPCalls.Count
& (Join-Path $repoRoot 'sharepoint-modern/Apply-Formatting.ps1') -SiteUrl $url -ClientId $id 6>$null | Out-Null
$connect = @(Get-Calls $mark 'Connect-PnPOnline')[0]
Assert-That 'default is interactive' $connect.Data.Interactive $true

# A thumbprint without a tenant is a misconfiguration worth failing loudly on.
$threw = $false
try {
    & (Join-Path $repoRoot 'sharepoint-modern/Apply-Formatting.ps1') `
        -SiteUrl $url -ClientId $id -CertificateThumbprint 'ABC123' 6>$null | Out-Null
}
catch { $threw = $true }
Assert-That 'certificate without -Tenant throws' $threw $true

# ----------------------------------------------------------------- result ----

Write-Host ""
if ($script:Failures -gt 0) {
    Write-Host "$script:Checks checks, $script:Failures FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "$script:Checks checks, all passed" -ForegroundColor Green
exit 0
