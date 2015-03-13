#
# Module 'Dynamite.PowerShell.Toolkit'
# Generated by: GSoft, Team Dynamite.
# Generated on: 12/11/2013
# > GSoft & Dynamite : http://www.gsoft.com
# > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
# > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
#

<#
	.SYNOPSIS
		Commandlet to create a new variations site structure

	.DESCRIPTION
		Commandlet to create a new variations site structure based on XML configuration values.  Designed to be used within the New-DSPStructure commandlet.

    --------------------------------------------------------------------------------------
    Module 'Dynamite.PowerShell.Toolkit'
    by: GSoft, Team Dynamite.
    > GSoft & Dynamite : http://www.gsoft.com
    > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    --------------------------------------------------------------------------------------
    
	.PARAMETER  Config
		The XmlElement containing the variations configuration and labels.

	.PARAMETER  Site
		SharePoint site url or object.

	.EXAMPLE
		PS C:\> New-DSPSiteVariations -Config $variationsXml -Site $site

	.INPUTS
		System.Xml.XmlElement,Microsoft.SharePoint.PowerShell.SPSitePipeBind
    
	.LINK
		GSoft, Team Dynamite on Github
		> https://github.com/GSoft-SharePoint

		Dynamite PowerShell Toolkit on Github
		> https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit

		Documentation
		> https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
	
	.NOTES
  		Here is the Structure XML schema.
		
	<WebApplication Url="http://myWebApp">
	  <Site Name="Site Name" RelativePath="mySiteUrl" OwnerAlias="ORG\admin" Language="1033" Template="STS#1" ContentDatabase="CUSTOM_CONTENT_NAME">
	    <Variations
	      CreateHierarchies="true"
	      EnableAutoSpawn="false" 
	      AutoSpawnStopAfterDelete="false" 
	      UpdateWebParts="false" 
	      CopyResources="true" 
	      SendNotificationEmail="false"
	      SourceVarRootWebTemplate="CMSPUBLISHING#0">
	      <Labels>
	        <Label Title="en" Description="" FlagControlDisplayName="English-US" Language="en-US" Locale="1033" IsSource="true" HierarchyCreationMode="Publishing Sites and All Pages"/>
	        <Label Title="fr" Description="" FlagControlDisplayName="French-FR" Language="fr-FR" Locale="1036" IsSource="false" HierarchyCreationMode="Publishing Sites and All Pages"/>
	      </Labels>
	    </Variations>
	  </Site>
	</WebApplication>
