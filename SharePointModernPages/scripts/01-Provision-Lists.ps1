<#
    01-Provision-Lists.ps1

    Creates (or completes) the six authoritative SharePoint Lists behind the
    HPUK Project Control Centre, per the Implementation Specification, section 2.

    Idempotent: safe to re-run. SP_MigrationRegister is expected to already
    exist (per HPUK_Migration_Register_Bulk_Update_1.xlsx, which exports from
    it) - this script will leave it alone and only add any fields it finds
    missing. The other five lists are created if they don't exist.

    Field names for SP_MigrationRegister match the real, live list exactly,
    as seen in the bulk-update workbook's "Migration Register Update" sheet
    header row. The other five lists use this script's own naming convention
    (see README.md) - rename them here first if your tenant already has
    different names for any of them.

    Usage:
        .\01-Provision-Lists.ps1 -SiteUrl "https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects"
#>
param(
    [Parameter(Mandatory = $true)][string]$SiteUrl
)

. "$PSScriptRoot\Common.ps1"

Connect-ControlCentreSite -SiteUrl $SiteUrl

# ============================================================
# 1. SP_MigrationRegister - Implementation Specification 2.1
# ============================================================
Write-Host "`n=== SP_MigrationRegister ===" -ForegroundColor Magenta
$migrationList = Ensure-ControlCentreList -Title "SP_MigrationRegister" -TitleFieldDisplayName "Site Title"

Ensure-ControlCentreField -List $migrationList -InternalName "SiteID"             -DisplayName "Site ID"              -Type Text     -Required
Ensure-ControlCentreField -List $migrationList -InternalName "SiteURL"            -DisplayName "Site URL"             -Type URL
Ensure-ControlCentreField -List $migrationList -InternalName "LegacyURL"          -DisplayName "Legacy URL"           -Type Text
Ensure-ControlCentreField -List $migrationList -InternalName "Department"         -DisplayName "Department"           -Type Choice   -Choices $DepartmentChoices -Required
Ensure-ControlCentreField -List $migrationList -InternalName "Wave"               -DisplayName "Wave"                 -Type Choice   -Choices $WaveChoices
Ensure-ControlCentreField -List $migrationList -InternalName "Tranche"            -DisplayName "Tranche"              -Type Text
Ensure-ControlCentreField -List $migrationList -InternalName "BusinessOwner"      -DisplayName "Business Owner"       -Type User     -Required
Ensure-ControlCentreField -List $migrationList -InternalName "MigrationOwner"     -DisplayName "Migration Owner"      -Type User     -Required
Ensure-ControlCentreField -List $migrationList -InternalName "MigrationStatus"    -DisplayName "Migration Status"     -Type Choice   -Choices $MigrationStatusChoices -Required
Ensure-ControlCentreField -List $migrationList -InternalName "ReadinessRAG"       -DisplayName "Readiness RAG"        -Type Choice   -Choices $ReadinessChoices -Required
Ensure-ControlCentreField -List $migrationList -InternalName "ReadinessScore"     -DisplayName "Readiness Score"      -Type Number
Ensure-ControlCentreField -List $migrationList -InternalName "PlannedMigration"   -DisplayName "Planned Migration"    -Type DateTime
Ensure-ControlCentreField -List $migrationList -InternalName "ActualMigration"    -DisplayName "Actual Migration"     -Type DateTime
Ensure-ControlCentreField -List $migrationList -InternalName "UATStatus"          -DisplayName "UAT Status"           -Type Choice   -Choices $UatStatusChoices
Ensure-ControlCentreField -List $migrationList -InternalName "BusinessSignoff"    -DisplayName "Business Sign-off"    -Type Choice   -Choices $MigrationBusinessSignoffChoices
Ensure-ControlCentreField -List $migrationList -InternalName "BlockerDependency"  -DisplayName "Blocker / Dependency" -Type Note
Ensure-ControlCentreField -List $migrationList -InternalName "DataSizeGB"         -DisplayName "Data Size (GB)"       -Type Number
Ensure-ControlCentreField -List $migrationList -InternalName "MigrationMethod"    -DisplayName "Migration Method"     -Type Choice   -Choices $MigrationMethodChoices
Ensure-ControlCentreField -List $migrationList -InternalName "LastReviewed"       -DisplayName "Last Reviewed"        -Type DateTime -Required
Ensure-ControlCentreField -List $migrationList -InternalName "ReviewNotes"        -DisplayName "Review Notes"         -Type Note

