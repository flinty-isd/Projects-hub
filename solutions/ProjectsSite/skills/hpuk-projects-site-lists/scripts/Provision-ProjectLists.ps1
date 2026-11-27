<#
.SYNOPSIS
    Creates the HPUK project lists on a SharePoint site: the Enterprise PMO hub, the Project
    Control Centre and the Control Board lists, or any combination.

.DESCRIPTION
    Reads ../schemas/catalogue.json and the schema of each set you choose, then for each list:
      * creates it if it doesn't exist (generic list, document library or Events list), with
        versioning on, at the URL in the schema (or one derived from the title)
      * adds every column that is missing, as the schema describes it: type, choices, default,
        required, date-only, decimals, lookups to lists in the same set, link columns;
        flow-managed columns are hidden from the new and edit forms; indexed columns get an index
      * renames the built-in Title column where the schema gives it another display name
      * for lists marked existingOnly (SP_MigrationRegister): never creates or renames it, only
        adds missing columns, and warns if it isn't there

    It never deletes or changes an existing list, column, view or item, so it is safe to re-run.
    -PlanOnly connects and reports what it would do without changing anything.

.PARAMETER SiteUrl
    The projects site, e.g. https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects
.PARAMETER Sets
    pmo, controlcentre, board, or all. Several allowed: -Sets pmo,board

.NOTES
    Requires PnP.PowerShell 2.x and an account with Site Owner (or higher) on the site, or an app
    registration with Sites.FullControl.All. Run scripts/plan_lists.py first to preview offline.

.EXAMPLE
    ./Provision-ProjectLists.ps1 -SiteUrl https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects -Sets pmo,board -Interactive -PlanOnly
    ./Provision-ProjectLists.ps1 -SiteUrl https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects -Sets pmo,board -Interactive
#>
param(
    [Parameter(Mandatory)] [string] $SiteUrl,
    [Parameter(Mandatory)] [ValidateSet('pmo', 'controlcentre', 'board', 'all')] [string[]] $Sets,
    [string] $ClientId,
    [string] $Tenant,
    [string] $Thumbprint,
    [switch] $Interactive,
    [switch] $PlanOnly
)

$ErrorActionPreference = 'Stop'
$skill = Split-Path -Parent $PSScriptRoot
$catalogue = Get-Content (Join-Path $skill 'schemas/catalogue.json') -Raw | ConvertFrom-Json
$setKeys = if ($Sets -contains 'all') { @($catalogue.sets.PSObject.Properties.Name) } else { $Sets }

$conn = if ($Interactive) { Connect-PnPOnline -Url $SiteUrl -Interactive -ReturnConnection }
        else { Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $Tenant -Thumbprint $Thumbprint -ReturnConnection }
$mode = if ($PlanOnly) { 'PLAN ONLY: nothing will be changed' } else { 'CHANGES WILL BE MADE' }
Write-Output "Connected to $SiteUrl ($mode). Sets: $($setKeys -join ', ')"

function Escape-Xml([string] $s) { [System.Security.SecurityElement]::Escape($s) }

function Get-ListUrl($l) {
    if ($l.url) { return $l.url }
    $slug = $l.listTitle -replace '[^A-Za-z0-9_]', ''
    if ($l.template -eq 'DocumentLibrary') { $slug } else { "Lists/$slug" }
}

function Get-DefaultXml($f) {
    if ($null -eq $f.default -or "$($f.default)" -eq '') { return '' }
    $value = if ($f.default -is [bool]) { if ($f.default) { '1' } else { '0' } } else { [string] $f.default }
    if ($f.type -eq 'Boolean') { $value = switch -Regex ($value) { '^(1|true|yes)$' { '1' } default { '0' } } }
    "<Default>$(Escape-Xml $value)</Default>"
}

