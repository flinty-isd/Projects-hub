<#
.SYNOPSIS
    Builds the Enterprise PMO hub: the PMO lists and libraries, their columns,
    RAG and due-date formatting, the dashboard views and the
    Portfolio-Governance-Hub.aspx page.

.DESCRIPTION
    Reads sharepoint/list-schema.json, sharepoint/dashboard.json and the column
    formatters in sharepoint/, then:
      * creates each list or library that doesn't exist yet (lookup targets
        first, in schema order), turns on versioning and adds missing columns.
        Flow-managed columns are hidden from the new and edit forms; columns
        marked indexed get an index (needed for the flows' filters once a list
        passes 5,000 items)
      * formats the RAG columns as status pills, the RAID target date and
        action due date as overdue / due-soon badges, and change request and
        escalation status as outcome badges
      * adds the dashboard views (Executive escalations, Pending board
        decisions, Next 30 days, PIDs and charters, Open change requests,
        Escalation requests)
      * creates and publishes the hub page: welcome text and Quick Links;
        Power BI (2/3) with the PMO commentary (1/3); RAID escalations and
        board decisions side by side; calendar, documents and the leadership
        People web part in three columns; open change requests and escalation
        requests side by side. Comments are off.

    Standard lists, views, web parts and JSON column formatting only: no
    custom script. Safe to re-run: existing lists, columns and views are left
    alone (-RefreshViews rebuilds the views), and the page is rebuilt only with
    -RefreshPage.

.NOTES
    Requires PnP.PowerShell 2.x. Run as a site owner of the PMO site, or with
    an app registration that has Sites.FullControl.All. The site itself
    (a communication or team site) must already exist.
    Not yet run against a tenant: run it on a test site first.

.EXAMPLE
    ./Provision-PMOHub.ps1 -SiteUrl https://contoso.sharepoint.com/sites/EnterprisePMO -Interactive `
        -LeadershipContacts director@contoso.com, headofpmo@contoso.com, governance.lead@contoso.com
#>
param(
    [Parameter(Mandatory)] [string] $SiteUrl,
    [string] $ClientId,
    [string] $Tenant,
    [string] $Thumbprint,
    [switch] $Interactive,
    # UPNs for the People web part, in the order of dashboard.json page.people.roles.
    [string[]] $LeadershipContacts = @(),
    [switch] $RefreshViews,
    [switch] $RefreshPage
)

$ErrorActionPreference = 'Stop'
$SiteUrl = $SiteUrl.TrimEnd('/')
$root = Split-Path -Parent $PSScriptRoot
$schema = Get-Content (Join-Path $root 'sharepoint/list-schema.json') -Raw | ConvertFrom-Json
$dash = Get-Content (Join-Path $root 'sharepoint/dashboard.json') -Raw | ConvertFrom-Json

$conn = if ($Interactive) { Connect-PnPOnline -Url $SiteUrl -Interactive -ReturnConnection }
        else { Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $Tenant -Thumbprint $Thumbprint -ReturnConnection }

function Escape-Xml([string] $s) { [System.Security.SecurityElement]::Escape($s) }

