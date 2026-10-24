<#
.SYNOPSIS
    Provisions the lists, columns, views, permissions and Publisher Guide page
    for the HPUK News and Other News communication sites.

.DESCRIPTION
    Reads sharepoint/list-schema.json (the same file the flow validator checks)
    and makes each site match it. Safe to re-run: existing lists and columns are
    left as they are, and missing ones are added.

    What it does on each site:
      * adds the news columns to Site Pages, with identical internal names on
        both sites, so news web parts and the flows can filter across both
      * creates Notices and Attachments, Notices Archive, Comms Distribution
        and Delivery Log on HPUK News
      * adds the Current and Archive views to Notices and Attachments
      * puts the scoped reader group in Visitors and each site's publisher group
        in Members (never "Everyone except external users": the tenant is shared)
      * makes the Delivery Log dispatch key (Title) unique and indexed, and adds a
        Needs checking view (rows that are Reserved or Reconcile)
      * locks Notices Archive, Comms Distribution and Delivery Log to the
        configuration maintainers group (and the flow identity where it writes)
      * keeps content approval off on Site Pages: publishers are pre-approved,
        so a published page is live straight away (turns it off if it was on)
      * creates and publishes Publisher-Guide.aspx on HPUK News from
        pages/Publisher-Guide.html

    Not done here (no supported cmdlet; see the README):
      * enabling audience targeting on Site Pages
      * hub association and organisation news site designation (IT)
      * News web part configuration on the home pages

.NOTES
    Requires PnP.PowerShell 2.x and an app registration with Sites.FullControl.All
    and TermStore.ReadWrite.All, or run with -Interactive as a SharePoint admin.
    The Department and Category term sets must already exist in the term group:
    import taxonomy/TermSet-Department.csv and taxonomy/TermSet-Category.csv first.
    Not yet run against a tenant: run it on a test pair of sites first.