# ============================================================
# 2. SP_PageDelivery - Implementation Specification 2.2
# ============================================================
Write-Host "`n=== SP_PageDelivery ===" -ForegroundColor Magenta
$pageList = Ensure-ControlCentreList -Title "SP_PageDelivery" -TitleFieldDisplayName "Page Name"

Ensure-ControlCentreField -List $pageList -InternalName "PageID"               -DisplayName "Page ID"               -Type Text     -Required
Ensure-ControlCentreField -List $pageList -InternalName "BusinessArea"         -DisplayName "Business Area"         -Type Text     -Required
Ensure-ControlCentreField -List $pageList -InternalName "ScopeClassification"  -DisplayName "Scope Classification"  -Type Choice   -Choices @("Original Scope", "Out of Scope", "Scope Change") -Required
Ensure-ControlCentreField -List $pageList -InternalName "ExistingURL"          -DisplayName "Existing URL"          -Type URL
Ensure-ControlCentreField -List $pageList -InternalName "TargetURL"            -DisplayName "Target URL"            -Type URL
Ensure-ControlCentreField -List $pageList -InternalName "Disposition"          -DisplayName "Disposition"           -Type Choice   -Choices @("Migrate", "Create-Rebuild", "Merge", "Retire", "Assess") -Required
Ensure-ControlCentreField -List $pageList -InternalName "ContentOwner"         -DisplayName "Content Owner"         -Type User     -Required
Ensure-ControlCentreField -List $pageList -InternalName "DeliveryOwner"        -DisplayName "Delivery Owner"        -Type User     -Required
Ensure-ControlCentreField -List $pageList -InternalName "Priority"             -DisplayName "Priority"              -Type Choice   -Choices @("Critical", "High", "Medium", "Low") -Required
Ensure-ControlCentreField -List $pageList -InternalName "DeliveryStatus"       -DisplayName "Delivery Status"       -Type Choice   -Choices @("Assess", "Define", "Design", "Build", "UAT", "Sign-off", "Complete") -Required
Ensure-ControlCentreField -List $pageList -InternalName "DesignApproved"       -DisplayName "Design Approved"       -Type Boolean
Ensure-ControlCentreField -List $pageList -InternalName "ContentReady"         -DisplayName "Content Ready"         -Type Boolean
Ensure-ControlCentreField -List $pageList -InternalName "UATStatus"            -DisplayName "UAT Status"            -Type Choice   -Choices $UatStatusChoices
Ensure-ControlCentreField -List $pageList -InternalName "BusinessSignoff"      -DisplayName "Business Sign-off"     -Type Boolean
Ensure-ControlCentreField -List $pageList -InternalName "TargetGoLive"         -DisplayName "Target Go-live"        -Type DateTime
Ensure-ControlCentreField -List $pageList -InternalName "RelatedActionRisk"    -DisplayName "Related Action/Risk"   -Type Text

# ============================================================
# 3. SP_Actions - Implementation Specification 2.3
# ============================================================
Write-Host "`n=== SP_Actions ===" -ForegroundColor Magenta
$actionsList = Ensure-ControlCentreList -Title "SP_Actions" -TitleFieldDisplayName "Action"

Ensure-ControlCentreField -List $actionsList -InternalName "ActionID"          -DisplayName "Action ID"      -Type Text     -Required
Ensure-ControlCentreField -List $actionsList -InternalName "Owner"             -DisplayName "Owner"          -Type User     -Required
Ensure-ControlCentreField -List $actionsList -InternalName "DueDate"           -DisplayName "Due Date"       -Type DateTime -Required
Ensure-ControlCentreField -List $actionsList -InternalName "Status"            -DisplayName "Status"         -Type Choice   -Choices @("Open", "Closed", "On Hold") -Required
Ensure-ControlCentreField -List $actionsList -InternalName "RAG"               -DisplayName "RAG"            -Type Choice   -Choices $RagChoices -Required
Ensure-ControlCentreField -List $actionsList -InternalName "Source"            -DisplayName "Source"         -Type Choice   -Choices @("Migration Register", "Page Delivery Register", "Governance")
Ensure-ControlCentreField -List $actionsList -InternalName "RelatedSitePage"   -DisplayName "Related Site/Page" -Type Text

# ============================================================
# 4. SP_RAID - Implementation Specification 2.3
# ============================================================
Write-Host "`n=== SP_RAID ===" -ForegroundColor Magenta
$raidList = Ensure-ControlCentreList -Title "SP_RAID" -TitleFieldDisplayName "Description"

