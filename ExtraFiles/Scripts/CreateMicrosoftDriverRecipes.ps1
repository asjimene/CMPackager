$ModelList = Import-CSV -Path "$PSScriptRoot\MicrosoftDrivers.csv"

Foreach ($ModeltoProcess in $ModelList) {
    $Model = $ModeltoProcess.ModelName
    $Downloadid = $ModeltoProcess.linkId
    $ModelShortName = $Model.Replace(' ', '')
    $DownloadLink = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=$Downloadid"
    $DocumentationLink = "https://www.microsoft.com/en-us/download/details.aspx?id=$Downloadid"

    $AvailableDrivers = ((Invoke-WebRequest "$DownloadLink" -UseBasicParsing).Links | Where-Object href -like "*.msi" | Select-Object href -Unique).href
    $DriverNames = Split-Path $AvailableDrivers -Leaf | Sort-Object -Descending
    $AvailableWinVersions = @()
    foreach ($Driver in ($DriverNames | Where-Object { $_ -match "^[\s\S]+_Win10_[\d]{5}_[\s\S]+.msi$" })) {
        $VersionNum = $Driver.Split('_')[2]
        if ($Model -eq "Surface 3") {
            $VersionNum = $Driver.Split('_')[3]
        }
        if ($VersionNum -match "^[\d]{5}$") {
            $AvailableWinVersions += $VersionNum
        }
    }
    $AppTemplate = (Get-Content "$PSScriptRoot\MicrosoftDriverRecipeTemplate.txt").Replace('%MODEL%', $Model).Replace('%MODELSHORTNAME%', $ModelShortName).Replace('%DOCUMENTATIONLINK%', $DocumentationLink).Replace('%DOWNLOADLINK%', $DownloadLink)
    [xml]$AppRecipe = $AppTemplate

    # Choose only the 3 latest versions of Windows 10
    if ($AvailableWinVersions.Count -gt 3) {
        $AvailableWinVersions = $AvailableWinVersions | Select-Object -First 3
    }

    foreach ($WindowsVersion in $AvailableWinVersions) {
        Add-LogContent "Processing Drivers for $ModelShortName for Windows Version $WindowsVersion"
        
        # Clone New Download Node with appropriate Windows Version
        $NewDownload = $AppRecipe.ApplicationDef.Downloads.FirstChild.Clone()
        $NewDownload.DeploymentType = [System.String]$WindowsVersion
        $NewDownload.PrefetchScript = ($NewDownload.PrefetchScript).Replace('%WINVER%', $WindowsVersion)
        $NewDownload.DownloadFileName = ($NewDownload.DownloadFileName).Replace('%WINVER%', $WindowsVersion)
        if ($AvailableWinVersions.IndexOf($WindowsVersion) -ne 0) {
            $NewDownload.DownloadVersionCheck = "#No Version Check for older Versions"
        }
        $AppRecipe.ApplicationDef.Downloads.AppendChild($NewDownload) | Out-Null
        # Clone New DeploymentType Node with appropriate Windows Version
        
        $NewDeploymentType = $AppRecipe.ApplicationDef.DeploymentTypes.FirstChild.Clone()
        $NewDeploymentType.Name = [System.String]$WindowsVersion
        $NewDeploymentType.DeploymentTypeName = [System.String]$WindowsVersion
        $NewDeploymentType.Comments = ($NewDeploymentType.Comments).Replace('%WINVER%', $WindowsVersion)
        $NewDeploymentType.InstallProgram = ($NewDeploymentType.InstallProgram).Replace('%WINVER%', $WindowsVersion)
        $NewDeploymentType.InstallationMSI = ($NewDeploymentType.InstallationMSI).Replace('%WINVER%', $WindowsVersion)
        $NewDeploymentType.Requirements.LastChild."#text" = ($NewDeploymentType.Requirements.LastChild."#text").Replace('%WINVER%', $WindowsVersion)
        $AppRecipe.ApplicationDef.DeploymentTypes.AppendChild($NewDeploymentType) | Out-Null

    }

    # Remove the Template Nodes and Save the Final Result
    $AppRecipe.ApplicationDef.Downloads.RemoveChild($AppRecipe.ApplicationDef.Downloads.FirstChild) | Out-Null
    $AppRecipe.ApplicationDef.DeploymentTypes.RemoveChild($AppRecipe.ApplicationDef.DeploymentTypes.FirstChild) | Out-Null
    $AppRecipe.Save("$ScriptRoot\Recipes\Microsoft$($ModelShortName)Drivers.xml")
}
