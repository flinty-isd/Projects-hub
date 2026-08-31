<#
    Shared helpers for the HPUK Project Control Centre provisioning scripts.
    Dot-source this from the numbered scripts; it does not run anything by itself.

    Requires the PnP.PowerShell module:
        Install-Module -Name PnP.PowerShell -Scope CurrentUser
#>

function Connect-ControlCentreSite {
    param(
        [Parameter(Mandatory = $true)][string]$SiteUrl
    )
    Write-Host "Connecting to $SiteUrl ..." -ForegroundColor Cyan
    Connect-PnPOnline -Url $SiteUrl -Interactive
    Write-Host "Connected." -ForegroundColor Green
}

# Creates the list if it doesn't already exist. Always returns the list
# (existing or newly created), so it's safe to re-run this script against a
# site where some lists (e.g. SP_MigrationRegister) already exist.
function Ensure-ControlCentreList {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$TitleFieldDisplayName
    )
    $list = Get-PnPList -Identity $Title -ErrorAction SilentlyContinue
    if ($null -ne $list) {
        Write-Host "  List '$Title' already exists - leaving it as is, only adding missing fields." -ForegroundColor Yellow
        return $list
    }
    Write-Host "  Creating list '$Title' ..." -ForegroundColor Cyan
    $list = New-PnPList -Title $Title -Template GenericList -OnQuickLaunch
    Set-PnPField -List $list -Identity "Title" -Values @{ Title = $TitleFieldDisplayName }
    return $list
}

# Adds a field only if a field with that internal name doesn't already exist
# on the list, so the script is safe to re-run.
function Ensure-ControlCentreField {
    param(
        [Parameter(Mandatory = $true)]$List,
        [Parameter(Mandatory = $true)][string]$InternalName,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][string]$Type,
        [string[]]$Choices,
        [switch]$Required
    )
    $existing = Get-PnPField -List $List -Identity $InternalName -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        Write-Host "    Field '$InternalName' already exists - skipping." -ForegroundColor DarkGray
        return
    }

    $params = @{
        List         = $List
        DisplayName  = $DisplayName
        InternalName = $InternalName
        Type         = $Type
        AddToDefaultView = $true
    }
    if ($Required) { $params["Required"] = $true }
    if ($Choices)  { $params["Choices"]  = $Choices }

    Write-Host "    Adding field '$InternalName' ($Type) ..." -ForegroundColor Cyan
    Add-PnPField @params | Out-Null
}

# Creates a view only if it doesn't already exist.
function Ensure-ControlCentreView {
    param(
        [Parameter(Mandatory = $true)]$List,
        [Parameter(Mandatory = $true)][string]$ViewName,
        [Parameter(Mandatory = $true)][string[]]$Fields,
        [string]$Query = "",
        [string]$RowLimit = "100",
        [switch]$SetAsDefault
    )
    $existing = Get-PnPView -List $List -Identity $ViewName -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        Write-Host "    View '$ViewName' already exists - skipping." -ForegroundColor DarkGray
        return $existing
    }
    Write-Host "    Adding view '$ViewName' ..." -ForegroundColor Cyan
    $view = Add-PnPView -List $List -Title $ViewName -Fields $Fields -Query $Query -RowLimit $RowLimit -SetAsDefault:$SetAsDefault
    return $view
}

# Adds a List web part bound to a specific list + view. This is the single
# most likely thing to need a manual touch-up afterwards: the client-side
# List web part's property schema isn't publicly documented and has shifted
# between SharePoint Online releases, so this uses the commonly-seen/
# community-verified property set. If a web part shows up blank or broken
# after running this, open the page, delete that web part, and re-add "List"
# from the picker instead - everything else on the page (sections, banners,
# which list/view each spot is meant to show) is unaffected.
function Add-ControlCentreListWebPart {
    param(
        [Parameter(Mandatory = $true)]$Page,
        [Parameter(Mandatory = $true)]$List,
        [Parameter(Mandatory = $true)][string]$ViewName,
        [Parameter(Mandatory = $true)][int]$Section,
        [Parameter(Mandatory = $true)][int]$Column,
        [string]$Title
    )
    $view = Get-PnPView -List $List -Identity $ViewName
    $props = @{
        selectedListId    = $List.Id.ToString()
        selectedViewId    = $view.Id.ToString()
        webpartHeightKey  = 4
        listTitle         = $List.Title
        isDocumentLibrary = $false
    }
    try {
        Add-PnPPageWebPart -Page $Page -DefaultWebPartType List -Section $Section -Column $Column -WebPartProperties $props -WebPartTitle $Title | Out-Null
    }
    catch {
        Write-Warning "Could not add List web part for '$($List.Title)' / view '$ViewName' on page '$($Page.Name)': $($_.Exception.Message)"
        Write-Warning "Add it manually: open the page, insert a 'List' web part in section $Section column $Column, and pick '$($List.Title)' / '$ViewName'."
    }
}

# Shared choice sets, taken from the real HPUK_Migration_Register_Bulk_Update
# workbook's Choices sheet where noted, so new lists stay consistent with the
# already-live SP_MigrationRegister list.
$RagChoices               = @("Green", "Amber", "Red")                                   # matches live ReadinessRAG values (minus "Not Assessed")
$ReadinessChoices         = @("Green", "Amber", "Red", "Not Assessed")                    # from live Choices sheet
$MigrationStatusChoices   = @("Not Started", "Planned", "Readiness Review", "Ready", "In Progress", "Migrated", "UAT", "Awaiting Sign-off", "Complete", "Blocked", "On Hold", "Not Required")  # from live Choices sheet
$UatStatusChoices         = @("Not Required", "Not Started", "Planned", "In Progress", "Passed", "Failed", "Conditional Acceptance")  # from live Choices sheet
$MigrationBusinessSignoffChoices = @("Not Required", "Pending", "Approved", "Rejected")   # from live Choices sheet
$MigrationMethodChoices   = @("ShareGate", "Manual", "Rebuild", "Hybrid", "Other")         # from live Choices sheet
$DepartmentChoices        = @("Terminal Operations", "Engineering & Maintenance", "HSE", "Commercial", "Finance", "HR", "IT", "Corporate Affairs", "Customer Service", "Operations", "Other")  # ASSUMED - adjust to your real department taxonomy
$WaveChoices              = @("Wave 0 (Pilot)", "Wave 1", "Wave 2", "Wave 3", "Wave 4", "Wave 5", "Not specified")  # ASSUMED - adjust to your real wave plan
