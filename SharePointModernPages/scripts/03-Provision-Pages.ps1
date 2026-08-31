<#
    03-Provision-Pages.ps1

    Creates the four modern SharePoint pages from the Implementation
    Specification, section 3, wired to the lists and views created by
    01-Provision-Lists.ps1 and 02-Provision-Views.ps1.

    Run those two scripts against the same site first.

    What this script can and can't do natively:
      - Section layout, banner text, and List web parts bound to real
        filtered views: fully scripted below.
      - A single web part combining rows from multiple lists (e.g. one
        unified "Attention Required" table blending RAID + Actions +
        blocked sites + decisions): SharePoint's stock List web part shows
        one list at a time. This script places the equivalent exception
        views side by side instead of faking a merged table.
      - A visual step-by-step delivery timeline (Define > Design > ... >
        Go-live) for the People page: there's no built-in web part for
        this. A Text note is added on the People & Pages page instead;
        consider a small SPFx web part or a Power BI visual if you want a
        real graphical timeline later.
      - A Quick Chart (e.g. completion by department): left as a Text
        placeholder rather than scripted, because the Quick Chart web
        part's property schema is not reliably scriptable without testing
        against your tenant. Add it manually via the page editor - it's a
        two-minute job once the page exists.

    Usage:
        .\03-Provision-Pages.ps1 -SiteUrl "https://hutchisonports.sharepoint.com/sites/hpuk-pof-projects"
#>
param(
    [Parameter(Mandatory = $true)][string]$SiteUrl
)

. "$PSScriptRoot\Common.ps1"

Connect-ControlCentreSite -SiteUrl $SiteUrl

$migrationList  = Get-PnPList -Identity "SP_MigrationRegister"
$pageList       = Get-PnPList -Identity "SP_PageDelivery"
$actionsList    = Get-PnPList -Identity "SP_Actions"
$raidList       = Get-PnPList -Identity "SP_RAID"
$decisionsList  = Get-PnPList -Identity "SP_Decisions"
$updatesList    = Get-PnPList -Identity "SP_ProjectUpdates"

function New-OrGetPage {
    param([string]$Name, [string]$Title)
    $existing = Get-PnPPage -Identity $Name -ErrorAction SilentlyContinue
    if ($null -ne $existing) {
        Write-Host "  Page '$Name' already exists - reusing it (existing sections/web parts are left as is; re-run may duplicate parts if you've already customised it)." -ForegroundColor Yellow
        return $existing
    }
    Write-Host "  Creating page '$Name' ..." -ForegroundColor Cyan
    return Add-PnPPage -Name $Name -Title $Title -LayoutType Article
}

# ============================================================
# 1. Programme Control Centre - Implementation Specification 3.1
# ============================================================
Write-Host "`n=== Programme Control Centre ===" -ForegroundColor Magenta
$page = New-OrGetPage -Name "ProgrammeControlCentre" -Title "Programme Control Centre"

Add-PnPPageSection -Page $page -SectionTemplate OneColumn
Add-PnPPageTextPart -Page $page -Text "Validated baseline: 209 sites complete. LMS is complete and is not a current programme blocker. The current delivery gap is the People page and other pages outside the original migration scope, tracked on People & Pages." -Section 1 -Column 1

Add-PnPPageSection -Page $page -SectionTemplate OneColumn -Order 2
Add-PnPPageTextPart -Page $page -Text "Attention required" -Section 2 -Column 1

Add-PnPPageSection -Page $page -SectionTemplate TwoColumn -Order 3
Add-ControlCentreListWebPart -Page $page -List $migrationList -ViewName "Blocked or Amber Sites" -Section 3 -Column 1 -Title "Blocked / Amber Sites"
Add-ControlCentreListWebPart -Page $page -List $actionsList   -ViewName "Overdue Actions"         -Section 3 -Column 2 -Title "Overdue Actions"

Add-PnPPageSection -Page $page -SectionTemplate TwoColumn -Order 4
Add-ControlCentreListWebPart -Page $page -List $raidList      -ViewName "Red or Amber RAID" -Section 4 -Column 1 -Title "Red / Amber RAID"
Add-ControlCentreListWebPart -Page $page -List $decisionsList -ViewName "Pending Decisions" -Section 4 -Column 2 -Title "Decisions Required"

Add-PnPPageSection -Page $page -SectionTemplate TwoColumn -Order 5
Add-ControlCentreListWebPart -Page $page -List $migrationList -ViewName "Next 30 Days"   -Section 5 -Column 1 -Title "Next Migrations"
Add-ControlCentreListWebPart -Page $page -List $pageList      -ViewName "Page Backlog"   -Section 5 -Column 2 -Title "Page Delivery Backlog"

Set-PnPPage -Identity $page.Name -Publish

