<#
.SYNOPSIS
    Applies the Hutchison Ports look to the SharePoint governance site.

.DESCRIPTION
    Uses only native SharePoint Online features, no SPFx or custom script:

      * registers the 'Hutchison Ports' tenant theme (theme/hutchison-ports-theme.json)
        and applies it to the governance site
      * sets column formatting on every governance Status column
        (column-formats/*.json), so each status shows as a good / bad / info /
        neutral outcome, in the colours of the process diagrams

    Run interactively by a SharePoint Administrator (tenant themes need the
    admin centre). Safe to re-run: the theme is overwritten and each column's
    formatting replaced. Regenerate the column formats first if
    status-map.json changed:
        python solutions/SharePointGovernance/tools/build_formatters.py

.NOTES
    Requires PnP.PowerShell 2.x on PowerShell 7.2+, and an Entra app
    registration that allows interactive sign-in (pass its client ID).
#>
param(
    [Parameter(Mandatory)] [string] $TenantName,          # e.g. contoso
    [Parameter(Mandatory)] [string] $ClientId,
    [Parameter(Mandatory)] [string] $GovernanceSitePath,  # IT Enterprise Governance site, e.g. /sites/ITEnterpriseGovernance
    [switch] $SkipTheme
)

$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$adminUrl = "https://$TenantName-admin.sharepoint.com"
$siteUrl = "https://$TenantName.sharepoint.com$GovernanceSitePath"

# --- Tenant theme -------------------------------------------------------------
if (-not $SkipTheme) {
    $theme = Get-Content -Raw (Join-Path $here 'theme/hutchison-ports-theme.json') | ConvertFrom-Json
    $palette = @{}
    $theme.palette.PSObject.Properties | ForEach-Object { $palette[$_.Name] = $_.Value }

    $admin = Connect-PnPOnline -Url $adminUrl -ClientId $ClientId -Interactive -ReturnConnection
    Add-PnPTenantTheme -Identity $theme.name -Palette $palette -IsInverted $theme.isInverted `
        -Overwrite -Connection $admin
    Set-PnPWebTheme -Theme $theme.name -WebUrl $siteUrl -Connection $admin
    Write-Output "Theme '$($theme.name)' applied to $siteUrl"
}

# --- Status column formatting -------------------------------------------------
$map = Get-Content -Raw (Join-Path $here 'status-map.json') | ConvertFrom-Json
$site = Connect-PnPOnline -Url $siteUrl -ClientId $ClientId -Interactive -ReturnConnection

foreach ($col in $map.columns) {
    $slug = { param($t) ($t.ToLower() -replace '[^a-z0-9]+', '-').Trim('-') }
    $file = Join-Path $here "column-formats/$(& $slug $col.list)-$(& $slug $col.field).json"
    $json = Get-Content -Raw $file
    Set-PnPField -List $col.list -Identity $col.field -Values @{ CustomFormatter = $json } `
        -Connection $site | Out-Null
    Write-Output "Formatted $($col.list) / $($col.field)"
}
