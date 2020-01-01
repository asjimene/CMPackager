## CreateAppleDriverRecipes.ps1
##
## This script is meant to be run as part of the CMPackager Process, this script generates a recipe to package Apple BootCamp Software and Drivers
## for all Apple models found in CM. The process is as follows:
## 1. The script runs a query on the CM server to determine what Apple Models are present
## 2. The script downloads the Apple software catalog and parses it, finding all the bootcampesd packages and determining what models each one supports
## 3. The script culls unneeded driver package information, and orders the drivers by PostDate (Newest to oldest)
## 4. The script generates an xml recipe file using the data it has gathered and the "AppleDriverRecipeTemplate.txt file", the recipe is saved to the "Recipes" folder for processing by CMPackager
## 5. The next time CMPackager is run (if this is the first time running this script), the recipe will instruct the CMPackager tool to create the following:
##   a. 1 CM Application
##   b. The version on the Apple BootCamp Software Application will be the PostDate of the latest firmware packaged
##   c. There will be multiple deployment types, each deployment type cooresponds with a BootCampESD package
##   d. Each deployment type will require the Manufacturer to equal "Apple Inc." and a Model being "one of" those supported by that BootCampESD package
##
## Note: Because some of the bootcamp files are so old, I have included in the ExtraFiles\AppleBootCamp\Install.ps1 file, instructions on replacing the BootCamp Executable + other files with the versions from
##   the latest BootCamp version available. Doing so allows the BootPicker to actually work in newer versions of MacOS (with APFS formatting). I leave the task of getting the latest installer and executable up to
##   the end user so I don't distribute Apple binaries. I plan on scripting that process in the future.
##
## Also, this would not be possible without the script found here: https://github.com/msftrncs/PwshReadXmlPList


function ConvertFrom-Plist {
    <#
.SYNOPSIS
    Convert a XML Plist to a PowerShell object
.DESCRIPTION
    Converts an XML PList (property list) in to a usable object in PowerShell.

    Properties will be converted in to ordered hashtables, the values of each property may be integer, double, date/time, boolean, string, or hashtables, arrays of any these, or arrays of bytes.
.EXAMPLE
    $pList = [xml](get-content 'somefile.plist') | ConvertFrom-Plist
.PARAMETER plist
    The property list as an [XML] document object, to be processed.  This parameter is mandatory and is accepted from the pipeline.
.INPUTS
    system.xml.document
.OUTPUTS
    system.object
.NOTES
    Script / Function / Class assembled by Carl Morris, Morris Softronics, Hooper, NE, USA
    Initial release - Aug 27, 2018
.LINK
    https://github.com/msftrncs/PwshReadXmlPList
.FUNCTIONALITY
    data format conversion
#>
    Param(
        # parameter to pass input via pipeline
        [Parameter(Mandatory, Position = 0,
            ValueFromPipeline, ValueFromPipelineByPropertyName,
            HelpMessage = 'XML Plist object.')]
        [ValidateNotNullOrEmpty()]
        [xml]$plist
    )

    # define a class to provide a method for accelerated processing of the XML tree
    class plistreader {
        # define a static method for accelerated processing of the XML tree
        static [object] processTree ($node) {
            return $(
                <#  iterate through the collection of XML nodes provided, recursing through the children nodes to
                extract properties and their values, dictionaries, or arrays of all, but note that property values
                follow their key, not contained within them. #>
                if ($node.HasChildNodes) {
                    switch ($node.Name) {
                        dict {
                            # for dictionary, return the subtree as a ordered hashtable, with possible recursion of additional arrays or dictionaries
                            $collection = [ordered]@{ }
                            $currnode = $node.FirstChild # start at the first child node of the dictionary
                            while ($null -ne $currnode) {
                                if ($currnode.Name -eq 'key') {
                                    # a key in a dictionary, add it to a collection
                                    if ($null -ne $currnode.NextSibling) {
                                        # note: keys are forced to [string], insures a $null key is accepted
                                        $collection[[string][plistreader]::processTree($currnode.FirstChild)] = [plistreader]::processTree($currnode.NextSibling)
                                        $currnode = $currnode.NextSibling.NextSibling # skip the next sibling because it was the value of the property
                                    }
                                    else {
                                        throw "Dictionary property value missing!"
                                    }
                                }
                                else {
                                    throw "Non 'key' element found in dictionary: <$($currnode.Name)>!"
                                }
                            }
                            # return the collected hash table
                            $collection
                            continue
                        }
                        array {
                            # for arrays, recurse each node in the subtree, returning an array (forced)
                            , @($node.ChildNodes.foreach{ [plistreader]::processTree($_) })
                            continue
                        }
                        string {
                            # for string, return the value, with possible recursion and collection
                            [plistreader]::processTree($node.FirstChild)
                            continue
                        }
                        integer {
                            # must be an integer type value element, return its value
                            [plistreader]::processTree($node.FirstChild).foreach{
                                # try to determine what size of interger to return this value as
                                if ([int]::TryParse( $_, [ref]$null)) {
                                    # a 32bit integer seems to work
                                    $_ -as [int]
                                }
                                elseif ([int64]::TryParse( $_, [ref]$null)) {
                                    # a 64bit integer seems to be needed
                                    $_ -as [int64]
                                }
                                else {
                                    # try an unsigned 64bit interger, the largest available here.
                                    $_ -as [uint64]
                                }
                            }
                            continue
                        }
                        real {
                            # must be a floating type value element, return its value
                            [plistreader]::processTree($node.FirstChild) -as [double]
                            continue
                        }
                        date {
                            # must be a date-time type value element, return its value
                            [plistreader]::processTree($node.FirstChild) -as [datetime]
                            continue
                        }
                        data {
                            # must be a data block value element, return its value as [byte[]]
                            [convert]::FromBase64String([plistreader]::processTree($node.FirstChild))
                            continue
                        }
                        default {
                            # we didn't recognize the element type!
                            throw "Unhandled PLIST property type <$($node.Name)>!"
                        }
                    }
                }
                else {
                    # return simple element value (need to check for Boolean datatype, and process value accordingly)
                    switch ($node.Name) {
                        true { $true; continue } # return a Boolean TRUE value
                        false { $false; continue } # return a Boolean FALSE value
                        default { $node.Value } # return the element value
                    }
                }
            )
        }
    }

    # process the 'plist' item of the input XML object
    [plistreader]::processTree($plist.item('plist').FirstChild)
}