# ============================================================
# 2. Migration - Implementation Specification 3.3
# ============================================================
Write-Host "`n=== Migration ===" -ForegroundColor Magenta
$page = New-OrGetPage -Name "Migration" -Title "Migration"

Add-PnPPageSection -Page $page -SectionTemplate OneColumn
Add-PnPPageTextPart -Page $page -Text "Residual site migration only. LMS is complete and is not shown here as a current blocker. The People page and other out-of-scope pages are tracked separately on People & Pages. (Add a Quick Chart web part here for completion-by-department if wanted - see script header.)" -Section 1 -Column 1

Add-PnPPageSection -Page $page -SectionTemplate TwoColumn -Order 2
Add-ControlCentreListWebPart -Page $page -List $migrationList -ViewName "Next 30 Days"          -Section 2 -Column 1 -Title "Next 30 Days"
Add-ControlCentreListWebPart -Page $page -List $migrationList -ViewName "Blocked or Amber Sites" -Section 2 -Column 2 -Title "Blocked / Amber Sites"

Add-PnPPageSection -Page $page -SectionTemplate TwoColumn -Order 3
Add-ControlCentreListWebPart -Page $page -List $migrationList -ViewName "Remaining Sites" -Section 3 -Column 1 -Title "Remaining Sites"
Add-ControlCentreListWebPart -Page $page -List $migrationList -ViewName "Completed Sites" -Section 3 -Column 2 -Title "Completed Sites"

Set-PnPPage -Identity $page.Name -Publish

# ============================================================
# 3. People & Pages - Implementation Specification 3.2
# ============================================================
Write-Host "`n=== People & Pages ===" -ForegroundColor Magenta
$page = New-OrGetPage -Name "PeopleAndPages" -Title "People & Pages"

Add-PnPPageSection -Page $page -SectionTemplate OneColumn
Add-PnPPageTextPart -Page $page -Text "The People page (PAGE-001) and other pages outside the original migration scope, managed as controlled deliverables - not as migration or LMS blockers. Delivery lifecycle: Define > Design > Content > Build > UAT > Sign-off > Go-live (no native stepper web part - check PAGE-001's Delivery Status in the Page Backlog list below for its current stage, or add a small SPFx/Power BI visual here later)." -Section 1 -Column 1

Add-PnPPageSection -Page $page -SectionTemplate TwoColumn -Order 2
Add-ControlCentreListWebPart -Page $page -List $pageList -ViewName "Priority Queue"   -Section 2 -Column 1 -Title "Priority Queue"
Add-ControlCentreListWebPart -Page $page -List $pageList -ViewName "Ownership Gaps"   -Section 2 -Column 2 -Title "Ownership Gaps"

Add-PnPPageSection -Page $page -SectionTemplate OneColumn -Order 3
Add-ControlCentreListWebPart -Page $page -List $pageList -ViewName "Page Backlog" -Section 3 -Column 1 -Title "Page Backlog (Out of Scope / Scope Change)"

Set-PnPPage -Identity $page.Name -Publish

# ============================================================
# 4. Governance / Control Board - Implementation Specification 3.4
# ============================================================
Write-Host "`n=== Governance ===" -ForegroundColor Magenta
$page = New-OrGetPage -Name "Governance" -Title "Governance / Control Board"

Add-PnPPageSection -Page $page -SectionTemplate OneColumn
Add-PnPPageTextPart -Page $page -Text "RAID, actions, decisions and the latest Project Update snapshot - the Control Board meeting landing page." -Section 1 -Column 1

Add-PnPPageSection -Page $page -SectionTemplate TwoColumn -Order 2
Add-ControlCentreListWebPart -Page $page -List $raidList    -ViewName "Red or Amber RAID" -Section 2 -Column 1 -Title "Red / Amber RAID"
Add-ControlCentreListWebPart -Page $page -List $actionsList -ViewName "Overdue Actions"   -Section 2 -Column 2 -Title "Overdue Actions"

Add-PnPPageSection -Page $page -SectionTemplate TwoColumn -Order 3
Add-ControlCentreListWebPart -Page $page -List $decisionsList -ViewName "Pending Decisions" -Section 3 -Column 1 -Title "Pending Decisions"
Add-ControlCentreListWebPart -Page $page -List $pageList      -ViewName "Scope Changes"     -Section 3 -Column 2 -Title "Scope Changes"

Add-PnPPageSection -Page $page -SectionTemplate OneColumn -Order 4
Add-ControlCentreListWebPart -Page $page -List $updatesList -ViewName "Weekly History" -Section 4 -Column 1 -Title "Weekly Snapshot History"

Set-PnPPage -Identity $page.Name -Publish

Write-Host "`nAll four pages created/updated and published." -ForegroundColor Green
Write-Host "Open each one in the browser and check the List web parts rendered - see the script header for the two spots (Quick Chart, timeline) left as manual steps." -ForegroundColor Green
