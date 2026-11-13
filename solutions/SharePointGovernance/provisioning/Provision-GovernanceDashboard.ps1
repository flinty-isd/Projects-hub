<#
.SYNOPSIS
    Builds the governance dashboard on the IT Enterprise Governance site.

.DESCRIPTION
    Reads sharepoint/dashboard.json and sharepoint/status-format.json and:
      * adds a filtered view to each governance list for every dashboard panel
        (Needs action, Ending soon, Ownership gaps, External sharing on, ...)
      * formats the Status columns (and Site Register's External sharing) as
        outcome badges: green good, red bad, blue info, with the words always
        shown
      * creates and publishes Governance-Dashboard.aspx: an intro, the panels
        as List web parts two to a row, and links to the SharePoint Advanced
        Management policies and reports

    Standard pages, views, list web parts and JSON column formatting only: no
    custom script (G-02) and no embedded HTML (G-06). Safe to re-run: existing
    views are left as they are (use -RefreshViews to rebuild them), and the page
    is rebuilt only with -RefreshPage.

.NOTES
    Requires PnP.PowerShell 2.x. Run as a site owner of the governance site, or
    with an app registration that has Sites.FullControl.All. The lists in
    sharepoint/list-schema.json must already exist.
    Not yet run against a tenant: run it on a test copy of the site first.
#>
param(
    [Parameter(Mandatory)] [string] $GovernanceSiteUrl,   # e.g. https://hphneu.sharepoint.com/sites/hpuk-pof-it-enterprisegovernance
    [string] $ClientId,
    [string] $Tenant,
    [string] $Thumbprint,
    [switch] $Interactive,
    [switch] $RefreshViews,
    [switch] $RefreshPage
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dash = Get-Content (Join-Path $root 'sharepoint/dashboard.json') -Raw | ConvertFrom-Json
$statusFormat = Get-Content (Join-Path $root 'sharepoint/status-format.json') -Raw

$conn = if ($Interactive) { Connect-PnPOnline -Url $GovernanceSiteUrl -Interactive -ReturnConnection }
        else { Connect-PnPOnline -Url $GovernanceSiteUrl -ClientId $ClientId -Tenant $Tenant -Thumbprint $Thumbprint -ReturnConnection }

# Admin centre URL for the links: https://<tenant>.sharepoint.com -> https://<tenant>-admin.sharepoint.com
$adminUrl = ([Uri] $GovernanceSiteUrl).GetLeftPart('Authority') -replace '\.sharepoint\.com$', '-admin.sharepoint.com'

# --- Status badges ------------------------------------------------------------
foreach ($pair in $dash.statusColumns) {
    Set-PnPField -List $pair[0] -Identity $pair[1] -Values @{ CustomFormatter = $statusFormat } -Connection $conn
    Write-Output "  ~ $($pair[0]).$($pair[1]) formatted"
}

# --- Views ----------------------------------------------------------------------
$views = @{}
foreach ($v in $dash.views) {
    $existing = Get-PnPView -List $v.list -Identity $v.title -Connection $conn -ErrorAction SilentlyContinue
    if ($existing -and $RefreshViews) { Remove-PnPView -List $v.list -Identity $v.title -Force -Connection $conn; $existing = $null }
    if (-not $existing) {
        Add-PnPView -List $v.list -Title $v.title -Query $v.query -Fields $v.fields -RowLimit $v.rowLimit -Connection $conn | Out-Null
        Write-Output "  + view $($v.list): $($v.title)"
    }
    $views[$v.key] = @{
        List = Get-PnPList -Identity $v.list -Connection $conn
        View = Get-PnPView -List $v.list -Identity $v.title -Connection $conn
    }
}

# --- Page -----------------------------------------------------------------------
$name = $dash.page.name
$page = Get-PnPPage -Identity $name -Connection $conn -ErrorAction SilentlyContinue
if ($page -and -not $RefreshPage) {
    Write-Output "  = $name.aspx exists (use -RefreshPage to rebuild it)"
} else {
    if ($page) { Remove-PnPPage -Identity $name -Force -Connection $conn }
    Add-PnPPage -Name $name -Title $dash.page.title -LayoutType Article -Connection $conn | Out-Null

    # Section 1: intro. Sections 2-5: panels two to a row. Last: SAM and automation links.
    $sections = ($dash.views | Measure-Object -Property section -Maximum).Maximum
    Add-PnPPageSection -Page $name -SectionTemplate OneColumn -Order 1 -Connection $conn | Out-Null
    for ($s = 2; $s -le $sections; $s++) {
        Add-PnPPageSection -Page $name -SectionTemplate TwoColumn -Order $s -Connection $conn | Out-Null
    }
    Add-PnPPageSection -Page $name -SectionTemplate OneColumn -Order ($sections + 1) -Connection $conn | Out-Null

    Add-PnPPageTextPart -Page $name -Section 1 -Column 1 -Text $dash.page.intro -Connection $conn | Out-Null
    foreach ($v in $dash.views) {
        $target = $views[$v.key]
        Add-PnPPageTextPart -Page $name -Section $v.section -Column $v.column -Text "<h3>$($v.heading)</h3>" -Connection $conn | Out-Null
        Add-PnPPageWebPart -Page $name -Section $v.section -Column $v.column -DefaultWebPartType List -WebPartProperties @{
            isDocumentLibrary = $false
            selectedListId    = $target.List.Id.ToString()
            selectedViewId    = $target.View.Id.ToString()
            hideCommandBar    = $true
            webpartHeightKey  = 1
        } -Connection $conn | Out-Null
    }
    Add-PnPPageTextPart -Page $name -Section ($sections + 1) -Column 1 -Text ($dash.page.links -replace '\{AdminUrl\}', $adminUrl) -Connection $conn | Out-Null

    Set-PnPPage -Identity $name -Publish -Connection $conn | Out-Null
    Write-Output "  + $name.aspx published"
}

Write-Output ''
Write-Output 'Next (by hand):'
Write-Output "  1. Open $name.aspx and check each panel shows its view; if one shows All Items, pick the view in the web part's settings and republish."
Write-Output '  2. Add the page to the site navigation, or set it as the home page (Pages library > ... > Make homepage).'
