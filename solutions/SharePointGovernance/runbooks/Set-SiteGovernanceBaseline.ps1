<#
.SYNOPSIS
    Applies the governance baseline to a newly created SharePoint Online site.

.DESCRIPTION
    Called by flow 03 (Provision governed SharePoint sites) as an Azure
    Automation runbook, after SPSiteManager has created the site. It applies
    the controls agreed in the PID (v4.2):

      * permissions only through security groups (federated AD or cloud-only),
        never individual grants
      * a named secondary site collection admin, so the site is never ownerless
      * external sharing off unless InfoSec approved it, and then limited to
        guests who already exist in the directory
      * no custom script on the site
      * the requested sensitivity label

    Authentication uses the Automation account's system-assigned managed
    identity: the only sanctioned non-named identity (D-03, PID v4.2 2.3.1).
    No app registration, certificate or secret is involved.

    It ends with a ###RESULT### line holding a JSON result object. Success is
    taken from that object and the Automation jobs log, never from the flow
    alone (G-10).

.NOTES
    Automation account requirements:
      Identity:    system-assigned managed identity switched on
      Modules:     PnP.PowerShell (2.x, PowerShell 7.2 runtime)
      Variables:   TenantName (e.g. contoso)
      Rights:      - Sites.Selected (FullControl) on each new site URL, applied by
                     IT Operations when flow 03 asks, and recorded in the grant
                     register (G-04)
                   - SharePoint Administrator role, for the tenant-level step
                     (sharing, secondary admin), as already held for the RCD
                     runbook (G-03, DEP007). If InfoSec won't grant it, move the
                     tenant-level step to a named administrator and remove it here.
#>
param(
    [Parameter(Mandatory)] [string] $SiteUrl,
    [Parameter(Mandatory)] [string] $SecondaryOwner,
    [Parameter(Mandatory)] [string] $OwnersGroupId,
    [Parameter(Mandatory)] [string] $MembersGroupId,
    [string] $VisitorsGroupId,
    [ValidateSet('Disabled', 'ExistingExternalUserSharingOnly')]
    [string] $ExternalSharing = 'Disabled',
    [ValidateSet('General', 'Confidential', 'Highly Confidential')]
    [string] $SensitivityLabel = 'General'
)

$ErrorActionPreference = 'Stop'

$tenant = Get-AutomationVariable -Name 'TenantName'
$adminUrl = "https://$tenant-admin.sharepoint.com"
$result = [ordered]@{ Status = 'Failed'; SiteUrl = $SiteUrl; Steps = @(); Errors = @() }

function Write-Result {
    Write-Output ('###RESULT###' + ($result | ConvertTo-Json -Compress -Depth 4))
}

trap {
    # Partial is not success (PID v4.2, 7.4): name what failed and stop.
    $result.Errors += $_.Exception.Message
    if ($_.Exception.Message -match '401|403|Forbidden|Unauthorized') {
        $result.Errors += 'Usually a missing Sites.Selected grant for this site URL (G-04).'
    }
    Write-Result
    throw
}

# --- Tenant-level site settings -------------------------------------------
$admin = Connect-PnPOnline -Url $adminUrl -ManagedIdentity -ReturnConnection

Set-PnPTenantSite -Url $SiteUrl -Connection $admin `
    -SharingCapability $ExternalSharing `
    -DenyAddAndCustomizePages:$true

# Secondary owner as site collection admin, so the site survives the primary
# owner leaving (flow 06 flags it as orphaned and prompts a replacement).
Set-PnPTenantSite -Url $SiteUrl -Connection $admin -Owners @($SecondaryOwner)
$result.Steps += "Sharing $ExternalSharing; custom script off; secondary admin $SecondaryOwner"

# --- Site-level permissions -------------------------------------------------
$site = Connect-PnPOnline -Url $SiteUrl -ManagedIdentity -ReturnConnection

# Federated AD and cloud security groups both resolve with this claim format.
function Get-GroupClaim([string] $objectId) { "c:0t.c|tenant|$objectId" }

$assignments = @(
    @{ Group = (Get-PnPGroup -AssociatedOwnerGroup -Connection $site);   Id = $OwnersGroupId },
    @{ Group = (Get-PnPGroup -AssociatedMemberGroup -Connection $site);  Id = $MembersGroupId }
)
if ($VisitorsGroupId) {
    $assignments += @{ Group = (Get-PnPGroup -AssociatedVisitorGroup -Connection $site); Id = $VisitorsGroupId }
}

foreach ($a in $assignments) {
    Add-PnPGroupMember -Group $a.Group -LoginName (Get-GroupClaim $a.Id) -Connection $site
    $result.Steps += "Added group $($a.Id) to '$($a.Group.Title)'"
}

# The site was created with the primary owner as an individual member of the
# Owners group. Ownership is now carried by the Owners security group and the
# site collection admin entries, so remove individual users from the SharePoint
# groups to keep access group-based only.
foreach ($a in $assignments) {
    Get-PnPGroupMember -Group $a.Group -Connection $site |
        Where-Object { $_.PrincipalType -eq 'User' -and $_.LoginName -like 'i:0#.f|membership|*' } |
        ForEach-Object {
            Remove-PnPGroupMember -Group $a.Group -LoginName $_.LoginName -Connection $site
            $result.Steps += "Removed individual grant $($_.LoginName) from '$($a.Group.Title)'"
        }
}

# --- Sensitivity label --------------------------------------------------------
# Label names must match the published Purview labels.
$label = Get-PnPAvailableSensitivityLabel -Connection $site |
    Where-Object { $_.Name -eq $SensitivityLabel } | Select-Object -First 1
if ($label) {
    Set-PnPSiteSensitivityLabel -Identity $label.Id -Connection $site
    $result.Steps += "Applied sensitivity label '$SensitivityLabel'"
} else {
    # Fail loudly: a Highly Confidential site without its label is a governance gap.
    throw "Sensitivity label '$SensitivityLabel' is not published to this tenant."
}

$result.Status = 'Success'
Write-Result
