<#
.SYNOPSIS
    Creates (or completes) the SharePoint Lists behind the HPUK Project
    Control Centre - Tier 1 (native SharePoint only, no SPFx, no Power
    Automate consolidation).

.DESCRIPTION
    Reads ../sharepoint/list-schema.json and, for each list it describes:

      * SP_MigrationRegister: expected to already exist live (it's the
        source HPUK_Migration_Register_Bulk_Update_1.xlsx exports from).
        Never created or renamed here - only checked for missing fields,
        which are added without touching anything already there.
      * The other five lists (SP_PageDelivery, SP_Actions, SP_RAID,
        SP_Decisions, SP_ProjectUpdates): created if missing, with every
        field from the schema. Existing fields are left untouched.

    Run interactively, once, by someone with permission to create lists on
    the target site (Site Owner or above) - this is not an Azure Automation
    runbook and nothing calls it from a Power Automate flow (Tier 1 has
    none). Safe to re-run: every step checks first and only adds what's
    missing.

.PARAMETER ClientId
    Application (client) ID of the tenant's PnP PowerShell app registration, for interactive
    sign-in. Create one once with Register-PnPEntraIDAppForInteractiveLogin.

.PARAMETER SiteUrl
    The SharePoint site to apply the schema to, e.g.
    https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects

.NOTES
    Requires PnP.PowerShell (Install-Module PnP.PowerShell -Scope CurrentUser)
    and interactive sign-in (Connect-PnPOnline -Interactive).

    After running this, apply the column formatting in
    ../sharepoint/column-formatting/DeliveryStatus.json to SP_PageDelivery's
    Delivery Status column (list view column settings > Format this column >
    Advanced mode > paste), and add the three Quick Chart web parts
    described in the Control Centre README.
#>
param(
    [Parameter(Mandatory)] [string] $SiteUrl,
    # Your tenant's PnP app registration. Needed for interactive sign-in since PnP retired its shared app (9 Sep 2024).
    [string] $ClientId
)

$ErrorActionPreference = 'Stop'

$schemaPath = Join-Path $PSScriptRoot '..\sharepoint\list-schema.json'
$schema = Get-Content $schemaPath -Raw | ConvertFrom-Json

Write-Host "Connecting to $SiteUrl ..." -ForegroundColor Cyan
if ($ClientId) { Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId }
else {
    Write-Warning 'No -ClientId given: sign-in fails unless a default PnP client ID is set on this machine.'
    Connect-PnPOnline -Url $SiteUrl -Interactive
}
Write-Host "Connected." -ForegroundColor Green

function Add-SchemaField {
    param($List, $Field)

    if (Get-PnPField -List $List -Identity $Field.internalName -ErrorAction SilentlyContinue) {
        Write-Host "    Field '$($Field.internalName)' already exists - skipping." -ForegroundColor DarkGray
        return
    }

    $params = @{
        List         = $List
        DisplayName  = $Field.displayName
        InternalName = $Field.internalName
        Type         = $Field.type
    }
    if ($Field.required) { $params['Required'] = $true }
    if ($Field.choices)  { $params['Choices']  = $Field.choices }

    Write-Host "    Adding field '$($Field.internalName)' ($($Field.type)) ..." -ForegroundColor Cyan
    Add-PnPField @params | Out-Null

    if ($Field.default -and $Field.type -eq 'Choice') {
        Set-PnPField -List $List -Identity $Field.internalName -Values @{ DefaultValue = $Field.default } | Out-Null
    }
}

foreach ($listDef in $schema.lists) {
    Write-Host "`n=== $($listDef.listTitle) ===" -ForegroundColor Magenta

    $list = Get-PnPList -Identity $listDef.listTitle -ErrorAction SilentlyContinue

    if ($null -eq $list) {
        if ($listDef.listTitle -eq 'SP_MigrationRegister') {
            Write-Warning "SP_MigrationRegister not found on this site. This schema documents the live list - it does not create it. Confirm you're pointed at the right site, or import the real list first."
            continue
        }
        Write-Host "  Creating list '$($listDef.listTitle)' ..." -ForegroundColor Cyan
        $list = New-PnPList -Title $listDef.listTitle -Template GenericList -OnQuickLaunch
    }
    else {
        Write-Host "  List already exists - adding any missing fields only." -ForegroundColor Yellow
    }

    foreach ($field in $listDef.fields) {
        if ($field.internalName -eq 'Title') {
            # Built-in field: rename its display name only, never recreate it,
            # and never touch it at all on SP_MigrationRegister (live list).
            if ($listDef.listTitle -ne 'SP_MigrationRegister') {
                Set-PnPField -List $list -Identity 'Title' -Values @{ Title = $field.displayName } | Out-Null
            }
            continue
        }
        Add-SchemaField -List $list -Field $field
    }
}

Write-Host "`nDone. Next: apply sharepoint/column-formatting/DeliveryStatus.json to SP_PageDelivery, then add the Quick Chart web parts (see ../README.md)." -ForegroundColor Green
