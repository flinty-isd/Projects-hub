<#
.SYNOPSIS
    Applies the JSON column and view formatting in ./formatting to the provisioned lists.

.DESCRIPTION
    Turns the plain lists created by ../provisioning/Provision-SharePointLists.ps1 into
    readable dashboards in place: coloured status pills, a progress bar for % complete,
    red past-due dates, an amber warning on exceptions expiring within 90 days, and a
    heat-coloured risk score.

    Also creates the RiskScore calculated column (Likelihood x Impact) on RiskRegister,
    since the heat badge formats that column. That is the only schema change this script
    makes; everything else only sets formatting.

    Re-runnable: formatting is overwritten each time, and the calculated column is only
    created if missing.

.PARAMETER SiteUrl
    Full URL of the site holding the lists.

.PARAMETER ClientId
    Entra ID application client ID for the interactive sign-in (PnP.PowerShell 2.x+).

.PARAMETER ViewName
    View to apply row formatting to. Defaults to "All Items".

.PARAMETER Include
    Which list set to format: Pm, Governance, or All (default).

.EXAMPLE
    .\Apply-Formatting.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/ITGovernance" `
        -ClientId "0000..." -Include Governance -WhatIf

.NOTES
    Not run against a live tenant -- review before use, and try -WhatIf first.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $SiteUrl,

    [Parameter(Mandatory = $true)]
    [string] $ClientId,

    [string] $ViewName = 'All Items',

    [ValidateSet('Pm', 'Governance', 'All')]
    [string] $Include = 'All'
)

$ErrorActionPreference = 'Stop'
Import-Module PnP.PowerShell

$formattingDir = Join-Path $PSScriptRoot 'formatting'
if (-not (Test-Path $formattingDir)) {
    throw "Formatting folder not found at $formattingDir"
}

# file prefix -> actual list title
$listForPrefix = @{
    'tasks'        = 'Tasks'
    'risks'        = 'Risks'
    'policies'     = 'Policies'
    'controls'     = 'Controls'
    'findings'     = 'AuditFindings'
    'riskregister' = 'RiskRegister'
    'exceptions'   = 'PolicyExceptions'
}

$pmPrefixes = @('tasks', 'risks')
$govPrefixes = @('policies', 'controls', 'findings', 'riskregister', 'exceptions')

$wanted = switch ($Include) {
    'Pm'         { $pmPrefixes }
    'Governance' { $govPrefixes }
    default      { $pmPrefixes + $govPrefixes }
}

Write-Host "Connecting to $SiteUrl ..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

function Ensure-RiskScoreColumn {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $existing = Get-PnPField -List 'RiskRegister' -Identity 'RiskScore' -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "  RiskScore column already exists - leaving it alone." -ForegroundColor DarkGray
        return
    }
    if (-not $PSCmdlet.ShouldProcess('RiskRegister.RiskScore', 'Create calculated column')) {
        return
    }

    Write-Host "  Creating calculated column RiskScore (Likelihood x Impact)..." -ForegroundColor Green
    $xml = @'
<Field Type="Calculated" DisplayName="Risk Score" Name="RiskScore" StaticName="RiskScore"
       ResultType="Number" Decimals="0">
  <Formula>=[Likelihood]*[Impact]</Formula>
  <FieldRefs>
    <FieldRef Name="Likelihood" />
    <FieldRef Name="Impact" />
  </FieldRefs>
</Field>
'@
    Add-PnPFieldFromXml -List 'RiskRegister' -FieldXml $xml | Out-Null
}

function Set-ColumnFormatting {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string] $ListTitle,
        [Parameter(Mandatory = $true)][string] $ColumnName,
        [Parameter(Mandatory = $true)][string] $Json
    )

    $field = Get-PnPField -List $ListTitle -Identity $ColumnName -ErrorAction SilentlyContinue
    if (-not $field) {
        Write-Warning "  $ListTitle.$ColumnName not found - skipping. Was the list provisioned?"
        return
    }
    if (-not $PSCmdlet.ShouldProcess("$ListTitle.$ColumnName", 'Apply column formatting')) {
        return
    }
    Write-Host "    column  $ColumnName" -ForegroundColor Cyan
    Set-PnPField -List $ListTitle -Identity $ColumnName -Values @{ CustomFormatter = $Json } | Out-Null
}

function Set-ViewFormatting {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string] $ListTitle,
        [Parameter(Mandatory = $true)][string] $Json
    )

    $view = Get-PnPView -List $ListTitle -Identity $ViewName -ErrorAction SilentlyContinue
    if (-not $view) {
        Write-Warning "  View '$ViewName' not found on $ListTitle - skipping row formatting."
        return
    }
    if (-not $PSCmdlet.ShouldProcess("$ListTitle/$ViewName", 'Apply view formatting')) {
        return
    }
    Write-Host "    view    $ViewName" -ForegroundColor Cyan
    Set-PnPView -List $ListTitle -Identity $ViewName -Values @{ CustomFormatter = $Json } | Out-Null
}

if ($wanted -contains 'riskregister') {
    Write-Host "`n=== Calculated columns ===" -ForegroundColor Yellow
    Ensure-RiskScoreColumn
}

Write-Host "`n=== Applying formatting ===" -ForegroundColor Yellow

foreach ($prefix in $wanted) {
    $listTitle = $listForPrefix[$prefix]
    $files = Get-ChildItem -Path $formattingDir -Filter "$prefix-*.json" | Sort-Object Name
    if (-not $files) {
        continue
    }

    Write-Host "  $listTitle" -ForegroundColor Green
    foreach ($file in $files) {
        # <prefix>-<Column>.json, or <prefix>-view.json for row formatting
        $target = ($file.BaseName -split '-', 2)[1]
        $json = Get-Content -Path $file.FullName -Raw

        if ($target -eq 'view') {
            Set-ViewFormatting -ListTitle $listTitle -Json $json
        }
        else {
            Set-ColumnFormatting -ListTitle $listTitle -ColumnName $target -Json $json
        }
    }
}

Write-Host "`nDone. Open each list to confirm the formatting renders as expected." -ForegroundColor Yellow
Disconnect-PnPOnline
