## GetLatestBootCamp.ps1
## Scans against the Apple software catalog to find the latest bootcamp ESD

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

$BootCampInstallers = @()
$AppleSUCatalog = "https://swscan.apple.com/content/catalogs/others/index-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog"
Invoke-WebRequest -URI $AppleSUCatalog -OutFile "$PSScriptRoot\AppleSUCatalog.sucatalog"
$Plist = ConvertFrom-Plist -plist $([xml](Get-Content "$PSScriptRoot\AppleSUCatalog.sucatalog"))

foreach ($Values in ($Plist.Products.Values | where { $_.ServerMetadataURL -like "*BootCamp*" } | where {$_.Distributions.English -ne $null})){
    $DistPackage = $(Invoke-Webrequest $Values.Distributions.English).Content
    (([xml]$DistPackage).ChildNodes.Script[2]).ToString() > .\temp.txt
    Start-Sleep -Milliseconds 250
    $models = Get-Content .\temp.txt | Select-String -pattern "var models"
    Remove-Item .\temp.txt -Force -ErrorAction SilentlyContinue
    $models = $models.ToString().TrimStart().TrimEnd().Replace('var models = ','').Replace(';','').Replace("`',`'",";").Replace("`'",'').Replace('[','').Replace(',]','')
    $SupportedModels = $models.Split(';')

    $BootCampIdentifier = ($Values.Distributions.English.Split('/')[-1]).Replace('.English.dist','')
    Write-output "Found: $BootCampIdentifier"
    $AppleBootCampInstaller = New-Object -TypeName System.Management.Automation.PSObject
    $AppleBootCampInstaller | Add-Member -MemberType NoteProperty -Name "OriginalDownloadLocation" -Value $Values.Packages.URL
    $AppleBootCampInstaller | Add-Member -MemberType NoteProperty -Name "BootCampIdentifier" -Value $BootCampIdentifier
    $AppleBootCampInstaller | Add-Member -MemberType NoteProperty -Name "PostDate" -Value $Values.PostDate
    $AppleBootCampInstaller | Add-Member -MemberType NoteProperty -Name "SupportedModels" -Value $SupportedModels
    $BootCampInstallers += $AppleBootCampInstaller
}
$BootCampInstallers = $BootCampInstallers | sort-object -Property PostDate,SupportedModels -Descending
Write-Output "The latest bootcamp installer is for model $($BootCampInstallers[0].SupportedModels), released on $($BootCampInstallers[0].PostDate) and is located at: " $BootcampInstallers[0].OriginalDownloadLocation ""