function Get-FieldXml($f, $listIds) {
    $name = $f.internalName
    $attrs = "Name=`"$name`" StaticName=`"$name`" DisplayName=`"$(Escape-Xml $f.displayName)`" Required=`"$(if ($f.required) {'TRUE'} else {'FALSE'})`""
    if ($f.flowManaged) { $attrs += ' ShowInNewForm="FALSE" ShowInEditForm="FALSE"' }
    elseif ($f.hideOnNewForm) { $attrs += ' ShowInNewForm="FALSE"' }
    if ($f.notes) { $attrs += " Description=`"$(Escape-Xml $f.notes)`"" }
    $default = if ($null -ne $f.default) { "<Default>$(Escape-Xml ([string] $f.default))</Default>" } else { '' }
    switch ($f.type) {
        'Text'     { "<Field Type=`"Text`" $attrs MaxLength=`"255`" />" }
        'Note'     { "<Field Type=`"Note`" $attrs NumLines=`"6`" RichText=`"FALSE`" />" }
        'Number'   { $dec = if ($null -ne $f.decimals) { $f.decimals } else { 0 }
                     "<Field Type=`"Number`" $attrs Decimals=`"$dec`">$default</Field>" }
        'DateTime' { $fmt = if ($f.format) { $f.format } else { 'DateTime' }
                     "<Field Type=`"DateTime`" $attrs Format=`"$fmt`" />" }
        'Boolean'  { "<Field Type=`"Boolean`" $attrs>$default</Field>" }
        'Choice'   { $choices = ($f.choices | ForEach-Object { "<CHOICE>$(Escape-Xml $_)</CHOICE>" }) -join ''
                     "<Field Type=`"Choice`" $attrs Format=`"Dropdown`" FillInChoice=`"FALSE`">$default<CHOICES>$choices</CHOICES></Field>" }
        'Person'   { "<Field Type=`"User`" $attrs UserSelectionMode=`"PeopleOnly`" UserSelectionScope=`"0`" List=`"UserInfo`" ShowField=`"ImnName`" />" }
        'Lookup'   { $target = $listIds[$f.lookupList]
                     if (-not $target) { throw "Lookup $name needs list '$($f.lookupList)', which must come earlier in list-schema.json" }
                     "<Field Type=`"Lookup`" $attrs List=`"{$target}`" ShowField=`"$($f.lookupField)`" />" }
        default    { throw "Unknown field type $($f.type) for $name" }
    }
}

# --- Lists, libraries and columns -------------------------------------------------
$listIds = @{}
foreach ($l in $schema.lists) {
    $list = Get-PnPList -Identity $l.listTitle -Connection $conn -ErrorAction SilentlyContinue
    if (-not $list) {
        $list = New-PnPList -Title $l.listTitle -Url $l.url -Template $l.template -OnQuickLaunch -Connection $conn
        Set-PnPList -Identity $l.listTitle -Description $l.listDescription -EnableVersioning $true -Connection $conn | Out-Null
        Write-Output "  + list $($l.listTitle) ($($l.template))"
        $list = Get-PnPList -Identity $l.listTitle -Connection $conn
    }
    $listIds[$l.listTitle] = $list.Id.ToString()

    $existing = (Get-PnPField -List $l.listTitle -Connection $conn).InternalName
    $added = @()
    foreach ($f in $l.fields) {
        if ($existing -contains $f.internalName) { continue }
        Add-PnPFieldFromXml -List $l.listTitle -FieldXml (Get-FieldXml $f $listIds) -Connection $conn | Out-Null
        if ($f.indexed) { Set-PnPField -List $l.listTitle -Identity $f.internalName -Values @{ Indexed = $true } -Connection $conn | Out-Null }
        if (-not $f.hidden) { $added += $f.internalName }
        Write-Output "    + $($l.listTitle).$($f.internalName)"
    }
    if ($added.Count -gt 0) {
        # Show new columns in the default view (flow-only tracking columns stay out).
        $view = Get-PnPView -List $l.listTitle -Connection $conn | Where-Object DefaultView
        $fields = @($view.ViewFields) + $added | Select-Object -Unique
        Set-PnPView -List $l.listTitle -Identity $view.Id -Fields $fields -Connection $conn | Out-Null
    }
}

# --- Column formatting -------------------------------------------------------------
foreach ($fmt in $dash.formatters) {
    $json = Get-Content (Join-Path $root "sharepoint/$($fmt.file)") -Raw
    foreach ($pair in $fmt.columns) {
        Set-PnPField -List $pair[0] -Identity $pair[1] -Values @{ CustomFormatter = $json } -Connection $conn | Out-Null
        Write-Output "  ~ $($pair[0]).$($pair[1]) formatted ($($fmt.file))"
    }
}

# --- Views -------------------------------------------------------------------------
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

# --- Hub page ----------------------------------------------------------------------
$name = $dash.page.name
$page = Get-PnPPage -Identity $name -Connection $conn -ErrorAction SilentlyContinue
if ($page -and -not $RefreshPage) {
    Write-Output "  = $name.aspx exists (use -RefreshPage to rebuild it)"
} else {
    if ($page) { Remove-PnPPage -Identity $name -Force -Connection $conn }
    # Home layout: no title banner, so the panels start at the top of the screen.
    Add-PnPPage -Name $name -Title $dash.page.title -LayoutType Home -Connection $conn | Out-Null

    Add-PnPPageSection -Page $name -SectionTemplate OneColumn     -Order 1 -Connection $conn | Out-Null  # header and navigation
    Add-PnPPageSection -Page $name -SectionTemplate TwoColumnLeft -Order 2 -Connection $conn | Out-Null  # Power BI 2/3, commentary 1/3
    Add-PnPPageSection -Page $name -SectionTemplate TwoColumn     -Order 3 -Connection $conn | Out-Null  # escalations, decisions
    Add-PnPPageSection -Page $name -SectionTemplate ThreeColumn   -Order 4 -Connection $conn | Out-Null  # cadence, artefacts, people
    # Sections 5 and up (change requests, escalation requests): two panels to a row.
    $last = ($dash.views | Measure-Object -Property section -Maximum).Maximum
    for ($s = 5; $s -le $last; $s++) {
        Add-PnPPageSection -Page $name -SectionTemplate TwoColumn -Order $s -Connection $conn | Out-Null
    }

    # Section 1: welcome and Quick Links (links are added by hand: see the list printed below).
    Add-PnPPageTextPart -Page $name -Section 1 -Column 1 -Text $dash.page.welcome -Connection $conn | Out-Null
    Add-PnPPageWebPart -Page $name -Section 1 -Column 1 -DefaultWebPartType QuickLinks -WebPartProperties @{
        title = 'Quick links'; layoutId = 'CompactCard'; dataProviderId = 'QuickLinks'
    } -Connection $conn | Out-Null

    # Section 2: Power BI report (picked by hand) and the PMO commentary.
    Add-PnPPageWebPart -Page $name -Section 2 -Column 1 -DefaultWebPartType PowerBIReportEmbed -Connection $conn | Out-Null
    Add-PnPPageTextPart -Page $name -Section 2 -Column 1 -Text $dash.page.powerBiNote -Connection $conn | Out-Null
    Add-PnPPageTextPart -Page $name -Section 2 -Column 2 -Text $dash.page.commentary -Connection $conn | Out-Null

    # Sections 3 and up: the dashboard views.
    foreach ($v in $dash.views) {
        $target = $views[$v.key]
        Add-PnPPageTextPart -Page $name -Section $v.section -Column $v.column -Text "<h3>$($v.heading)</h3>" -Connection $conn | Out-Null
        Add-PnPPageWebPart -Page $name -Section $v.section -Column $v.column -DefaultWebPartType List -WebPartProperties @{
            isDocumentLibrary = [bool] $v.isDocumentLibrary
            selectedListId    = $target.List.Id.ToString()
            selectedViewId    = $target.View.Id.ToString()
            hideCommandBar    = $true
            webpartHeightKey  = 1
        } -Connection $conn | Out-Null
    }

    # Section 4, column 3: leadership contacts.
    $persons = @($LeadershipContacts | Where-Object { $_ } | ForEach-Object { @{ id = "i:0#.f|membership|$_"; upn = $_ } })
    Add-PnPPageTextPart -Page $name -Section 4 -Column 3 -Text "<h3>$($dash.page.people.title)</h3>" -Connection $conn | Out-Null
    Add-PnPPageWebPart -Page $name -Section 4 -Column 3 -DefaultWebPartType People -WebPartProperties @{
        layout = 2; persons = $persons
    } -Connection $conn | Out-Null

    Set-PnPPage -Identity $name -CommentsEnabled:$false -Publish -Connection $conn | Out-Null
    Write-Output "  + $name.aspx published"
}

Write-Output ''
Write-Output 'Next (by hand, in the page editor):'
Write-Output '  1. Quick Links web part: add these links (and turn on audience targeting if PMs and Steering Committee members should see different sets):'
foreach ($q in $dash.page.quickLinks) {
    Write-Output ("       - {0}: {1}  [icon {2}; audience {3}] {4}" -f $q.title, ($q.url -replace '\{SiteUrl\}', $SiteUrl), $q.icon, $q.audience, $q.description)
}
Write-Output '  2. Power BI web part: pick the PMO Enterprise Analytics report (RAG scorecard, slippage trend, early-warning heatmap), then delete the note under it.'
Write-Output '  3. Commentary: replace the [bracketed] placeholders with this period''s commentary.'
Write-Output "  4. People web part: check the contacts ($($dash.page.people.roles -join '; ')) and add each role as the person's description."
Write-Output '  5. Check each list panel shows its view; if one shows All Items, pick the view in the web part settings. Republish.'
Write-Output '  6. Make the page the site home page (Pages library > ... > Make homepage) or add it to the navigation.'
