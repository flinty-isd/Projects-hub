<#
.SYNOPSIS
    Creates the SharePoint lists backing the PM dashboard and the IT Governance site.

.DESCRIPTION
    Creates seven lists with the exact INTERNAL column names both dashboards read.
    Internal names matter: SharePoint derives them from the display name at creation
    time and encodes spaces (so a column created as "Assigned To" gets the internal
    name "Assigned_x0020_To", which the dashboards would not find). This script
    always creates fields with an explicit space-free internal name and then sets a
    friendly display name separately.

    The script is idempotent -- existing lists and fields are left alone, so it is
    safe to re-run after a partial failure or to add a newly introduced column.

.PARAMETER SiteUrl
    Full URL of the target site, e.g. https://contoso.sharepoint.com/sites/ITGovernance

.PARAMETER ClientId
    Entra ID (Azure AD) application client ID used for the interactive sign-in.
    Required by PnP.PowerShell 2.x+ -- see README.md in this folder.

.PARAMETER Include
    Which list set to create: Pm, Governance, or All (default).

.EXAMPLE
    .\Provision-SharePointLists.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/PMO" `
        -ClientId "00000000-0000-0000-0000-000000000000" -Include Pm

.NOTES
    Requires the PnP.PowerShell module and permission to create lists on the site.
    This script has not been run against a live tenant -- review it before use.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $SiteUrl,

    [Parameter(Mandatory = $true)]
    [string] $ClientId,

    [ValidateSet('Pm', 'Governance', 'All')]
    [string] $Include = 'All'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    throw "PnP.PowerShell is not installed. Run: Install-Module PnP.PowerShell -Scope CurrentUser"
}

Import-Module PnP.PowerShell

# Date-only vs. date-and-time display for DateTime fields.
$DateOnly = 0

function Ensure-List {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string] $Title,
        [Parameter(Mandatory = $true)][string] $TitleFieldDisplayName,
        [string] $Description = ''
    )

    $list = Get-PnPList -Identity $Title -ErrorAction SilentlyContinue
    if ($list) {
        Write-Host "  List '$Title' already exists - leaving it alone." -ForegroundColor DarkGray
        return $list
    }

    if (-not $PSCmdlet.ShouldProcess($Title, 'Create list')) {
        return $null
    }

    Write-Host "  Creating list '$Title'..." -ForegroundColor Green
    $list = New-PnPList -Title $Title -Template GenericList -OnQuickLaunch
    if ($Description) {
        Set-PnPList -Identity $Title -Description $Description | Out-Null
    }

    # Re-label the built-in Title column so the list reads sensibly to humans.
    # The internal name stays "Title", which is what the dashboards read.
    Set-PnPField -List $Title -Identity 'Title' -Values @{ Title = $TitleFieldDisplayName } | Out-Null

    return $list
}

function Ensure-Field {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string] $ListTitle,
        [Parameter(Mandatory = $true)][string] $InternalName,
        [Parameter(Mandatory = $true)][string] $DisplayName,
        [Parameter(Mandatory = $true)][string] $Type,
        [string[]] $Choices,
        [switch] $DateOnlyFormat,
        [switch] $Required
    )

    $existing = Get-PnPField -List $ListTitle -Identity $InternalName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "    Field '$InternalName' already exists - skipping." -ForegroundColor DarkGray
        return
    }

    if (-not $PSCmdlet.ShouldProcess("$ListTitle.$InternalName", 'Add field')) {
        return
    }

    Write-Host "    Adding field '$InternalName' ($Type)" -ForegroundColor Cyan

    # Create with the internal name as the display name so SharePoint derives a
    # clean internal name, then rename the display afterwards.
    $params = @{
        List         = $ListTitle
        DisplayName  = $InternalName
        InternalName = $InternalName
        Type         = $Type
        AddToDefaultView = $true
    }
    if ($Choices) { $params['Choices'] = $Choices }
    if ($Required) { $params['Required'] = $true }

    Add-PnPField @params | Out-Null

    $values = @{ Title = $DisplayName }
    if ($DateOnlyFormat) { $values['DisplayFormat'] = $DateOnly }
    Set-PnPField -List $ListTitle -Identity $InternalName -Values $values | Out-Null
}

Write-Host "Connecting to $SiteUrl ..." -ForegroundColor Yellow
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId

$createPm = $Include -in @('Pm', 'All')
$createGov = $Include -in @('Governance', 'All')

# ---------------------------------------------------------------------------
# PM dashboard lists  (/ and /aspx)
# ---------------------------------------------------------------------------

if ($createPm) {
    Write-Host "`n=== PM dashboard lists ===" -ForegroundColor Yellow

    Ensure-List -Title 'Tasks' -TitleFieldDisplayName 'Task' `
        -Description 'Project tasks shown on the PM dashboard.' | Out-Null
    Ensure-Field -ListTitle 'Tasks' -InternalName 'Status' -DisplayName 'Status' -Type Choice `
        -Choices 'Not Started', 'In Progress', 'Done'
    Ensure-Field -ListTitle 'Tasks' -InternalName 'AssignedTo' -DisplayName 'Assigned To' -Type User
    Ensure-Field -ListTitle 'Tasks' -InternalName 'StartDate' -DisplayName 'Start Date' -Type DateTime -DateOnlyFormat
    Ensure-Field -ListTitle 'Tasks' -InternalName 'DueDate' -DisplayName 'Due Date' -Type DateTime -DateOnlyFormat
    Ensure-Field -ListTitle 'Tasks' -InternalName 'PercentComplete' -DisplayName '% Complete' -Type Number
    if ($PSCmdlet.ShouldProcess('Tasks.PercentComplete', 'Show as percentage')) {
        Set-PnPField -List 'Tasks' -Identity 'PercentComplete' -Values @{ ShowAsPercentage = $true } | Out-Null
    }
    Ensure-Field -ListTitle 'Tasks' -InternalName 'Priority' -DisplayName 'Priority' -Type Choice `
        -Choices 'High', 'Medium', 'Low'

    Ensure-List -Title 'Risks' -TitleFieldDisplayName 'Risk' `
        -Description 'Project risks and issues shown on the PM dashboard.' | Out-Null
    Ensure-Field -ListTitle 'Risks' -InternalName 'Severity' -DisplayName 'Severity' -Type Choice `
        -Choices 'High', 'Medium', 'Low'
    Ensure-Field -ListTitle 'Risks' -InternalName 'Owner' -DisplayName 'Owner' -Type User
    Ensure-Field -ListTitle 'Risks' -InternalName 'Status' -DisplayName 'Status' -Type Choice `
        -Choices 'Open', 'Mitigated', 'Closed'
    Ensure-Field -ListTitle 'Risks' -InternalName 'Description' -DisplayName 'Description' -Type Note
}

# ---------------------------------------------------------------------------
# IT Governance lists  (/governance-aspx)
# ---------------------------------------------------------------------------

