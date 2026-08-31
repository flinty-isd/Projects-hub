<#
    02-Provision-Views.ps1

    Creates the filtered views each Control Centre page needs, on top of the
    lists created by 01-Provision-Lists.ps1. Idempotent: safe to re-run.

    Run 01-Provision-Lists.ps1 against the same site first.

    Usage:
        .\02-Provision-Views.ps1 -SiteUrl "https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects"
#>
param(
    [Parameter(Mandatory = $true)][string]$SiteUrl
)

. "$PSScriptRoot\Common.ps1"

Connect-ControlCentreSite -SiteUrl $SiteUrl

# ============================================================
# SP_MigrationRegister views
# ============================================================
Write-Host "`n=== SP_MigrationRegister views ===" -ForegroundColor Magenta
$migrationList = Get-PnPList -Identity "SP_MigrationRegister"
$migrationFields = @("SiteID", "Title", "Department", "Wave", "MigrationStatus", "ReadinessRAG", "PlannedMigration", "MigrationOwner")

Ensure-ControlCentreView -List $migrationList -ViewName "Next 30 Days" -Fields $migrationFields -RowLimit "100" -Query @"
<Where>
  <And>
    <Neq><FieldRef Name='MigrationStatus'/><Value Type='Choice'>Complete</Value></Neq>
    <And>
      <IsNotNull><FieldRef Name='PlannedMigration'/></IsNotNull>
      <Leq><FieldRef Name='PlannedMigration'/><Value Type='DateTime'><Today OffsetDays='30'/></Value></Leq>
    </And>
  </And>
</Where>
<OrderBy><FieldRef Name='PlannedMigration' Ascending='TRUE'/></OrderBy>
"@

Ensure-ControlCentreView -List $migrationList -ViewName "Blocked or Amber Sites" -Fields $migrationFields -RowLimit "200" -Query @"
<Where>
  <Or>
    <Eq><FieldRef Name='MigrationStatus'/><Value Type='Choice'>Blocked</Value></Eq>
    <Or>
      <Eq><FieldRef Name='ReadinessRAG'/><Value Type='Choice'>Amber</Value></Eq>
      <Eq><FieldRef Name='ReadinessRAG'/><Value Type='Choice'>Red</Value></Eq>
    </Or>
  </Or>
</Where>
"@

Ensure-ControlCentreView -List $migrationList -ViewName "Remaining Sites" -Fields $migrationFields -RowLimit "500" -Query @"
<Where><Neq><FieldRef Name='MigrationStatus'/><Value Type='Choice'>Complete</Value></Neq></Where>
"@

Ensure-ControlCentreView -List $migrationList -ViewName "Completed Sites" -Fields ($migrationFields + @("ActualMigration")) -RowLimit "500" -Query @"
<Where><Eq><FieldRef Name='MigrationStatus'/><Value Type='Choice'>Complete</Value></Eq></Where>
<OrderBy><FieldRef Name='ActualMigration' Ascending='FALSE'/></OrderBy>
"@

# ============================================================
# SP_PageDelivery views
# ============================================================
Write-Host "`n=== SP_PageDelivery views ===" -ForegroundColor Magenta
$pageList = Get-PnPList -Identity "SP_PageDelivery"
$pageFields = @("PageID", "Title", "BusinessArea", "ScopeClassification", "Disposition", "DeliveryStatus", "ContentOwner", "DeliveryOwner", "Priority")

Ensure-ControlCentreView -List $pageList -ViewName "Page Backlog" -Fields $pageFields -RowLimit "200" -Query @"
<Where>
  <Or>
    <Eq><FieldRef Name='ScopeClassification'/><Value Type='Choice'>Out of Scope</Value></Eq>
    <Eq><FieldRef Name='ScopeClassification'/><Value Type='Choice'>Scope Change</Value></Eq>
  </Or>
</Where>
"@