## Gather Apple Models currently in CM
Push-Location
Set-Location $Global:CMSite
$WMI = @"
select distinct SMS_G_System_COMPUTER_SYSTEM.Model from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Manufacturer = "Apple Inc." order by SMS_G_System_COMPUTER_SYSTEM.Model
"@

$QueryResults = (Invoke-CMWmiQuery -Query $WMI -Option Lazy).Model
Pop-Location


$BootCampInstallers = @()
$AppleSUCatalog = "https://swscan.apple.com/content/catalogs/others/index-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
Invoke-WebRequest -URI $AppleSUCatalog -OutFile "$PSScriptRoot\AppleSUCatalog.sucatalog"
$Plist = ConvertFrom-Plist -plist $([xml](Get-Content "$PSScriptRoot\AppleSUCatalog.sucatalog"))
foreach ($Values in ($Plist.Products.Values | Where-Object { $_.ServerMetadataURL -like "*BootCamp*" } | Where-Object {$_.Distributions.English -ne $null})){
    $DistPackage = $(Invoke-Webrequest $Values.Distributions.English).Content
    (([xml]$DistPackage).ChildNodes.Script[2]).ToString() > .\temp.txt
    Start-Sleep 1
    $models = Get-Content .\temp.txt | Select-String -pattern "var models"
    Remove-Item .\temp.txt -Force -ErrorAction SilentlyContinue
    $models = $models.ToString().TrimStart().TrimEnd().Replace('var models = ','').Replace(';','').Replace("`',`'",";").Replace("`'",'').Replace('[','').Replace(',]','')
    $SupportedModels = $models.Split(';')
    $ModelComparison = Compare-Object -ReferenceObject $QueryResults -DifferenceObject $SupportedModels -IncludeEqual
    $Comparison = ($ModelComparison | Where-Object -Property SideIndicator -eq "==").InputObject
    if ($Comparison){
        
        $BootCampIdentifier = ($Values.Distributions.English.Split('/')[-1]).Replace('.English.dist','')
        Add-Logcontent "$BootCampIdentifier contains these models found in CM: $($Comparison -join ", ")"
        $AppleBootCampInstaller = New-Object -TypeName System.Management.Automation.PSObject
        $AppleBootCampInstaller | Add-Member -MemberType NoteProperty -Name "OriginalDownloadLocation" -Value $Values.Packages.URL
        $AppleBootCampInstaller | Add-Member -MemberType NoteProperty -Name "BootCampIdentifier" -Value $BootCampIdentifier
        $AppleBootCampInstaller | Add-Member -MemberType NoteProperty -Name "PostDate" -Value $Values.PostDate
        $AppleBootCampInstaller | Add-Member -MemberType NoteProperty -Name "SupportedModels" -Value $SupportedModels

        $BootCampInstallers += $AppleBootCampInstaller
    }
}
$BootCampInstallers = $BootCampInstallers | sort-object -Property PostDate, SupportedModels -Descending -Unique
#$ReqBootCampInstallers = @()
#foreach ($RequestedModel in $QueryResults) {
#    $ReqBootCampInstallers += $BootCampInstaller | Where-Object -Property SupportedModels -Contains $RequestedModel | Select-Object -First 1
#}
#$ReqBootCampInstallers = $BootCampInstallers |Sort-Object -Property PostDate, SupportedModels -Descending -Unique
Add-LogContent "There are $($BootCampInstallers.Count) Boot Camp Installers that need to be packaged"
Add-Logcontent "Packaging: $($BootCampInstallers.BootCampIdentifier -join ", ")"

