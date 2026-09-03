<#
.SYNOPSIS
    Creates modern SharePoint pages that surface the provisioned lists as dashboards.

.DESCRIPTION
    Builds two pages out of List web parts pointing at the lists created by
    ../provisioning/Provision-SharePointLists.ps1:

      PM-Dashboard.aspx   Tasks + Risks
      IT-Governance.aspx  Policies, Controls, Audit Findings, Risk Register, Exceptions

    The visual encoding (status pills, progress bars, red past-due dates, risk heat
    colours) comes from the JSON formatting applied by Apply-Formatting.ps1 -- run that
    first, or the pages will render as plain grey tables.

    Re-runnable: pass -Overwrite to rebuild pages that already exist.

.PARAMETER SiteUrl
    Full URL of the site holding the lists.

.PARAMETER ClientId
    Entra ID application client ID for the interactive sign-in (PnP.PowerShell 2.x+).

.PARAMETER Include
    Which page(s) to create: Pm, Governance, or All (default).

.PARAMETER Overwrite
    Recreate pages that already exist. Without this, existing pages are left alone.

.PARAMETER Publish
    Publish each page after building it. Without this they stay as drafts.

.EXAMPLE
    .\Provision-ModernPages.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/ITGovernance" `
        -ClientId "0000..." -Include Governance -Publish

.NOTES
    Not run against a live tenant -- review before use, and try -WhatIf first.

    The List web part's property names are the least stable part of this script: they
    have changed between SharePoint/PnP versions. If a web part lands on the page
    unconfigured, add one List web part by hand, then run
    (Get-PnPPage <name>).Controls | Select-Object -ExpandProperty PropertiesJson
    to see the shape your tenant expects, and adjust Get-ListWebPartProperties below.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $SiteUrl,

    [Parameter(Mandatory = $true)]
    [string] $ClientId,

    [ValidateSet('Pm', 'Governance', 'All')]
    [string] $Include = 'All',

    [switch] $Overwrite,

    [switch] $Publish
)

$ErrorActionPreference = 'Stop'
Import-Module PnP.PowerShell

Write-Host "Connecting to $SiteUrl ..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

function Get-ListWebPartProperties {
    param([Parameter(Mandatory = $true)][string] $ListTitle)

    $list = Get-PnPList -Identity $ListTitle -ErrorAction SilentlyContinue
    if (-not $list) {
        Write-Warning "  List '$ListTitle' not found - skipping its web part."
        return $null
    }

    return @{
        isDocumentLibrary  = $false
        selectedListId     = $list.Id.ToString()
        listTitle          = $list.Title
        webRelativeListUrl = $list.DefaultViewUrl
        hideCommandBar     = $false
    }
}

function New-DashboardPage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Title,
        [Parameter(Mandatory = $true)][string] $Intro,
        # ordered list of @{ Heading = '...'; List = '...' }
        [Parameter(Mandatory = $true)][object[]] $Sections
    )

    $existing = Get-PnPPage -Identity $Name -ErrorAction SilentlyContinue
    if ($existing -and -not $Overwrite) {
        Write-Host "  Page '$Name' already exists - skipping (pass -Overwrite to rebuild)." -ForegroundColor DarkGray
        return
    }
    if (-not $PSCmdlet.ShouldProcess($Name, 'Create modern page')) {
        return
    }

    Write-Host "  Building page '$Name'..." -ForegroundColor Green
    $page = Add-PnPPage -Name $Name -Title $Title -LayoutType Article -Force

    Add-PnPPageTextPart -Page $Name -Text $Intro | Out-Null

    foreach ($section in $Sections) {
        $properties = Get-ListWebPartProperties -ListTitle $section.List
        if (-not $properties) {
            continue
        }

        Write-Host "    section: $($section.Heading) -> $($section.List)" -ForegroundColor Cyan
        Add-PnPPageSection -Page $Name -SectionTemplate OneColumn | Out-Null
        Add-PnPPageTextPart -Page $Name -Text "<h2>$($section.Heading)</h2>" | Out-Null
        Add-PnPPageWebPart -Page $Name `
            -DefaultWebPartType List `
            -WebPartProperties $properties | Out-Null
    }

    if ($Publish) {
        Write-Host "    publishing" -ForegroundColor Cyan
        Set-PnPPage -Identity $Name -Publish | Out-Null
    }
}

if ($Include -in @('Pm', 'All')) {
    Write-Host "`n=== PM dashboard page ===" -ForegroundColor Yellow
    New-DashboardPage -Name 'PM-Dashboard' -Title 'PM Dashboard' `
        -Intro ('Project delivery status. Task rows turn red once past their due date. ' +
                'Use the column headers to filter and group; the views are formatted, so ' +
                'grouping by Status or Owner keeps the colour coding.') `
        -Sections @(
            @{ Heading = 'Tasks';            List = 'Tasks' },
            @{ Heading = 'Risks and issues'; List = 'Risks' }
        )
}

if ($Include -in @('Governance', 'All')) {
    Write-Host "`n=== IT Governance page ===" -ForegroundColor Yellow
    New-DashboardPage -Name 'IT-Governance' -Title 'IT Governance' `
        -Intro ('Policies, control compliance, audit findings, IT risk and exceptions. ' +
                'Amber marks something needing attention soon (a policy review due, an ' +
                'exception expiring within 90 days); red marks something already past due ' +
                'or scoring 15+ on the 5x5 risk grid.') `
        -Sections @(
            @{ Heading = 'Policies and standards'; List = 'Policies' },
            @{ Heading = 'Control compliance';     List = 'Controls' },
            @{ Heading = 'Audit findings';         List = 'AuditFindings' },
            @{ Heading = 'IT risk register';       List = 'RiskRegister' },
            @{ Heading = 'Policy exceptions';      List = 'PolicyExceptions' }
        )
}

Write-Host "`nDone." -ForegroundColor Yellow
Write-Host "Run Apply-Formatting.ps1 first (or now) so the lists render with colour." -ForegroundColor DarkGray
Write-Host "To add charts, edit a page and drop in a Quick chart web part pointed at a list." -ForegroundColor DarkGray

Disconnect-PnPOnline
