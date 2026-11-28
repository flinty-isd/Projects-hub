<#
.SYNOPSIS
    Provisions the lists, columns, views, permissions and Publisher Guide page
    for the HPUK News and Other News communication sites.

.DESCRIPTION
    Reads sharepoint/list-schema.json (the same file the flow validator checks)
    and makes each site match it. Missing lists and columns are added. Existing
    columns are compared with the schema (type, required, default, choices) and
    every difference is listed as drift; the script ends with an error while any
    drift is left. -FixDrift corrects defaults, required and missing choices (it
    never changes a column's type or removes a choice: those are reported for a
    person to decide). On Other News a column uses its otherNewsInternalName
    where the schema gives one.

    Permissions are checked, not changed, on a normal run: the restricted lists'
    grants and the site's groups are compared with the intended state, and broad
    claims (Everyone, Everyone except external users) and direct user grants are
    reported. -RepairPermissions re-applies the list restrictions; it keeps
    item-level permissions unless -ClearItemPermissions is also given, and lists
    them first.

    What it does on each site:
      * adds the news columns to Site Pages, with identical internal names on
        both sites, so news web parts and the flows can filter across both
      * creates Notices and Attachments, Notices Archive, Comms Distribution
        and Delivery Log on HPUK News
      * adds the Current and Archive views to Notices and Attachments
      * creates a News Videos library on both sites (major versions; videos
        play through Stream and inherit the site's permissions)
      * puts the scoped reader group in Visitors and each site's publisher group
        in Members (never "Everyone except external users": the tenant is shared)
      * makes the Delivery Log dispatch key (Title) unique and indexed, and adds a
        Needs checking view (rows that are Reserved or Reconcile)
      * locks Notices Archive, Comms Distribution and Delivery Log to the
        configuration maintainers group (and the named flow owner where it writes)
      * turns on draft (minor) versions on Site Pages, with drafts visible only to
        editors, so publishers' drafts stay out of readers' sight
      * keeps content approval off on Site Pages: publishers are pre-approved,
        so a published page is live straight away (turns it off if it was on)
      * creates and publishes Publisher-Guide.aspx on HPUK News from
        pages/Publisher-Guide.html
      * with -CreateTemplates, adds the news page template to each site
        ("HPUK News post" / "Other News post"): image and title header, then
        one-column sections for Summary, Main content, Action required and
        deadline, Attachments and Contact, and no author byline. Run once per site; an existing
        template is left alone unless -RefreshTemplates is also given

    Not done here (no supported cmdlet; see the README):
      * enabling audience targeting on Site Pages
      * hub association and organisation news site designation (IT)
      * News web part configuration on the home pages

.NOTES
    Requires PnP.PowerShell 2.x and an Entra app registration (-ClientId is always
    required: PnP no longer ships a default app). App-only: Sites.FullControl.All
    and TermStore.ReadWrite.All with -Tenant and -Thumbprint. -Interactive: the
    same app with delegated permissions, signed in as a SharePoint admin.
    The Department, Category and Strategy theme term sets must already exist in the
    term group: import the three CSVs in taxonomy/ first.
    Not yet run against a tenant: run it on a test pair of sites first.
#>
param(
    [Parameter(Mandatory)] [string] $HPUKNewsUrl,
    [Parameter(Mandatory)] [string] $OtherNewsUrl,
    [Parameter(Mandatory)] [string] $ReaderGroupId,            # scoped HPUK reader security group (Entra object ID)
    [Parameter(Mandatory)] [string] $HPUKPublisherGroupId,
    [Parameter(Mandatory)] [string] $OtherPublisherGroupId,
    [Parameter(Mandatory)] [string] $ConfigMaintainerGroupId,
    [Parameter(Mandatory)] [string] $FlowIdentityUpn,           # named news flow owner the connections sign in as (never a shared account, D-03)
    [string] $TermGroup = 'Communications',
    [string] $ClientId,
    [string] $Tenant,
    [string] $Thumbprint,
    [switch] $Interactive,
    [switch] $RefreshPublisherGuide,
    [switch] $CreateTemplates,
    [switch] $RefreshTemplates,
    [switch] $FixDrift,
    [switch] $RepairPermissions,
    [switch] $ClearItemPermissions
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$schema = Get-Content (Join-Path $root 'sharepoint/list-schema.json') -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($ClientId)) {
    throw '-ClientId is required (the Entra app registration PnP signs in with), for -Interactive too.'
}
if (-not $Interactive -and ([string]::IsNullOrWhiteSpace($Tenant) -or [string]::IsNullOrWhiteSpace($Thumbprint))) {
    throw 'App-only sign-in needs -Tenant and -Thumbprint; or use -Interactive.'
}
$drift = [System.Collections.Generic.List[string]]::new()
function Add-Drift([string] $text) { $drift.Add($text); Write-Warning "  drift: $text" }

function Connect-Site([string] $url) {
    if ($Interactive) { return Connect-PnPOnline -Url $url -Interactive -ClientId $ClientId -ReturnConnection }
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

# Schema type -> SharePoint field Type attribute(s) it may have.
$typeMap = @{
    Taxonomy = @('TaxonomyFieldType', 'TaxonomyFieldTypeMulti'); MultiChoice = @('MultiChoice'); Choice = @('Choice')
    Boolean = @('Boolean'); Number = @('Number'); DateOnly = @('DateTime'); DateTime = @('DateTime')
    Note = @('Note'); Person = @('User', 'UserMulti'); Text = @('Text')
}

function Test-Field($conn, [string] $listTitle, $f, $existing) {
    $x = ([xml]$existing.SchemaXml).Field
    $name = "$listTitle.$($existing.InternalName)"
    $want = $typeMap[$f.type]; if (-not $want) { $want = @('Text') }
    $accept = @($want) + @($f.alsoAccept | Where-Object { $_ })
    if ($accept -notcontains $x.Type) { Add-Drift "$name is $($x.Type), schema says $($f.type) (not changed: decide by hand)"; return }
    $fix = @{}
    $isReq = "$($x.Required)" -eq 'TRUE'
    if ($isReq -ne [bool]$f.required) {
        if ($FixDrift) { $fix.Required = [bool]$f.required } else { Add-Drift "$name required is $isReq, schema says $([bool]$f.required)" }
    }
    if ($null -ne $f.default) {
        $wantDefault = if ($f.default -is [bool]) { if ($f.default) { '1' } else { '0' } } else { [string]$f.default }
        $haveDefault = "$($x.Default)"
        if ($haveDefault -ne $wantDefault) {
            if ($FixDrift) { $fix.DefaultValue = $wantDefault } else { Add-Drift "$name default is '$haveDefault', schema says '$wantDefault'" }
        }
    }
    if ($f.choices -and $x.Type -in 'Choice', 'MultiChoice') {
        $have = @($x.CHOICES.CHOICE)
        $missing = @($f.choices | Where-Object { $have -notcontains $_ })
        $extra = @($have | Where-Object { $f.choices -notcontains $_ })
        if ($missing) {
            if ($FixDrift) { $fix.Choices = [string[]](@($have) + $missing) } else { Add-Drift "$name is missing choices: $($missing -join ', ')" }
        }
        if ($extra) { Add-Drift "$name has choices not in the schema: $($extra -join ', ') (not removed: check no item uses them)" }
    }
    if ($fix.Count) {
        Set-PnPField -List $listTitle -Identity $existing.InternalName -Values $fix -Connection $conn | Out-Null
        Write-Output "  ~ $name fixed: $($fix.Keys -join ', ')"
    }
}

function Ensure-Field($conn, [string] $listTitle, $f, [string] $siteKey) {
    if ($siteKey -eq 'Other News' -and $f.otherNewsInternalName) {
        $f = $f.PSObject.Copy(); $f.internalName = $f.otherNewsInternalName
    }
    $existing = Get-PnPField -List $listTitle -Identity $f.internalName -Connection $conn -ErrorAction SilentlyContinue
    if ($existing) { Test-Field $conn $listTitle $f $existing; return }
    Write-Output "  + $listTitle.$($f.internalName) ($($f.type))"
    $common = @{ List = $listTitle; DisplayName = $f.displayName; InternalName = $f.internalName; Connection = $conn }
    switch ($f.type) {
        'Taxonomy' {
            $path = "$TermGroup|$($f.termSet.Split('|')[-1])"
            Add-PnPTaxonomyField @common -TermSetPath $path -Required:([bool]$f.required) -MultiValue:([bool]$f.multi) | Out-Null
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

function Get-ListGrants($conn, [string] $listTitle) {
    $list = Get-PnPList -Identity $listTitle -Includes HasUniqueRoleAssignments, RoleAssignments -Connection $conn
    $grants = @()
    foreach ($ra in $list.RoleAssignments) {
        Get-PnPProperty -ClientObject $ra -Property Member, RoleDefinitionBindings -Connection $conn | Out-Null
        foreach ($rd in $ra.RoleDefinitionBindings) { $grants += "$($ra.Member.LoginName)=$($rd.Name)".ToLowerInvariant() }
    }
    [pscustomobject]@{ Unique = $list.HasUniqueRoleAssignments; Grants = $grants }
}

function Get-UniqueItems($conn, [string] $listTitle) {
    @(Get-PnPListItem -List $listTitle -PageSize 500 -Connection $conn | Where-Object {
        (Get-PnPProperty -ClientObject $_ -Property HasUniqueRoleAssignments -Connection $conn)
    } | ForEach-Object { $_.Id })
}

# Checks a restricted list against its intended grants; changes it only with -RepairPermissions.
function Restrict-List($conn, [string] $listTitle, [string[]] $editors, [string[]] $readers) {
    $want = @($editors | ForEach-Object { "$_=edit".ToLowerInvariant() }) + @($readers | ForEach-Object { "$_=read".ToLowerInvariant() })
    $now = Get-ListGrants $conn $listTitle
    $wantNorm = $want | ForEach-Object { $_ -replace '^i:0#\.f\|membership\|', '' }
    $haveNorm = $now.Grants | ForEach-Object { $_ -replace '^i:0#\.f\|membership\|', '' }
    $missing = @($wantNorm | Where-Object { $haveNorm -notcontains $_ })
    $extra = @($haveNorm | Where-Object { $wantNorm -notcontains $_ -and $_ -notmatch '=limited access$' })
    if ($now.Unique -and -not $missing -and -not $extra) { Write-Output "  = $listTitle permissions as intended"; return }
    $what = @(); if (-not $now.Unique) { $what += 'inherits site permissions' }
    if ($missing) { $what += "missing $($missing -join ', ')" }; if ($extra) { $what += "extra $($extra -join ', ')" }
    if (-not $RepairPermissions) { Add-Drift "$listTitle permissions: $($what -join '; ') (rerun with -RepairPermissions)"; return }

    $items = Get-UniqueItems $conn $listTitle
    if ($items.Count -and -not $ClearItemPermissions) {
        Write-Warning "  $listTitle has $($items.Count) item(s) with their own permissions (IDs $($items -join ', ')): kept. Review them; -ClearItemPermissions resets them."
    }
    # Start from no list-level grants: reset to the site's, then break without copying.
    # Item-level permissions are untouched unless -ClearItemPermissions.
    if ($now.Unique) { Set-PnPList -Identity $listTitle -ResetRoleInheritance -Connection $conn | Out-Null }
    Set-PnPList -Identity $listTitle -BreakRoleInheritance -CopyRoleAssignments:$false -ClearSubscopes:([bool]$ClearItemPermissions) -Connection $conn | Out-Null
    foreach ($e in $editors) { Set-PnPListPermission -Identity $listTitle -User $e -AddRole 'Edit' -Connection $conn }
    foreach ($r in $readers) { Set-PnPListPermission -Identity $listTitle -User $r -AddRole 'Read' -Connection $conn }
    # Breaking inheritance grants the person running this Full Control; site admins keep access anyway.
    $me = (Get-PnPProperty -ClientObject (Get-PnPWeb -Connection $conn) -Property CurrentUser -Connection $conn).LoginName
    Set-PnPListPermission -Identity $listTitle -User $me -RemoveRole 'Full Control' -Connection $conn -ErrorAction SilentlyContinue
    $after = Get-ListGrants $conn $listTitle
    $afterNorm = $after.Grants | ForEach-Object { $_ -replace '^i:0#\.f\|membership\|', '' }
    $still = @($wantNorm | Where-Object { $afterNorm -notcontains $_ })
    if ($still) { Add-Drift "$listTitle permissions after repair still missing: $($still -join ', ')" } else { Write-Output "  ~ $listTitle restricted (read back)" }
}

# Reports (never removes) broad or individual grants on the site and its three associated groups.
function Test-SiteAccess($conn, [string] $siteKey, [string[]] $expectedGroups) {
    $broad = 'c:0-.f|rolemanager|spo-grid-all-users', 'c:0(.s|true'   # Everyone except external users; Everyone
    $web = Get-PnPWeb -Includes RoleAssignments -Connection $conn
    foreach ($ra in $web.RoleAssignments) {
        Get-PnPProperty -ClientObject $ra -Property Member -Connection $conn | Out-Null
        $login = "$($ra.Member.LoginName)"
        if ($broad | Where-Object { $login.StartsWith($_) }) { Add-Drift "$siteKey site grant to a broad claim: $login" }
        elseif ($login -like 'i:0#.f|membership|*') { Add-Drift "$siteKey site grant to an individual: $login (use a group)" }
    }
    foreach ($g in @((Get-PnPGroup -AssociatedVisitorGroup -Connection $conn), (Get-PnPGroup -AssociatedMemberGroup -Connection $conn), (Get-PnPGroup -AssociatedOwnerGroup -Connection $conn))) {
        foreach ($m in @(Get-PnPGroupMember -Group $g -Connection $conn)) {
            $login = "$($m.LoginName)"
            if ($broad | Where-Object { $login.StartsWith($_) }) { Add-Drift "$siteKey group '$($g.Title)' contains a broad claim: $login" }
            elseif ($login -like 'c:0t.c|tenant|*' -and $expectedGroups -notcontains $login) { Write-Output "  ? $siteKey group '$($g.Title)' also contains $login: check it is intended" }
        }
    }
}

# Sections of the news page template, in order: heading and the prompt a publisher overwrites.
$templateSections = @(
    @{ Heading = 'Summary';                       Hint = 'One or two sentences: who is affected and what they need to know. Before publishing, open Page details and paste this into Description (emails and Teams show it), then set Department, Category and Port.' },
    @{ Heading = 'Main content';                  Hint = 'The detail. Add pictures with the Image web part and video from News Videos.' },
    @{ Heading = 'Action required and deadline';  Hint = 'What readers must do, and by when. Delete this section if no action is needed.' },
    @{ Heading = 'Attachments';                   Hint = 'Link files from Notices and Attachments. Delete this section if there are none.' },
    @{ Heading = 'Contact';                       Hint = 'Named person and how to reach them.' }
)

function Ensure-NewsTemplate($conn, [string] $title) {
    $name = $title -replace ' ', '-'
    $existing = Get-PnPPage -Identity "Templates/$name" -Connection $conn -ErrorAction SilentlyContinue
    if ($existing -and -not $RefreshTemplates) { return }
    if ($existing) { Remove-PnPPage -Identity "Templates/$name" -Force -Connection $conn }
    # Saved as a template: appears under + New > News post > the site's templates.
    Add-PnPPage -Name $name -Title $title -LayoutType Article -PromoteAs Template -Connection $conn | Out-Null
    $page = Get-PnPPage -Identity "Templates/$name" -Connection $conn
    $i = 1
    foreach ($s in $templateSections) {
        Add-PnPPageSection -Page $page -SectionTemplate OneColumn -Order $i -Connection $conn | Out-Null
        Add-PnPPageTextPart -Page $page -Section $i -Column 1 `
            -Text "<h2>$($s.Heading)</h2><p><em>$($s.Hint)</em></p>" -Connection $conn | Out-Null
        $i++
    }
    # No author byline: posts read as from the site ("HPUK News"), not the publisher.
    # Who published each post stays in Page details and version history.
    try {
        $page = Get-PnPPage -Identity "Templates/$name" -Connection $conn
        $page.PageHeader.Authors = '[]'
        $page.PageHeader.AuthorByLine = ''
        $page.PageHeader.AuthorByLineId = -1
        $page.Save() | Out-Null
    } catch {
        Write-Warning "  Couldn't clear the author byline on '$title': remove it by hand in the template's title area."
    }
    Set-PnPPage -Identity "Templates/$name" -Publish -Connection $conn | Out-Null
    Write-Output "  + template $title"
}

$sites = @(
    @{ Key = 'HPUK News';  Url = $HPUKNewsUrl;  Publishers = $HPUKPublisherGroupId;  Template = 'HPUK News post' },
    @{ Key = 'Other News'; Url = $OtherNewsUrl; Publishers = $OtherPublisherGroupId; Template = 'Other News post' }
)

foreach ($site in $sites) {
    Write-Output "== $($site.Key) ($($site.Url))"
    $conn = Connect-Site $site.Url

    foreach ($def in $schema.lists | Where-Object { $_.sites -contains $site.Key }) {
        Ensure-List $conn $def | Out-Null
        foreach ($f in $def.fields) { Ensure-Field $conn $def.listTitle $f $site.Key }
    }

    # Readers and publishers: groups only, no individual grants.
    Add-PnPGroupMember -Group (Get-PnPGroup -AssociatedVisitorGroup -Connection $conn) -LoginName (Get-GroupClaim $ReaderGroupId) -Connection $conn
    Add-PnPGroupMember -Group (Get-PnPGroup -AssociatedMemberGroup -Connection $conn) -LoginName (Get-GroupClaim $site.Publishers) -Connection $conn
    Test-SiteAccess $conn $site.Key @((Get-GroupClaim $ReaderGroupId), (Get-GroupClaim $site.Publishers), (Get-GroupClaim $ConfigMaintainerGroupId))

    # No page approval: publishers are pre-approved, so publishing makes a page live.
    # Membership of the publisher group is the control.
    if ((Get-PnPList -Identity 'Site Pages' -Connection $conn).EnableModeration) {
        Set-PnPList -Identity 'Site Pages' -EnableModeration $false -Connection $conn | Out-Null
        Write-Output '  ~ Site Pages: content approval turned off'
    }

    # Draft versions on Site Pages, visible only to people who can edit, so readers never see
    # a publisher's unfinished draft. (C1 removes expired posts from news; it no longer unpublishes.)
    $pages = Get-PnPList -Identity 'Site Pages' -Connection $conn
    if (-not $pages.EnableMinorVersions -or "$($pages.DraftVersionVisibility)" -ne 'Author') {
        Set-PnPList -Identity 'Site Pages' -EnableVersioning $true -EnableMinorVersions $true -Connection $conn | Out-Null
        $pages = Get-PnPList -Identity 'Site Pages' -Connection $conn
        $pages.DraftVersionVisibility = [Microsoft.SharePoint.Client.DraftVisibilityType]::Author
        $pages.Update()
        Invoke-PnPQuery -Connection $conn
        Write-Output '  ~ Site Pages: draft versions on, drafts visible to editors only'
    }

    # Video for news posts: same permissions as the site, plays through Stream.
    Set-PnPList -Identity 'News Videos' -EnableVersioning $true -EnableMinorVersions $false -Connection $conn | Out-Null

    if ($CreateTemplates -or $RefreshTemplates) { Ensure-NewsTemplate $conn $site.Template }

    if ($site.Key -eq 'HPUK News') {
        Set-PnPList -Identity 'Notices and Attachments' -EnableVersioning $true -EnableMinorVersions $false -Connection $conn | Out-Null

        # Other News publishers attach files here too, without edit rights on the rest of HPUK News.
        $na = Get-ListGrants $conn 'Notices and Attachments'
        $otherClaim = (Get-GroupClaim $OtherPublisherGroupId)
        if (-not $na.Unique -or $na.Grants -notcontains "$otherClaim=contribute".ToLowerInvariant()) {
            if (-not $na.Unique) { Set-PnPList -Identity 'Notices and Attachments' -BreakRoleInheritance -CopyRoleAssignments -Connection $conn | Out-Null }
            Set-PnPListPermission -Identity 'Notices and Attachments' -User $otherClaim -AddRole 'Contribute' -Connection $conn
            Write-Output '  ~ Notices and Attachments: Other News publishers can contribute'
        }

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
if ($drift.Count) {
    Write-Output "Drift ($($drift.Count)) - the sites don't fully match the schema or intended permissions:"
    $drift | ForEach-Object { Write-Output "  ! $_" }
}
Write-Output 'Manual steps left (see README):'
Write-Output '  1. Site Pages > Settings > Audience targeting: turn on, on both sites.'
Write-Output '  2. IT: associate both sites with the intranet hub; designate HPUK News as an organisation news site.'
Write-Output '  3. Home pages: configure the News web parts (Status = Live filter; Safety section = Category Health and Safety).'
Write-Output '  4. Fill Comms Distribution with one row per port (Enabled = No until destinations are verified).'
Write-Output '  5. Run Set-NewsRetention.ps1 (7-year retention) as a Purview compliance admin.'
if (-not ($CreateTemplates -or $RefreshTemplates)) {
    Write-Output '  6. News page templates: re-run with -CreateTemplates (once per site), or build them by hand.'
} else {
    Write-Output '  6. Open each template once, add a banner image to the title area, check the author byline is empty, and republish it.'
}

if ($drift.Count) {
    throw "$($drift.Count) difference(s) left (listed above). Fix them by hand, or rerun with -FixDrift / -RepairPermissions where offered."
}
