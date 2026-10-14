<#
.SYNOPSIS
    Applies the governance baseline to a newly created SharePoint Online site.

.DESCRIPTION
    Called by flow 03 (Provision governed SharePoint sites) as an Azure
    Automation runbook, after SPSiteManager has created the site. It applies
    the controls agreed in PID v3.1:

      * permissions only through security groups (federated AD or cloud-only),
        never individual grants
      * a named secondary site collection admin, so the site is never ownerless
      * external sharing off unless InfoSec approved it, and then limited to
        guests who already exist in the directory
      * no custom script on the site
      * the requested sensitivity label

    Authentication uses the Azure Enterprise App registered for PnP PowerShell
    (DEP005) with a certificate held in the Automation account.

.NOTES
    Automation account requirements:
      Modules:     PnP.PowerShell (2.x, PowerShell 7.2 runtime)
      Variables:   PnPClientId, TenantName (e.g. contoso), TenantId
      Certificate: PnPAppCertificate (private key of the Enterprise App's certificate)
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

$clientId = Get-AutomationVariable -Name 'PnPClientId'
$tenant = Get-AutomationVariable -Name 'TenantName'
$tenantId = Get-AutomationVariable -Name 'TenantId'
$cert = Get-AutomationCertificate -Name 'PnPAppCertificate'

$adminUrl = "https://$tenant-admin.sharepoint.com"

# --- Tenant-level site settings -------------------------------------------
$admin = Connect-PnPOnline -Url $adminUrl -ClientId $clientId -Tenant $tenantId `
    -Thumbprint $cert.Thumbprint -ReturnConnection

Set-PnPTenantSite -Url $SiteUrl -Connection $admin `
    -SharingCapability $ExternalSharing `
    -DenyAddAndCustomizePages:$true

# Secondary owner as site collection admin, so the site survives the primary
# owner leaving (flow 08 flags it as orphaned and prompts a replacement).
Set-PnPTenantSite -Url $SiteUrl -Connection $admin -Owners @($SecondaryOwner)

# --- Site-level permissions -------------------------------------------------
$site = Connect-PnPOnline -Url $SiteUrl -ClientId $clientId -Tenant $tenantId `
    -Thumbprint $cert.Thumbprint -ReturnConnection

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
    Write-Output "Added group $($a.Id) to '$($a.Group.Title)'"
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
            Write-Output "Removed individual grant $($_.LoginName) from '$($a.Group.Title)'"
        }
}

# --- Sensitivity label --------------------------------------------------------
# Label names must match the published Purview labels.
$label = Get-PnPAvailableSensitivityLabel -Connection $site |
    Where-Object { $_.Name -eq $SensitivityLabel } | Select-Object -First 1
if ($label) {
    Set-PnPSiteSensitivityLabel -Identity $label.Id -Connection $site
    Write-Output "Applied sensitivity label '$SensitivityLabel'"
} else {
    # Fail loudly: a Highly Confidential site without its label is a governance gap.
    throw "Sensitivity label '$SensitivityLabel' is not published to this tenant."
}

Write-Output "Governance baseline applied to $SiteUrl (sharing: $ExternalSharing)"