#>
function global:New-DSPSiteVariations() {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[System.Xml.XmlElement]$Config,
		
		[Parameter(Mandatory=$true, Position=1)]
		[ValidateNotNullOrEmpty()]
		[Microsoft.SharePoint.PowerShell.SPSitePipeBind]$Site
	)
	
	#region Private Functions
	# Configures the site variation settings in the variations relationships list
	function ConfigureSiteVariationsSettings ([Microsoft.SharePoint.SPWeb]$RootWeb, [System.Xml.XmlElement]$Config){
		Write-Verbose "Setting site variation settings"
	    
		$guid = [Guid]$RootWeb.GetProperty("_VarRelationshipsListId");
	    $list = $RootWeb.Lists[$guid];
	    $rootFolder = $list.RootFolder;
	    $rootFolder.Properties["EnableAutoSpawnPropertyName"] = [System.Convert]::ToBoolean($Config.EnableAutoSpawn);
	    $list.RootFolder.Properties["AutoSpawnStopAfterDeletePropertyName"] = [System.Convert]::ToBoolean($Config.AutoSpawnStopAfterDelete);
	    $list.RootFolder.Properties["UpdateWebPartsPropertyName"] = [System.Convert]::ToBoolean($Config.UpdateWebParts);
	    $list.RootFolder.Properties["CopyResourcesPropertyName"] = [System.Convert]::ToBoolean($Config.CopyResources);
	    $list.RootFolder.Properties["SendNotificationEmailPropertyName"] = [System.Convert]::ToBoolean($Config.SendNotificationEmail);
	    $list.RootFolder.Properties["SourceVarRootWebTemplatePropertyName"] = [string]$Config.SourceVarRootWebTemplate;
	    $list.RootFolder.Update();
	    $item = $null;

	    if (($list.Items.Count -gt 0)){
	       $item = $list.Items[0];
	    }
	    else{
	        $item = $list.Items.Add();
			
			# Not sure where this GUID is from		
	        $item["GroupGuid"] =New-object System.Guid("F68A02C8-2DCC-4894-B67D-BBAED5A066F9");
	    }

		$item["Deleted"] = $false;
	    $item["ObjectID"] = $RootWeb.ServerRelativeUrl;
	    $item["ParentAreaID"] = [System.String]::Empty;
	    $item.Update();
	}
	
	# Creates a variations label based on it's configuration
	function CreateVariationsLabel ([Microsoft.SharePoint.SPWeb]$RootWeb, [System.Xml.XmlElement]$LabelConfig){
		Write-Verbose "Creating variation label for '$($LabelConfig.Title)'"
	    
		$guid = [Guid]$RootWeb.GetProperty("_VarLabelsListId");
	    $list = $RootWeb.Lists[$guid];
		
		$caml = New-Object -TypeName Microsoft.SharePoint.SPQuery;
		$caml.RowLimit = 1;
		$caml.Query = "<Where><Eq><FieldRef Name='Title'/><Value Type='Text'>" + [string]$LabelConfig.Title + "</Value></Eq></Where>";
		$items = $list.GetItems($caml);
					
		if ($items.Count -eq 0)
		{
		    $item = $list.Items.Add();
		    $item["Title"] = [string]$LabelConfig.Title;
		    $item["Description"] = [string]$LabelConfig.Description;
		    $item["Flag Control Display Name"] = [string]$LabelConfig.FlagControlDisplayName;
		    $item["Language"] = [string]$LabelConfig.Language;
		    $item["Locale"] = [int]$LabelConfig.Locale;
		    $item["Hierarchy Creation Mode"] = [string]$LabelConfig.HierarchyCreationMode;
		    $item["Is Source"] = [System.Convert]::ToBoolean($LabelConfig.IsSource);
		    $item["Hierarchy Is Created"] = $false;
		    $item.Update();			
				
		}
		else{
			Write-Warning "Skipping label for '$($LabelConfig.Title)' since it already exists"
		}
    }
	
	# Create 
	function CreateHierarchies ([Microsoft.SharePoint.SPSite]$Site){
	
		$id = [Guid]("e7496be8-22a8-45bf-843a-d1bd83aceb25");
			  			  	  			
	    $workItemId = $Site.AddWorkItem([System.Guid]::Empty, [System.DateTime]::Now.ToUniversalTime(), $id, $Site.RootWeb.ID, $Site.ID, 1, $false, [System.Guid]::Empty, [System.Guid]::Empty, $Site.RootWeb.CurrentUser.ID, $null, [System.String]::Empty, [System.Guid]::Empty, $false);
		
	    $webApplication = $Site.WebApplication;

		Wait-SPTimerJob -Name "VariationsCreateHierarchies" -WebApplication $webApplication
		Write-Verbose "Waiting for 'VariationsCreateHierarchies' timer job to finish..."
		Start-Sleep -Seconds 30
	}	


    function Add-LabelRelationship([Microsoft.SharePoint.SPWeb]$VariationRootWeb, [string]$Label)
    {
		$guid = [Guid]$VariationRootWeb.GetProperty("_VarLabelsListId");
		$list = $VariationRootWeb.Lists[$guid];

		# Get the variation label in the "Variation Labels" hidden list
		$caml = New-Object -TypeName Microsoft.SharePoint.SPQuery;
		$caml.RowLimit = 1;
		$caml.Query = "<Where><Eq><FieldRef Name='Title'/><Value Type='Text'>" + $Label + "</Value></Eq></Where>";
		$items = $list.GetItems($caml);
		$labelGuid = $null

		if ($items.Count -gt 0)
		{
			$isSource = $items[0]["Is Source"]
			
			if($isSource -eq $false)
			{
				$labelGuid = $items[0].UniqueId
			
				$guid = [Guid]$VariationRootWeb.GetProperty("_VarRelationshipsListId");
				$list = $VariationRootWeb.Lists[$guid];
				$groupGuid = $null

				# Get the group GUID of the variation source label in the "Relationship List" hidden list
				$caml = New-Object -TypeName Microsoft.SharePoint.SPQuery;
				$caml.RowLimit = 1;
				$caml.Query = "<Where><And><IsNotNull><FieldRef Name='ParentAreaID'/></IsNotNull><Neq><FieldRef Name='Label'/><Value Type='Guid'>" + $labelGuid + "</Value></Neq></And></Where>";
				$items = $list.GetItems($caml);
				if ($items.Count -gt 0)
				{
					$groupGuid = $items[0]["GroupGuid"];

					$item = $list.Items.Add();
					$item["GroupGuid"] = $groupGuid;			
					$item["Deleted"] = $false;
					
					# The label ID is the UniqueId of the list item for the label in the Variations Label Hidden List
					$item["Label"] = $labelGuid;
					
					# "2" means "To be created"
					$item["Status"] = 2;
					
					# "2" means "Variation branch" processing by the "VariationsCreateHierarchies" job
					$item["EntryType"] = 2;
					$item.Update();

					# Force the timer job
					CreateHierarchies -Site $VariationRootWeb.Site;					
				}
				else
				{
					Write-Verbose "No variation root label found!"
				}
			}
		}
		else
		{
			Write-Verbose "Label '$Label' doesn't exist in the Variation Labels hidden list"
		}	  		  
    }
	#endregion
	
	#region Main
	$rootWeb = $Site.Read().RootWeb;
	$createHierarchies = [System.Convert]::ToBoolean($Config.CreateHierarchies);
	Write-Verbose "Creating variations for site '$($rootWeb.Url)'"
	ConfigureSiteVariationsSettings -RootWeb $rootWeb -Config $Config;
	
	# Create each label
	$Config.Labels.Label | ForEach-Object {
		CreateVariationsLabel -RootWeb $rootWeb -LabelConfig $_
	}
	
	# If specified to create hierarchies, start timer job
	if($createHierarchies){
		Write-Verbose "Started variations hierarchies creation.`
		For more information, please consult the variations history log"
		CreateHierarchies -Site $Site.Read();
		
		# Manually Add other labels if doesn't exist
		$Config.Labels.Label | ForEach-Object {
			Add-LabelRelationship -VariationRootWeb $rootWeb -Label $_.Title
		}
	}
	#endregion
}