$BootCampDate = $BootCampInstallers[0].PostDate.ToString("yyyyMMdd")

$AppTemplate = (Get-Content "$PSScriptRoot\AppleDriverRecipeTemplate.txt")
[xml]$AppRecipe = $AppTemplate

## Generate the Recipe
foreach ($Installer in $BootCampInstallers) {
    Write-Output "Processing Drivers for $($Installer.BootCampIdentifier))"
    # Clone New Download Node with appropriate Windows Version
    $NewDownload = $AppRecipe.ApplicationDef.Downloads.FirstChild.Clone()
    $NewDownload.DeploymentType = $Installer.BootCampIdentifier
    $NewDownload.URL = ($NewDownload.URL).Replace('%DOWNLOADLINK%', $Installer.OriginalDownloadLocation)
    $NewDownload.DownloadFileName = ($NewDownload.DownloadFileName).Replace('%BCIDENTIFIER%', $Installer.BootCampIdentifier)
    $NewDownload.DownloadVersionCheck = ($NewDownload.DownloadVersionCheck).Replace('%LATESTBCDATE%',$BootCampDate)
    if ($BootCampInstallers.IndexOf($Installer) -ne 0) {
        $NewDownload.DownloadVersionCheck = "#No Version Check for older Versions"
    }
    $NewDownload.AppRepoFolder = ($NewDownload.AppRepoFolder).Replace('%BCIDENTIFIER%', $Installer.BootCampIdentifier)
    $NewDownload.ExtraCopyFunctions = ($NewDownload.ExtraCopyFunctions).Replace('%BCIDENTIFIER%', $Installer.BootCampIdentifier)
    $AppRecipe.ApplicationDef.Downloads.AppendChild($NewDownload) | Out-Null

    # Clone New DeploymentType Node with appropriate Windows Version
    $NewDeploymentType = $AppRecipe.ApplicationDef.DeploymentTypes.FirstChild.Clone()
    $NewDeploymentType.Name = $Installer.BootCampIdentifier
    $NewDeploymentType.DeploymentTypeName = $Installer.BootCampIdentifier
    $NewDeploymentType.Comments = ($NewDeploymentType.Comments).Replace('%BCIDENTIFIER%', $Installer.BootCampIdentifier).Replace('%SUPPORTEDMODELS%', $($Installer.SupportedModels -join ", "))
    
    foreach ($Value in $Installer.SupportedModels) {
        $NewValue = $NewDeploymentType.RequirementsRules.LastChild.RequirementsRuleValue.FirstChild.clone()
        $NewValue.'#text' = $Value
        $NewDeploymentType.RequirementsRules.LastChild.RequirementsRuleValue.AppendChild($NewValue) | Out-Null
    }
    $NewDeploymentType.RequirementsRules.LastChild.RequirementsRuleValue.RemoveChild($NewDeploymentType.RequirementsRules.LastChild.RequirementsRuleValue.FirstChild)
    $AppRecipe.ApplicationDef.DeploymentTypes.AppendChild($NewDeploymentType) | Out-Null
}

# Remove the Template Nodes and Save the Final Result
Add-LogContent "Removing Unneeded Content Nodes"
$AppRecipe.ApplicationDef.Downloads.RemoveChild($AppRecipe.ApplicationDef.Downloads.FirstChild) | Out-Null
Start-Sleep 1
$AppRecipe.ApplicationDef.DeploymentTypes.RemoveChild($AppRecipe.ApplicationDef.DeploymentTypes.FirstChild) | Out-Null
Start-Sleep 1
Add-LogContent "Saving AppleBootCampDrivers.xml"
$AppRecipe.Save("$ScriptRoot\Recipes\AppleBootCampDrivers.xml")