#>
param(
    [Parameter(Mandatory)] [string] $HPUKNewsUrl,
    [Parameter(Mandatory)] [string] $OtherNewsUrl,
    [Parameter(Mandatory)] [string] $ReaderGroupId,            # scoped HPUK reader security group (Entra object ID)
    [Parameter(Mandatory)] [string] $HPUKPublisherGroupId,
    [Parameter(Mandatory)] [string] $OtherPublisherGroupId,
    [Parameter(Mandatory)] [string] $ConfigMaintainerGroupId,
    [Parameter(Mandatory)] [string] $FlowIdentityUpn,           # account the flows' SharePoint connection signs in as
    [string] $TermGroup = 'Communications',
    [string] $ClientId,
    [string] $Tenant,
    [string] $Thumbprint,
    [switch] $Interactive,
    [switch] $RefreshPublisherGuide
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$schema = Get-Content (Join-Path $root 'sharepoint/list-schema.json') -Raw | ConvertFrom-Json

function Connect-Site([string] $url) {
    if ($Interactive) { return Connect-PnPOnline -Url $url -Interactive -ReturnConnection }
    return Connect-PnPOnline -Url $url -ClientId $ClientId -Tenant $Tenant -Thumbprint $Thumbprint -ReturnConnection
}

function Get-GroupClaim([string] $objectId) { "c:0t.c|tenant|$objectId" }

function Ensure-List($conn, $def) {
    $list = Get-PnPList -Identity $def.listTitle -Connection $conn -ErrorAction SilentlyContinue
    if ($list) { return $list }
    $template = if ($def.template -eq 'DocumentLibrary') { 'DocumentLibrary' } else { 'GenericList' }
    Write-Output "  + list $($def.listTitle)"
    New-PnPList -Title $def.listTitle -Template $template -OnQuickLaunch:$false -Connection $conn | Out-Null
    return Get-PnPList -Identity $def.listTitle -Connection $conn
}

function Ensure-Field($conn, [string] $listTitle, $f) {
    $existing = Get-PnPField -List $listTitle -Identity $f.internalName -Connection $conn -ErrorAction SilentlyContinue
    if ($existing) { return }
    Write-Output "  + $listTitle.$($f.internalName) ($($f.type))"
    $common = @{ List = $listTitle; DisplayName = $f.displayName; InternalName = $f.internalName; Connection = $conn }
    switch ($f.type) {
        'Taxonomy' {
            $path = "$TermGroup|$($f.termSet.Split('|')[-1])"
            Add-PnPTaxonomyField @common -TermSetPath $path -Required:([bool]$f.required) | Out-Null
        }
        'MultiChoice' { Add-PnPField @common -Type MultiChoice -Choices $f.choices -Required:([bool]$f.required) | Out-Null }
        'Choice'      { Add-PnPField @common -Type Choice -Choices $f.choices -Required:([bool]$f.required) | Out-Null }
        'Boolean'     { Add-PnPField @common -Type Boolean | Out-Null }
        'Number'      { Add-PnPField @common -Type Number -Required:([bool]$f.required) | Out-Null }
        'DateOnly'    {
            Add-PnPField @common -Type DateTime -Required:([bool]$f.required) | Out-Null
            Set-PnPField -List $listTitle -Identity $f.internalName -Values @{ DisplayFormat = 0 } -Connection $conn  # date only
        }
        'DateTime'    { Add-PnPField @common -Type DateTime -Required:([bool]$f.required) | Out-Null }
        'Note'        {
            Add-PnPField @common -Type Note -Required:([bool]$f.required) | Out-Null
            if ($f.richText) { Set-PnPField -List $listTitle -Identity $f.internalName -Values @{ RichText = $true } -Connection $conn }
        }
        'Person'      { Add-PnPField @common -Type User -Required:([bool]$f.required) | Out-Null }
        default       { Add-PnPField @common -Type Text -Required:([bool]$f.required) | Out-Null }
    }
    if ($null -ne $f.default) {
        $value = if ($f.default -is [bool]) { if ($f.default) { '1' } else { '0' } } else { [string]$f.default }
        Set-PnPField -List $listTitle -Identity $f.internalName -Values @{ DefaultValue = $value } -Connection $conn
    }
}

function Restrict-List($conn, [string] $listTitle, [string[]] $editors, [string[]] $readers) {
    Set-PnPList -Identity $listTitle -BreakRoleInheritance -CopyRoleAssignments:$false -ClearSubscopes -Connection $conn | Out-Null
    foreach ($e in $editors) { Set-PnPListPermission -Identity $listTitle -User $e -AddRole 'Edit' -Connection $conn }
    foreach ($r in $readers) { Set-PnPListPermission -Identity $listTitle -User $r -AddRole 'Read' -Connection $conn }
    Write-Output "  ~ $listTitle restricted"
}

$sites = @(
    @{ Key = 'HPUK News';  Url = $HPUKNewsUrl;  Publishers = $HPUKPublisherGroupId },
    @{ Key = 'Other News'; Url = $OtherNewsUrl; Publishers = $OtherPublisherGroupId }
)

foreach ($site in $sites) {
    Write-Output "== $($site.Key) ($($site.Url))"
    $conn = Connect-Site $site.Url

    foreach ($def in $schema.lists | Where-Object { $_.sites -contains $site.Key }) {
        Ensure-List $conn $def | Out-Null
        foreach ($f in $def.fields) { Ensure-Field $conn $def.listTitle $f }
    }

    # Readers and publishers: groups only, no individual grants.
    Add-PnPGroupMember -Group (Get-PnPGroup -AssociatedVisitorGroup -Connection $conn) -LoginName (Get-GroupClaim $ReaderGroupId) -Connection $conn
    Add-PnPGroupMember -Group (Get-PnPGroup -AssociatedMemberGroup -Connection $conn) -LoginName (Get-GroupClaim $site.Publishers) -Connection $conn

    # No page approval: publishers are pre-approved, so publishing makes a page live.
    # Membership of the publisher group is the control.
    if ((Get-PnPList -Identity 'Site Pages' -Connection $conn).EnableModeration) {
        Set-PnPList -Identity 'Site Pages' -EnableModeration $false -Connection $conn | Out-Null
        Write-Output '  ~ Site Pages: content approval turned off'
    }

    if ($site.Key -eq 'HPUK News') {
        Set-PnPList -Identity 'Notices and Attachments' -EnableVersioning $true -EnableMinorVersions $false -Connection $conn | Out-Null

        # Other News publishers attach files here too, without edit rights on the rest of HPUK News.
        Set-PnPList -Identity 'Notices and Attachments' -BreakRoleInheritance -CopyRoleAssignments -Connection $conn | Out-Null
        Set-PnPListPermission -Identity 'Notices and Attachments' -User (Get-GroupClaim $OtherPublisherGroupId) -AddRole 'Contribute' -Connection $conn

        foreach ($v in @(
            @{ Title = 'Current'; Query = '<Where><Eq><FieldRef Name="Status"/><Value Type="Choice">Live</Value></Eq></Where>' },
            @{ Title = 'Archive'; Query = '<Where><Eq><FieldRef Name="Status"/><Value Type="Choice">Expired</Value></Eq></Where>' })) {
            if (-not (Get-PnPView -List 'Notices and Attachments' -Identity $v.Title -Connection $conn -ErrorAction SilentlyContinue)) {
                Add-PnPView -List 'Notices and Attachments' -Title $v.Title -Query $v.Query `
                    -Fields 'DocIcon', 'LinkFilename', 'Department', 'Category', 'Port', 'ExpiryDate', 'Modified' -Connection $conn | Out-Null
                Write-Output "  + view $($v.Title)"
            }
        }

        # The dispatch key (Title) must be unique and indexed: the flows reserve it before every send,
        # so two runs can never both send the same notice to the same destination.
        Set-PnPField -List 'Delivery Log' -Identity 'Title' -Values @{ Indexed = $true; EnforceUniqueValues = $true } -Connection $conn
        if (-not (Get-PnPView -List 'Delivery Log' -Identity 'Needs checking' -Connection $conn -ErrorAction SilentlyContinue)) {
            Add-PnPView -List 'Delivery Log' -Title 'Needs checking' `
                -Query '<Where><Or><Eq><FieldRef Name="DeliveryStatus"/><Value Type="Choice">Reconcile</Value></Eq><Eq><FieldRef Name="DeliveryStatus"/><Value Type="Choice">Reserved</Value></Eq></Or></Where><OrderBy><FieldRef Name="DeliveredAt" Ascending="FALSE"/></OrderBy>' `
                -Fields 'Title', 'DeliveryStatus', 'Destination', 'Channel', 'DeliveredAt', 'ErrorDetail' -Connection $conn | Out-Null
            Write-Output '  + view Delivery Log: Needs checking'
        }

        $maint = Get-GroupClaim $ConfigMaintainerGroupId
        Restrict-List $conn 'Notices Archive'    @($maint)                    @((Get-GroupClaim $ReaderGroupId))
        Restrict-List $conn 'Comms Distribution' @($maint)                    @($FlowIdentityUpn)
        Restrict-List $conn 'Delivery Log'       @($maint, $FlowIdentityUpn)  @()

        $guide = Get-PnPPage -Identity 'Publisher-Guide' -Connection $conn -ErrorAction SilentlyContinue
        if (-not $guide -or $RefreshPublisherGuide) {
            $html = Get-Content (Join-Path $root 'pages/Publisher-Guide.html') -Raw
            # Rebuild rather than edit in place: the page holds one text web part and nothing else.
            if ($guide) { Remove-PnPPage -Identity 'Publisher-Guide' -Force -Connection $conn }
            Add-PnPPage -Name 'Publisher-Guide' -Title 'Publisher Guide' -LayoutType Article -Connection $conn | Out-Null
            Add-PnPPageTextPart -Page 'Publisher-Guide' -Text $html -Connection $conn | Out-Null
            Set-PnPPage -Identity 'Publisher-Guide' -Publish -Connection $conn | Out-Null
            Write-Output '  + Publisher-Guide.aspx published'
        }
    }
}

Write-Output ''
Write-Output 'Manual steps left (see README):'
Write-Output '  1. Site Pages > Settings > Audience targeting: turn on, on both sites.'
Write-Output '  2. IT: associate both sites with the intranet hub; designate HPUK News as an organisation news site.'
Write-Output '  3. Home pages: configure the News web parts (Status = Live filter; Safety section = Category Health and Safety).'
Write-Output '  4. Fill Comms Distribution with one row per port (Enabled = No until destinations are verified).'
Write-Output '  5. Run Set-NewsRetention.ps1 (7-year retention) as a Purview compliance admin.'