function Format-XML ([xml]$xml, $indent=2) 
{ 
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented" 
    $xmlWriter.Indentation = $Indent 
    $xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output $StringWriter.ToString() 
}

function Sync-DSPItem
{
	param
	(
        [Parameter(Mandatory=$true, Position=0)]
		$VariationListItem
	)
    
    $ItemSourceUniqueId = $VariationListItem.UniqueId
	$VariationList = $VariationListItem.ParentList
    $VariationWeb = $VariationList.ParentWeb
	$VariationWebId = $VariationList.ParentWeb.Id
	$ListId = $VariationList.Id
	$Site = $VariationList.ParentWeb.Site
		
	$TextPayLoadString = 	'<?xml version="1.0" encoding="utf-16"?>' +
					        '<PropagateListItemWorkItem xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
						        '<siteId>' + $VariationWeb.Site.Id + '</siteId>' +
						        '<webId>'  + $VariationWebId + '</webId>' +
						        '<listId>' + $ListId + '</listId>' +
						        '<itemIds><guid>' + $ItemSourceUniqueId + '</guid></itemIds>' +
					        '</PropagateListItemWorkItem>'

	$TextPayLoad = Format-XML $TextPayLoadString 
	
	$id = [Guid]("0B1B30B6-688A-4008-8ADE-A9736972B5E1");
									
	$workItemId = $Site.AddWorkItem([System.Guid]::Empty, [System.DateTime]::Now.ToUniversalTime(), $id, $VariationWebId , $ListId, 1, $false, [System.Guid]::Empty, [System.Guid]::Empty, $Site.RootWeb.CurrentUser.ID, $null, $TextPayLoad, [System.Guid]::Empty, $false);
}