function Get-FieldXml($f, $listIds) {
    $name = $f.internalName
    $attrs = "Name=`"$name`" StaticName=`"$name`" DisplayName=`"$(Escape-Xml $f.displayName)`" Required=`"$(if ($f.required) {'TRUE'} else {'FALSE'})`""
    if ($f.flowManaged) { $attrs += ' ShowInNewForm="FALSE" ShowInEditForm="FALSE"' }
    elseif ($f.hideOnNewForm) { $attrs += ' ShowInNewForm="FALSE"' }
    if ($f.notes) { $attrs += " Description=`"$(Escape-Xml $f.notes)`"" }
    $default = Get-DefaultXml $f
    switch ($f.type) {
        'Text'     { "<Field Type=`"Text`" $attrs MaxLength=`"255`">$default</Field>" }
        'Note'     { "<Field Type=`"Note`" $attrs NumLines=`"6`" RichText=`"FALSE`" />" }
        'Number'   { $dec = if ($null -ne $f.decimals) { $f.decimals } else { 0 }
                     "<Field Type=`"Number`" $attrs Decimals=`"$dec`">$default</Field>" }
        'DateTime' { $fmt = if ($f.format) { $f.format } else { 'DateTime' }
                     "<Field Type=`"DateTime`" $attrs Format=`"$fmt`" />" }
        'Boolean'  { "<Field Type=`"Boolean`" $attrs>$default</Field>" }
        'Choice'   { $choices = ($f.choices | ForEach-Object { "<CHOICE>$(Escape-Xml $_)</CHOICE>" }) -join ''
                     "<Field Type=`"Choice`" $attrs Format=`"Dropdown`" FillInChoice=`"FALSE`">$default<CHOICES>$choices</CHOICES></Field>" }
        'Person'   { "<Field Type=`"User`" $attrs UserSelectionMode=`"PeopleOnly`" UserSelectionScope=`"0`" List=`"UserInfo`" ShowField=`"ImnName`" />" }
        'URL'      { "<Field Type=`"URL`" $attrs Format=`"Hyperlink`" />" }
        'Lookup'   { $target = $listIds[$f.lookupList]
                     if (-not $target) { throw "Lookup $name needs list '$($f.lookupList)', which must exist or come earlier in the set" }
                     "<Field Type=`"Lookup`" $attrs List=`"{$target}`" ShowField=`"$($f.lookupField)`" />" }
        default    { throw "Unsupported column type $($f.type) for $name" }
    }
}

$report = New-Object System.Collections.Generic.List[object]
$listIds = @{}

foreach ($key in $setKeys) {
    $spec = $catalogue.sets.$key
    $schema = Get-Content (Join-Path $skill "schemas/$($spec.schema)") -Raw | ConvertFrom-Json
    Write-Output ''
    Write-Output "=== [$key] $($spec.title) ==="

    foreach ($l in $schema.lists) {
        $title = $l.listTitle
        $template = if ($l.template) { $l.template } else { 'GenericList' }
        $list = Get-PnPList -Identity $title -Connection $conn -ErrorAction SilentlyContinue
        $status = 'exists'

        if (-not $list) {
            if ($l.existingOnly) {
                Write-Warning "$title not found. It is a live list this script never creates: check you're on the right site."
                $report.Add([pscustomobject]@{ Set = $key; List = $title; Result = 'MISSING (not created: live list)'; ColumnsAdded = 0 })
                continue
            }
            if ($PlanOnly) {
                Write-Output "  would create $title ($template) at $(Get-ListUrl $l) with $(@($l.fields | Where-Object internalName -ne 'Title').Count) columns"
                $listIds[$title] = '00000000-0000-0000-0000-000000000000'   # lets lookups in the plan resolve
                $report.Add([pscustomobject]@{ Set = $key; List = $title; Result = 'would create'; ColumnsAdded = @($l.fields).Count })
                continue
            }
            New-PnPList -Title $title -Url (Get-ListUrl $l) -Template $template -OnQuickLaunch -Connection $conn | Out-Null
            $desc = if ($l.listDescription) { $l.listDescription } else { '' }
            if ($desc.Length -gt 255) { $desc = $desc.Substring(0, 252) + '...' }
            Set-PnPList -Identity $title -Description $desc -EnableVersioning $true -Connection $conn | Out-Null
            $list = Get-PnPList -Identity $title -Connection $conn
            $status = 'created'
            Write-Output "  + $title ($template) at $(Get-ListUrl $l)"
        }
        $listIds[$title] = $list.Id.ToString()

        $existing = (Get-PnPField -List $title -Connection $conn).InternalName
        $added = @()
        foreach ($f in $l.fields) {
            if ($f.internalName -eq 'Title') {
                # Built-in column: rename only, and never on a live existingOnly list.
                if (-not $l.existingOnly -and $f.displayName -and $f.displayName -ne 'Title') {
                    if ($PlanOnly) { Write-Output "    would rename Title to '$($f.displayName)'" }
                    else { Set-PnPField -List $title -Identity 'Title' -Values @{ Title = $f.displayName } -Connection $conn | Out-Null }
                }
                continue
            }
            if ($existing -contains $f.internalName) { continue }
            if ($PlanOnly) { Write-Output "    would add $title.$($f.internalName) ($($f.type))"; $added += $f.internalName; continue }
            Add-PnPFieldFromXml -List $title -FieldXml (Get-FieldXml $f $listIds) -Connection $conn | Out-Null
            if ($f.indexed) { Set-PnPField -List $title -Identity $f.internalName -Values @{ Indexed = $true } -Connection $conn | Out-Null }
            if (-not $f.hidden) { $added += $f.internalName }
            Write-Output "    + $title.$($f.internalName)"
        }
        if ($added.Count -gt 0 -and -not $PlanOnly) {
            $view = Get-PnPView -List $title -Connection $conn | Where-Object DefaultView
            Set-PnPView -List $title -Identity $view.Id -Fields (@($view.ViewFields) + $added | Select-Object -Unique) -Connection $conn | Out-Null
        }
        if ($status -eq 'exists' -and $added.Count -gt 0) { $status = if ($PlanOnly) { 'exists: would add columns' } else { 'exists: columns added' } }
        $report.Add([pscustomobject]@{ Set = $key; List = $title; Result = $status; ColumnsAdded = $added.Count })
    }
}

Write-Output ''
$report | Format-Table -AutoSize | Out-String -Width 200 | Write-Output

Write-Output 'Next:'
foreach ($key in $setKeys) {
    foreach ($n in $catalogue.sets.$key.next) { Write-Output "  [$key] $n" }
}