Ensure-ControlCentreView -List $pageList -ViewName "Priority Queue" -Fields ($pageFields + @("TargetGoLive")) -RowLimit "200" -Query @"
<Where>
  <And>
    <Or>
      <Eq><FieldRef Name='Priority'/><Value Type='Choice'>Critical</Value></Eq>
      <Eq><FieldRef Name='Priority'/><Value Type='Choice'>High</Value></Eq>
    </Or>
    <Neq><FieldRef Name='DeliveryStatus'/><Value Type='Choice'>Complete</Value></Neq>
  </And>
</Where>
"@

Ensure-ControlCentreView -List $pageList -ViewName "Ownership Gaps" -Fields $pageFields -RowLimit "200" -Query @"
<Where>
  <Or>
    <IsNull><FieldRef Name='ContentOwner'/></IsNull>
    <IsNull><FieldRef Name='DeliveryOwner'/></IsNull>
  </Or>
</Where>
"@

Ensure-ControlCentreView -List $pageList -ViewName "Scope Changes" -Fields $pageFields -RowLimit "200" -Query @"
<Where><Eq><FieldRef Name='ScopeClassification'/><Value Type='Choice'>Scope Change</Value></Eq></Where>
"@

# ============================================================
# SP_Actions views
# ============================================================
Write-Host "`n=== SP_Actions views ===" -ForegroundColor Magenta
$actionsList = Get-PnPList -Identity "SP_Actions"
$actionsFields = @("ActionID", "Title", "Owner", "DueDate", "Status", "RAG", "RelatedSitePage")

Ensure-ControlCentreView -List $actionsList -ViewName "Overdue Actions" -Fields $actionsFields -RowLimit "200" -Query @"
<Where>
  <And>
    <Lt><FieldRef Name='DueDate'/><Value Type='DateTime'><Today/></Value></Lt>
    <Neq><FieldRef Name='Status'/><Value Type='Choice'>Closed</Value></Neq>
  </And>
</Where>
<OrderBy><FieldRef Name='DueDate' Ascending='TRUE'/></OrderBy>
"@

# ============================================================
# SP_RAID views
# ============================================================
Write-Host "`n=== SP_RAID views ===" -ForegroundColor Magenta
$raidList = Get-PnPList -Identity "SP_RAID"
$raidFields = @("RAIDID", "Title", "Type", "Area", "RAG", "Owner", "RelatedSitePage")

Ensure-ControlCentreView -List $raidList -ViewName "Red or Amber RAID" -Fields $raidFields -RowLimit "200" -Query @"
<Where>
  <And>
    <Or>
      <Eq><FieldRef Name='RAG'/><Value Type='Choice'>Red</Value></Eq>
      <Eq><FieldRef Name='RAG'/><Value Type='Choice'>Amber</Value></Eq>
    </Or>
    <Eq><FieldRef Name='Status'/><Value Type='Choice'>Open</Value></Eq>
  </And>
</Where>
"@

# ============================================================
# SP_Decisions views
# ============================================================
Write-Host "`n=== SP_Decisions views ===" -ForegroundColor Magenta
$decisionsList = Get-PnPList -Identity "SP_Decisions"
$decisionsFields = @("DecisionID", "Title", "Owner", "DecisionDate", "RelatedSitePage")

Ensure-ControlCentreView -List $decisionsList -ViewName "Pending Decisions" -Fields $decisionsFields -RowLimit "200" -Query @"
<Where><Eq><FieldRef Name='Status'/><Value Type='Choice'>Pending</Value></Eq></Where>
"@

# ============================================================
# SP_ProjectUpdates views
# ============================================================
Write-Host "`n=== SP_ProjectUpdates views ===" -ForegroundColor Magenta
$updatesList = Get-PnPList -Identity "SP_ProjectUpdates"
$updatesFields = @("SnapshotDate", "SitesComplete", "RemainingSites", "OverallRAG", "OpenRisks", "OverdueActions", "PagesOutstanding", "Commentary")

Ensure-ControlCentreView -List $updatesList -ViewName "Weekly History" -Fields $updatesFields -RowLimit "100" -Query @"
<OrderBy><FieldRef Name='SnapshotDate' Ascending='FALSE'/></OrderBy>
"@

Write-Host "`nAll views checked/created. Next: 03-Provision-Pages.ps1" -ForegroundColor Green