Ensure-ControlCentreField -List $raidList -InternalName "RAIDID"           -DisplayName "RAID ID"        -Type Text     -Required
Ensure-ControlCentreField -List $raidList -InternalName "Type"             -DisplayName "Type"           -Type Choice   -Choices @("Risk", "Assumption", "Issue", "Dependency") -Required
Ensure-ControlCentreField -List $raidList -InternalName "Area"             -DisplayName "Area"           -Type Choice   -Choices @("Migration", "Page Delivery", "Governance") -Required
Ensure-ControlCentreField -List $raidList -InternalName "Likelihood"       -DisplayName "Likelihood"     -Type Choice   -Choices @("Low", "Medium", "High")
Ensure-ControlCentreField -List $raidList -InternalName "Impact"           -DisplayName "Impact"         -Type Choice   -Choices @("Low", "Medium", "High")
Ensure-ControlCentreField -List $raidList -InternalName "RAG"              -DisplayName "RAG"            -Type Choice   -Choices $RagChoices -Required
Ensure-ControlCentreField -List $raidList -InternalName "Owner"            -DisplayName "Owner"          -Type User     -Required
Ensure-ControlCentreField -List $raidList -InternalName "TargetDate"       -DisplayName "Target Date"    -Type DateTime
Ensure-ControlCentreField -List $raidList -InternalName "Status"           -DisplayName "Status"         -Type Choice   -Choices @("Open", "Closed") -Required
Ensure-ControlCentreField -List $raidList -InternalName "RelatedSitePage"  -DisplayName "Related Site/Page" -Type Text

# ============================================================
# 5. SP_Decisions - Implementation Specification 2.3
# ============================================================
Write-Host "`n=== SP_Decisions ===" -ForegroundColor Magenta
$decisionsList = Ensure-ControlCentreList -Title "SP_Decisions" -TitleFieldDisplayName "Decision"

Ensure-ControlCentreField -List $decisionsList -InternalName "DecisionID"      -DisplayName "Decision ID"    -Type Text     -Required
Ensure-ControlCentreField -List $decisionsList -InternalName "DecisionDate"    -DisplayName "Date"           -Type DateTime -Required
Ensure-ControlCentreField -List $decisionsList -InternalName "Owner"           -DisplayName "Owner"          -Type User     -Required
Ensure-ControlCentreField -List $decisionsList -InternalName "Rationale"       -DisplayName "Rationale"      -Type Note
Ensure-ControlCentreField -List $decisionsList -InternalName "Status"          -DisplayName "Status"         -Type Choice   -Choices @("Approved", "Pending", "Rejected") -Required
Ensure-ControlCentreField -List $decisionsList -InternalName "RelatedSitePage" -DisplayName "Related Site/Page" -Type Text

# ============================================================
# 6. SP_ProjectUpdates - Implementation Specification 2.3
# ============================================================
Write-Host "`n=== SP_ProjectUpdates ===" -ForegroundColor Magenta
$updatesList = Ensure-ControlCentreList -Title "SP_ProjectUpdates" -TitleFieldDisplayName "Snapshot Label"

Ensure-ControlCentreField -List $updatesList -InternalName "SnapshotDate"      -DisplayName "Snapshot Date"      -Type DateTime -Required
Ensure-ControlCentreField -List $updatesList -InternalName "SitesComplete"     -DisplayName "Sites Complete"     -Type Number   -Required
Ensure-ControlCentreField -List $updatesList -InternalName "RemainingSites"    -DisplayName "Remaining Sites"    -Type Number   -Required
Ensure-ControlCentreField -List $updatesList -InternalName "OverallRAG"        -DisplayName "Overall RAG"        -Type Choice   -Choices $RagChoices -Required
Ensure-ControlCentreField -List $updatesList -InternalName "OpenRisks"         -DisplayName "Open Risks"         -Type Number
Ensure-ControlCentreField -List $updatesList -InternalName "OverdueActions"    -DisplayName "Overdue Actions"    -Type Number
Ensure-ControlCentreField -List $updatesList -InternalName "PagesOutstanding"  -DisplayName "Pages Outstanding"  -Type Number
Ensure-ControlCentreField -List $updatesList -InternalName "Commentary"        -DisplayName "Commentary"         -Type Note

Write-Host "`nAll six lists checked/created. Next: 02-Provision-Views.ps1" -ForegroundColor Green