if ($createGov) {
    Write-Host "`n=== IT Governance lists ===" -ForegroundColor Yellow

    Ensure-List -Title 'Policies' -TitleFieldDisplayName 'Policy' `
        -Description 'Policy and standards register.' | Out-Null
    Ensure-Field -ListTitle 'Policies' -InternalName 'Category' -DisplayName 'Category' -Type Choice `
        -Choices 'Security', 'Data', 'Operations', 'Vendor', 'Architecture'
    Ensure-Field -ListTitle 'Policies' -InternalName 'Owner' -DisplayName 'Owner' -Type User
    Ensure-Field -ListTitle 'Policies' -InternalName 'Status' -DisplayName 'Status' -Type Choice `
        -Choices 'Draft', 'Under Review', 'Approved', 'Expired'
    Ensure-Field -ListTitle 'Policies' -InternalName 'Version' -DisplayName 'Version' -Type Text
    Ensure-Field -ListTitle 'Policies' -InternalName 'LastReviewed' -DisplayName 'Last Reviewed' -Type DateTime -DateOnlyFormat
    Ensure-Field -ListTitle 'Policies' -InternalName 'NextReview' -DisplayName 'Next Review' -Type DateTime -DateOnlyFormat

    Ensure-List -Title 'Controls' -TitleFieldDisplayName 'Control Description' `
        -Description 'Control framework mapping and assessment status.' | Out-Null
    Ensure-Field -ListTitle 'Controls' -InternalName 'ControlId' -DisplayName 'Control ID' -Type Text
    Ensure-Field -ListTitle 'Controls' -InternalName 'Framework' -DisplayName 'Framework' -Type Choice `
        -Choices 'ISO 27001', 'NIST CSF', 'SOC 2', 'COBIT'
    Ensure-Field -ListTitle 'Controls' -InternalName 'Owner' -DisplayName 'Owner' -Type User
    Ensure-Field -ListTitle 'Controls' -InternalName 'Status' -DisplayName 'Status' -Type Choice `
        -Choices 'Compliant', 'Partial', 'Non-Compliant', 'Not Assessed'
    Ensure-Field -ListTitle 'Controls' -InternalName 'LastAssessed' -DisplayName 'Last Assessed' -Type DateTime -DateOnlyFormat

    Ensure-List -Title 'AuditFindings' -TitleFieldDisplayName 'Finding' `
        -Description 'Internal and external audit findings.' | Out-Null
    Ensure-Field -ListTitle 'AuditFindings' -InternalName 'Severity' -DisplayName 'Severity' -Type Choice `
        -Choices 'Critical', 'High', 'Medium', 'Low'
    Ensure-Field -ListTitle 'AuditFindings' -InternalName 'Source' -DisplayName 'Source' -Type Choice `
        -Choices 'Internal Audit', 'External Audit', 'Self-Assessment'
    Ensure-Field -ListTitle 'AuditFindings' -InternalName 'Owner' -DisplayName 'Owner' -Type User
    Ensure-Field -ListTitle 'AuditFindings' -InternalName 'Status' -DisplayName 'Status' -Type Choice `
        -Choices 'Open', 'In Remediation', 'Closed'
    Ensure-Field -ListTitle 'AuditFindings' -InternalName 'RaisedDate' -DisplayName 'Raised Date' -Type DateTime -DateOnlyFormat
    Ensure-Field -ListTitle 'AuditFindings' -InternalName 'DueDate' -DisplayName 'Due Date' -Type DateTime -DateOnlyFormat

    Ensure-List -Title 'RiskRegister' -TitleFieldDisplayName 'Risk' `
        -Description 'IT risk register scored on a 5x5 likelihood x impact grid.' | Out-Null
    Ensure-Field -ListTitle 'RiskRegister' -InternalName 'Category' -DisplayName 'Category' -Type Choice `
        -Choices 'Security', 'Technology', 'Operational', 'Compliance', 'Vendor', 'Financial'
    Ensure-Field -ListTitle 'RiskRegister' -InternalName 'Owner' -DisplayName 'Owner' -Type User
    Ensure-Field -ListTitle 'RiskRegister' -InternalName 'Treatment' -DisplayName 'Treatment' -Type Choice `
        -Choices 'Mitigate', 'Accept', 'Transfer', 'Avoid'
    Ensure-Field -ListTitle 'RiskRegister' -InternalName 'Status' -DisplayName 'Status' -Type Choice `
        -Choices 'Open', 'Monitored', 'Closed'
    Ensure-Field -ListTitle 'RiskRegister' -InternalName 'Likelihood' -DisplayName 'Likelihood (1-5)' -Type Number
    Ensure-Field -ListTitle 'RiskRegister' -InternalName 'Impact' -DisplayName 'Impact (1-5)' -Type Number

    Ensure-List -Title 'PolicyExceptions' -TitleFieldDisplayName 'Exception' `
        -Description 'Approved exceptions and waivers against policy.' | Out-Null
    Ensure-Field -ListTitle 'PolicyExceptions' -InternalName 'PolicyRef' -DisplayName 'Against Policy' -Type Text
    Ensure-Field -ListTitle 'PolicyExceptions' -InternalName 'RequestedBy' -DisplayName 'Requested By' -Type User
    Ensure-Field -ListTitle 'PolicyExceptions' -InternalName 'Approver' -DisplayName 'Approver' -Type User
    Ensure-Field -ListTitle 'PolicyExceptions' -InternalName 'Status' -DisplayName 'Status' -Type Choice `
        -Choices 'Pending', 'Active', 'Expired'
    Ensure-Field -ListTitle 'PolicyExceptions' -InternalName 'ExpiryDate' -DisplayName 'Expires' -Type DateTime -DateOnlyFormat
}

Write-Host "`nDone. Set the list names in Web.config / secrets.toml to match." -ForegroundColor Yellow
Write-Host "Numeric ranges: Likelihood and Impact are 1-5; PercentComplete is 0-1 (0.5 = 50%)." -ForegroundColor DarkGray

Disconnect-PnPOnline
