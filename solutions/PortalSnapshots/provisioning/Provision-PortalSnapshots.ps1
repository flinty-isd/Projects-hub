<#
.SYNOPSIS
    Creates the lists the portal snapshot flows read, and uploads the portal templates.

.DESCRIPTION
    Reads sharepoint/list-schema.json and:
      * creates each list that doesn't exist yet on its site (Asset lists on -AssetSiteUrl,
        Control Board lists on -BoardSiteUrl, governance registers on -GovernanceSiteUrl), turns
        on versioning and adds missing columns. Lists marked "existing" (the Site Register and
        Decision Log from the SharePointGovernance solution) are never created: the script only
        checks they exist and have the columns flow P3 reads
      * uploads templates/*.html to the templates folder on -PortalSiteUrl (default
        SiteAssets/PortalTemplates). Flows P1-P3 read these, fill in the snapshot block and write
        the pages to the pages folder (default Site Pages)

    Safe to re-run: existing lists and columns are left alone; templates are overwritten, which
    is how a new portal version is rolled out.

.NOTES
    Requires PnP.PowerShell 2.x, run as an owner of each site (or an app registration with
    Sites.FullControl.All). Not yet run against a tenant: try it on test sites first.

.EXAMPLE
    ./Provision-PortalSnapshots.ps1 -PortalSiteUrl https://contoso.sharepoint.com/sites/hpuk-it-portals `
        -AssetSiteUrl https://contoso.sharepoint.com/sites/hpuk-it-assets `
        -BoardSiteUrl https://contoso.sharepoint.com/sites/hpuk-pmo-spo `
        -GovernanceSiteUrl https://contoso.sharepoint.com/sites/hpuk-pof-it-enterprisegovernance -Interactive
#>
param(
    [Parameter(Mandatory)] [string] $PortalSiteUrl,
    [Parameter(Mandatory)] [string] $AssetSiteUrl,
    [Parameter(Mandatory)] [string] $BoardSiteUrl,
    [Parameter(Mandatory)] [string] $GovernanceSiteUrl,
    [string] $TemplatesFolder = 'SiteAssets/PortalTemplates',
    [string] $ClientId,
    [string] $Tenant,
    [string] $Thumbprint,
    [switch] $Interactive,
    [switch] $SkipLists,
    [switch] $SkipTemplates
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$schema = Get-Content (Join-Path $root 'sharepoint/list-schema.json') -Raw | ConvertFrom-Json
$sites = @{ asset = $AssetSiteUrl.TrimEnd('/'); board = $BoardSiteUrl.TrimEnd('/'); governance = $GovernanceSiteUrl.TrimEnd('/') }

$connections = @{}
function Get-Conn([string] $url) {
    if (-not $connections.ContainsKey($url)) {
        $connections[$url] = if ($Interactive) { Connect-PnPOnline -Url $url -Interactive -ReturnConnection }
                             else { Connect-PnPOnline -Url $url -ClientId $ClientId -Tenant $Tenant -Thumbprint $Thumbprint -ReturnConnection }
    }
    $connections[$url]
}

function Escape-Xml([string] $s) { [System.Security.SecurityElement]::Escape($s) }

function Get-FieldXml($f) {
    $name = $f.internalName
    $attrs = "Name=`"$name`" StaticName=`"$name`" DisplayName=`"$(Escape-Xml $f.displayName)`" Required=`"$(if ($f.required) {'TRUE'} else {'FALSE'})`""
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
        default    { throw "Unknown field type $($f.type) for $name" }
    }
}

# --- Source lists --------------------------------------------------------------------
if (-not $SkipLists) {
    foreach ($l in $schema.lists) {
        $conn = Get-Conn $sites[$l.site]
        $list = Get-PnPList -Identity $l.listTitle -Connection $conn -ErrorAction SilentlyContinue
        $existing = if ($list) { (Get-PnPField -List $l.listTitle -Connection $conn).InternalName } else { @() }

        if ($l.existing) {
            # Owned by another solution: check, never create or change.
            if (-not $list) { Write-Warning "$($l.listTitle) not found on $($sites[$l.site]). Deploy the $($l.existing) solution's lists first, or point -GovernanceSiteUrl at its site."; continue }
            $missing = $l.fields.internalName | Where-Object { $existing -notcontains $_ }
            if ($missing) { Write-Warning "$($l.listTitle) is missing columns flow P3 reads: $($missing -join ', ')" }
            else { Write-Output "  = $($l.listTitle) ($($l.existing)) found with the columns P3 reads" }
            continue
        }

        if (-not $list) {
            New-PnPList -Title $l.listTitle -Url $l.url -Template $l.template -OnQuickLaunch -Connection $conn | Out-Null
            Set-PnPList -Identity $l.listTitle -Description $l.listDescription -EnableVersioning $true -Connection $conn | Out-Null
            Write-Output "  + list $($l.listTitle) on $($sites[$l.site])"
            $existing = (Get-PnPField -List $l.listTitle -Connection $conn).InternalName
        }
        $added = @()
        foreach ($f in $l.fields) {
            if ($existing -contains $f.internalName) { continue }
            Add-PnPFieldFromXml -List $l.listTitle -FieldXml (Get-FieldXml $f) -Connection $conn | Out-Null
            if ($f.indexed) { Set-PnPField -List $l.listTitle -Identity $f.internalName -Values @{ Indexed = $true } -Connection $conn | Out-Null }
            $added += $f.internalName
            Write-Output "    + $($l.listTitle).$($f.internalName)"
        }
        if ($added.Count -gt 0) {
            $view = Get-PnPView -List $l.listTitle -Connection $conn | Where-Object DefaultView
            Set-PnPView -List $l.listTitle -Identity $view.Id -Fields (@($view.ViewFields) + $added | Select-Object -Unique) -Connection $conn | Out-Null
        }
    }
}

# --- Templates -----------------------------------------------------------------------
if (-not $SkipTemplates) {
    $conn = Get-Conn $PortalSiteUrl.TrimEnd('/')
    Resolve-PnPFolder -SiteRelativePath $TemplatesFolder -Connection $conn | Out-Null
    foreach ($file in Get-ChildItem (Join-Path $root 'templates') -Filter *.html) {
        Add-PnPFile -Path $file.FullName -Folder $TemplatesFolder -Connection $conn | Out-Null
        Write-Output "  + $TemplatesFolder/$($file.Name)"
    }
}

Write-Output ''
Write-Output 'Next:'
Write-Output "  1. Site Pages on $PortalSiteUrl : Library settings > File types > Allow HTML files (the flows write .html pages there)."
Write-Output '  2. Import the PortalSnapshots solution, set its environment variables, turn on P1-P3, then set PortalSnapshotsEnabled = Yes and run each flow once.'
Write-Output '  3. Governance portal SAM tab: load the SAM CSV in the published page, Save Snapshot HTML, upload it over SitePages/hpuk-it-governance-portal.html once; P3 then carries the SAM rows forward.'