function Start-ListItemPropagation
{
    param
	(
        [Parameter(Mandatory=$true, Position=0)]
		$WebApplication
	)

    Wait-SPTimerJob -Name "VariationsPropagateListItem" -WebApplication $WebApplication
	Write-Verbose "Waiting for 'VariationsPropagateListItem' timer job to finish..."
	Start-Sleep -Seconds 15
}

function Set-VariationHierarchy {
	[CmdletBinding()]
	param
	(	
		[Parameter(Mandatory=$true, Position=0)]
		[ValidateNotNullOrEmpty()]
		[string]$Site
	)
	
		$spSite = Get-SPSite $Site;
		$rootWeb = $spSite.RootWeb;
		$guid = [Guid]$rootWeb.GetProperty("_VarLabelsListId");
		$list = $rootWeb.Lists[$guid];
	
		$caml = New-Object -TypeName Microsoft.SharePoint.SPQuery;
		$caml.RowLimit = 1;
		$caml.Query = "<Where><Eq><FieldRef Name='Title'/><Value Type='Text'>en</Value></Eq></Where>";
		$items = $list.GetItems($caml);
					
		if ($items.Count -eq 1) {
			$item = $items[0];
			$isHierarchyCreated = $item["Hierarchy Is Created"];
			if ($isHierarchyCreated) {
				Write-Host "The 'en' label 'hierarchy is created' is already true.  Skipping fix..."
			} else {
				Write-Host "Fixing the 'en' label 'hierarchy is created' flag and resetting IIS..."
				$item["Hierarchy Is Created"] = $true;
				$item.Update();			

				iisreset
			}


				
		}
		else {
			Write-Warning "Couldn't find 'en' label and fix the 'hierarchy is created' flag"
		}
}

function Sync-DSPWeb {
	param
	(
        [Parameter(Mandatory=$true, HelpMessage = "The variation source web", Position=0, ValueFromPipeline=$true)]
		[Microsoft.SharePoint.SPWeb]$SourceWeb,

		[Parameter(Mandatory=$true, HelpMessage = "The label to Sync", Position=1)]
		[string]$LabelToSync
	)

	$sourceUrl = $SourceWeb.Url
	$labelToUpper = $LabelToSync.ToUpper()
    Write-Warning "Sync SPWeb '$sourceUrl' to the variation label '$labelToUpper'..."

	$variationSyncHelper = Resolve-DSPType "GSoft.Dynamite.Globalization.Variations.IVariationSyncHelper"

	$variationSyncHelper.SyncWeb($SourceWeb, $LabelToSync)
}

function Sync-DSPList {
	param
	(
        [Parameter(Mandatory=$true, HelpMessage = "The variation source list", Position=0, ValueFromPipeline=$true)]
		[Microsoft.SharePoint.SPList]$SourceList,

		[Parameter(Mandatory=$true, HelpMessage = "The label to Sync", Position=1)]
		[string]$LabelToSync
	)

	$listTitle = $SourceList.Title
	$labelToUpper = $LabelToSync.ToUpper()
    Write-Warning "Sync SPList '$listTitle' to the variation label '$labelToUpper'..."

	$variationSyncHelper = Resolve-DSPType "GSoft.Dynamite.Globalization.Variations.IVariationSyncHelper"

	$variationSyncHelper.SyncList($SourceList, $LabelToSync)
}

function Get-VariationLabels {

	Param
	(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[Microsoft.SharePoint.SPWeb]$Web
	)

    $Labels = @{}
    
    # To know if a site has variatiosn enabled, we need to check labels in the variation hidden list
    $PublishingWeb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($Web)

    if ($PublishingWeb)
    {
        $ListGuid = $Web.GetProperty("_VarLabelsListId")
        if ($ListGuid -ne $null)
        {
            
            $List = $Web.Lists[[Guid]$ListGuid]
		
            $CamlQuery = New-Object -TypeName Microsoft.SharePoint.SPQuery
            $CamlQuery.Query = "<OrderBy><FieldRef Name='Title' /></OrderBy>"
            $CamlQuery.ViewFields = "<FieldRef Name='Title' /><FieldRef Name='Locale' />"
            $LabelItems = $List.GetItems($CamlQuery) 

            $LabelItems | ForEach-Object {
                
                $Labels.Add($_.Title, $_["Locale"])
            }          
        }
    }

    return $Labels
}