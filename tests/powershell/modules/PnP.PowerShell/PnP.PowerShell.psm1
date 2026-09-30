# Stand-in for PnP.PowerShell so the provisioning scripts can be executed
# without a SharePoint tenant. Records every call into $global:PnPCalls and
# keeps just enough state (lists, fields, views, pages) for the scripts'
# "create it if it's missing" branches to behave realistically.

$global:PnPCalls  = [System.Collections.ArrayList]::new()
$global:PnPLists  = @{}   # title -> @{ Fields = @{}; Views = @{} }
$global:PnPPages  = @{}   # name  -> @{ Parts = @() }

function Record {
    param([string] $Cmdlet, [hashtable] $Data = @{})
    [void]$global:PnPCalls.Add([pscustomobject]@{ Cmdlet = $Cmdlet; Data = $Data })
}

function Reset-PnPMock {
    $global:PnPCalls.Clear()
    $global:PnPLists = @{}
    $global:PnPPages = @{}
}

function Connect-PnPOnline {
    param(
        [string] $Url, [string] $ClientId, [string] $Tenant,
        [switch] $Interactive,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    Record 'Connect-PnPOnline' @{ Url = $Url; ClientId = $ClientId; Interactive = [bool]$Interactive }
}

function Disconnect-PnPOnline {
    param([Parameter(ValueFromRemainingArguments = $true)] $Rest)
    Record 'Disconnect-PnPOnline'
}

function Get-PnPList {
    param(
        [string] $Identity,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    if (-not $global:PnPLists.ContainsKey($Identity)) { return $null }
    [pscustomobject]@{
        Title          = $Identity
        Id             = [guid]::NewGuid()
        DefaultViewUrl = "Lists/$Identity/AllItems.aspx"
    }
}

function New-PnPList {
    param(
        [string] $Title, [string] $Template,
        [switch] $OnQuickLaunch,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    $global:PnPLists[$Title] = @{ Fields = @{}; Views = @{ 'All Items' = $true } }
    Record 'New-PnPList' @{ Title = $Title; Template = $Template }
    [pscustomobject]@{ Title = $Title; Id = [guid]::NewGuid() }
}

function Set-PnPList {
    param(
        [string] $Identity, [string] $Description,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    Record 'Set-PnPList' @{ Identity = $Identity; Description = $Description }
}

function Get-PnPField {
    param(
        [string] $List, [string] $Identity,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    if (-not $global:PnPLists.ContainsKey($List)) { return $null }
    # Title always exists on a new list; everything else must be created first.
    if ($Identity -eq 'Title') { return [pscustomobject]@{ InternalName = 'Title' } }
    if (-not $global:PnPLists[$List].Fields.ContainsKey($Identity)) { return $null }
    [pscustomobject]@{ InternalName = $Identity }
}

function Add-PnPField {
    param(
        [string] $List, [string] $DisplayName, [string] $InternalName,
        [string] $Type, [string[]] $Choices, [switch] $AddToDefaultView,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    if (-not $global:PnPLists.ContainsKey($List)) { throw "Add-PnPField: list '$List' does not exist" }
    $global:PnPLists[$List].Fields[$InternalName] = @{ Type = $Type; Choices = $Choices }
    Record 'Add-PnPField' @{ List = $List; InternalName = $InternalName; Type = $Type; Choices = $Choices }
    [pscustomobject]@{ InternalName = $InternalName }
}

function Add-PnPFieldFromXml {
    param(
        [string] $List, [string] $FieldXml,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    $xml = [xml]$FieldXml
    $name = $xml.Field.Name
    if (-not $global:PnPLists.ContainsKey($List)) { throw "Add-PnPFieldFromXml: list '$List' does not exist" }
    $global:PnPLists[$List].Fields[$name] = @{ Type = $xml.Field.Type; Formula = $xml.Field.Formula }
    Record 'Add-PnPFieldFromXml' @{ List = $List; Name = $name; Type = $xml.Field.Type; Formula = $xml.Field.Formula }
}

function Set-PnPField {
    param(
        [string] $List, [string] $Identity, [hashtable] $Values,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    Record 'Set-PnPField' @{ List = $List; Identity = $Identity; Values = $Values }
}

function Get-PnPView {
    param(
        [string] $List, [string] $Identity,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    if (-not $global:PnPLists.ContainsKey($List)) { return $null }
    if (-not $global:PnPLists[$List].Views.ContainsKey($Identity)) { return $null }
    [pscustomobject]@{ Title = $Identity }
}

function Set-PnPView {
    param(
        [string] $List, [string] $Identity, [hashtable] $Values,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    Record 'Set-PnPView' @{ List = $List; Identity = $Identity; Values = $Values }
}

function Add-PnPListItem {
    param(
        [string] $List, [hashtable] $Values,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    if (-not $global:PnPLists.ContainsKey($List)) { throw "Add-PnPListItem: list '$List' does not exist" }
    Record 'Add-PnPListItem' @{ List = $List; Values = $Values }
}

function Get-PnPContext {
    param([Parameter(ValueFromRemainingArguments = $true)] $Rest)
    [pscustomobject]@{ Web = [pscustomobject]@{ } }
}

function Get-PnPProperty {
    param(
        $ClientObject, [string] $Property,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    [pscustomobject]@{ LoginName = 'i:0#.f|membership|mock.user@contoso.com' }
}

function Get-PnPPage {
    param(
        [string] $Identity,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    if (-not $global:PnPPages.ContainsKey($Identity)) { return $null }
    [pscustomobject]@{ Name = $Identity }
}

function Add-PnPPage {
    param(
        [string] $Name, [string] $Title, [string] $LayoutType,
        [switch] $Force,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    $global:PnPPages[$Name] = @{ Parts = @() }
    Record 'Add-PnPPage' @{ Name = $Name; Title = $Title; LayoutType = $LayoutType }
    [pscustomobject]@{ Name = $Name }
}

function Add-PnPPageSection {
    param(
        [string] $Page, [string] $SectionTemplate,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    Record 'Add-PnPPageSection' @{ Page = $Page; SectionTemplate = $SectionTemplate }
}

function Add-PnPPageTextPart {
    param(
        [string] $Page, [string] $Text,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    Record 'Add-PnPPageTextPart' @{ Page = $Page; Text = $Text }
}

function Add-PnPPageWebPart {
    param(
        [string] $Page, [string] $DefaultWebPartType, [hashtable] $WebPartProperties,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    if (-not $global:PnPPages.ContainsKey($Page)) { throw "Add-PnPPageWebPart: page '$Page' does not exist" }
    Record 'Add-PnPPageWebPart' @{ Page = $Page; Type = $DefaultWebPartType; Properties = $WebPartProperties }
}

function Set-PnPPage {
    param(
        [string] $Identity, [switch] $Publish,
        [Parameter(ValueFromRemainingArguments = $true)] $Rest
    )
    Record 'Set-PnPPage' @{ Identity = $Identity; Publish = [bool]$Publish }
}

Export-ModuleMember -Function *-PnP*, Reset-PnPMock
