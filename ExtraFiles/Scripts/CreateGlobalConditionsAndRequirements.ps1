$Windows10Versions = "10586","14393","15063","16299","17134","17763","18362"
$ModelQueries = (Import-CSV "$PSScriptRoot\MicrosoftDrivers.csv").ModelName
$SystemSKUQueries = (Import-CSV "$PSScriptRoot\MicrosoftDrivers.csv").SystemSKU
$ManufacturerQueries = "Microsoft Corporation"

$BIOSProvScript = '$Make = (Get-WmiObject Win32_ComputerSystem).Manufacturer
$Family = (Get-WmiObject Win32_ComputerSystem).Model
$SMBIOS = "$((Get-WmiObject Win32_BIOS).SMBIOSMajorVersion).$((Get-WmiObject Win32_BIOS).SMBIOSMinorVersion)"
$PowershellVersion = $PSVersionTable.PSVersion.Major

if (($Make -like "Dell*") -and (($Family -like "*Optiplex*") -or ($Family -like "*Latitude*") -or ($Family -like "*XPS*") -or ($Family -like "*Venue*")) -and (($SMBIOS -ge 2.3) -and ($PowershellVersion -ge 3))){
    Write-Output $true
} else {
    Write-Output $false
}'

$BIOSProvDescription = 'Determines if the Dell PowerShell Provider can be installed:
Make = Dell
Model = Latitude, Optiplex, Precision, Venue, XPS
SMBIOS Version = Greater Than or Equal to 2.3
PowerShell Version = Greater Than or Equal to 3.0'

if (-not (Get-Module ConfigurationManager)) {
    try {
        Add-LogContent "Importing ConfigurationManager Module"
        Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    } 
    catch {
        $ErrorMessage = $_.Exception.Message
        Add-LogContent "ERROR: Importing ConfigurationManager Module Failed!"
        Add-LogContent "ERROR: $ErrorMessage"
    }
}

Push-Location
Set-Location $Global:SCCMSite
Add-LogContent "Creating Global Conditions - If Needed"
if (-not (Get-CMGlobalCondition -Name "AutoPackage - Windows 10 Build Number Integer")){
    New-CMGlobalConditionWqlQuery -DataType Integer -Class Win32_OperatingSystem -Namespace root\cimv2 -Property BuildNumber -Name "AutoPackage - Windows 10 Build Number Integer" -Description "Returns the Windows 10 Build Number as an Integer (Good for determining if a build is greater than or less than a current build)"
}

if (-not (Get-CMGlobalCondition -Name "AutoPackage - Computer Manufacturer")) {
    New-CMGlobalConditionWqlQuery -DataType String -Class Win32_ComputerSystem -Namespace root\cimv2 -Property Manufacturer -Name "AutoPackage - Computer Manufacturer" -Description "Returns the Manufacturer from ComputerSystem\Manufacturer"
}

if (-not (Get-CMGlobalCondition -Name "AutoPackage - Computer Model")) {
    New-CMGlobalConditionWqlQuery -DataType String -Class Win32_ComputerSystem -Namespace root\cimv2 -Property Model -Name "AutoPackage - Computer Model" -Description "Returns the Model from ComputerSystem\Model"
}

if (-not (Get-CMGlobalCondition -Name "AutoPackage - Computer SystemSKU")) {
    New-CMGlobalConditionWqlQuery -DataType String -Class MS_SystemInformation -Namespace root\wmi -Property SystemSKU -Name "AutoPackage - Computer SystemSKU" -Description "Returns the SystemSKU from MS_SystemInformation"
}

if (-not (Get-CMGlobalCondition -Name "AutoPackage - OSArchitecture x64")) {
    New-CMGlobalConditionWqlQuery -DataType String -Class Win32_OperatingSystem -Namespace root\cimv2 -Property OSArchitecture -WhereClause "OSArchitecture = `'64-bit`'" -Name "AutoPackage - OSArchitecture x64" -Description "Returns True if Win32_OperatingSystem is True. Use as existential rule for 64-bit operating system"
}

if (-not (Get-CMGlobalCondition -Name "AutoPackage - DellBIOSProvider Prereq Check")) {
    New-CMGlobalConditionScript -DataType Boolean -ScriptLanguage PowerShell -ScriptText $BIOSProvScript -Name "AutoPackage - DellBIOSProvider Prereq Check" -Description $BIOSProvDescription
}

# Only add the Requirements if the Application Already Exists
if (Get-CMApplication -Name $Global:RequirementsTemplateAppName -Fast) {
    $ApplicationTemplateDTName = (Get-CMApplication -name $Global:RequirementsTemplateAppName | ConvertTo-CMApplication).DeploymentTypes[0].Title
    $ExistingRequirements = (Get-CMApplication -Name $Global:RequirementsTemplateAppName | ConvertTo-CMApplication).DeploymentTypes[0].Requirements.Name
    Add-logcontent "Adding All Requirements to $RequirementsTemplateAppName : $ApplicationTemplateDTName"
    Add-logContent "Existing Requirements: `r`n$($ExistingRequirements -join "`r`n")" 
    
    # Add Operating System Query to Template
    Add-LogContent "Processing - Add Operating System Not Windows 10 to Template"
    if (-not ($ExistingRequirements -contains "Operating System None of {All Windows 10 (64-bit), All Windows 10 (32-bit)}")) {
        Add-Logcontent "Adding: Operating system None of {All Windows 10 (64-bit), All Windows 10 (32-bit)}"
        $GlobalCondition = Get-CMGlobalCondition -name "Operating System" | Where-Object PlatformType -eq 1
        $Platforms = "Windows/All_x64_Windows_10_and_higher_Clients", "Windows/All_x86_Windows_10_and_higher_Clients"
        $rule = $GlobalCondition | New-CMRequirementRuleOperatingSystemValue -RuleOperator NoneOf -PlatformStrings $Platforms
        $rule.Name = "Operating system None of {All Windows 10 (64-bit), All Windows 10 (32-bit)}"
        Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
    }
    
    # Add OS Architecture Query to Template
    Add-LogContent "Processing - Add OS Architecture to Template"
    if (-not ($ExistingRequirements -contains "Existential of AutoPackage - OSArchitecture x64 Not Equal to 0")) {
        Add-LogContent "OSArchitecture x64 is being added"
        $rule = Get-CMGlobalCondition -Name "AutoPackage - OSArchitecture x64" | New-CMRequirementRuleExistential -Existential $true
        $rule.Name = "Existential of AutoPackage - OSArchitecture x64 Not Equal to 0"
        Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
    }

    # Add Windows 10 Versions to Template
    Add-LogContent "Processing - Add Windows 10 Versions to Template"
    foreach ($Version in $Windows10Versions) {
        if (-not ($ExistingRequirements -contains "AutoPackage - Windows 10 Build Number Integer Greater than or equal to $Version")) {
            Add-LogContent "`"$Version`" is being added"
            $rule = Get-CMGlobalCondition -Name "AutoPackage - Windows 10 Build Number Integer" | New-CMRequirementRuleCommonValue -Value1 $Version -RuleOperator GreaterEquals
            $rule.Name =  "AutoPackage - Windows 10 Build Number Integer Greater than or equal to $Version"
            Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
        }
    }

    # Add Model Queries to Template
    Add-LogContent "Processing - Add Models to Template"
    foreach ($Model in $ModelQueries) {
        if (-not ($ExistingRequirements -contains "AutoPackage - Computer Model Equals $Model")) {
            Add-LogContent "`"$Model`" is being added"
            $rule = Get-CMGlobalCondition -Name "AutoPackage - Computer Model" | New-CMRequirementRuleCommonValue -Value1 "$Model" -RuleOperator IsEquals 
            $rule.Name = "AutoPackage - Computer Model Equals $Model"
            Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
        }
    }

    # Add Manufacturer Queries to Template
    Add-LogContent "Processing - Add Manufacturers to Template"
    foreach ($Manufacturer in $ManufacturerQueries) {
        if (-not ($ExistingRequirements -contains "AutoPackage - Computer Manufacturer Equals $Manufacturer")) {
            Add-LogContent "`"$Manufacturer`" is being added"
            $rule = Get-CMGlobalCondition -Name "AutoPackage - Computer Manufacturer" | New-CMRequirementRuleCommonValue -Value1 "$Manufacturer" -RuleOperator IsEquals 
            $rule.Name = "AutoPackage - Computer Manufacturer Equals $Manufacturer"
            Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
        }
    }

    Add-LogContent "Processing - Add SystemSKU to Template"
    foreach ($SystemSKU in $($SystemSKUQueries | where-object {$_ -ne ""})) {
        $SystemSKUSplit = $SystemSKU.Split(",")
        $SystemSKU = $SystemSKU.Replace(',',', ')
        if (-not ($ExistingRequirements -contains "AutoPackage - Computer SystemSKU OneOf {$SystemSKU}")) {
            Add-LogContent "`"$SystemSKU`" is being added"
            $rule = Get-CMGlobalCondition -Name "AutoPackage - Computer SystemSKU" | New-CMRequirementRuleCommonValue -Value1 $SystemSKUSplit -RuleOperator OneOf 
            $rule.Name = "AutoPackage - Computer SystemSKU OneOf {$SystemSKU}"
            Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
        }
    }

    # Add Dell BIOS Provider Prereq Check
    Add-LogContent "Processing - DellBIOSProvider to Template"
    if (-not ($ExistingRequirements -contains "AutoPackage - DellBIOSProvider Prereq Check Not Equal to 0")) {
        Add-LogContent "DellBIOSProvider Prereq Check is being added"
        $rule = Get-CMGlobalCondition -Name "AutoPackage - DellBIOSProvider Prereq Check" | New-CMRequirementRuleExistential -Existential $true 
        $rule.Name = "Existential of AutoPackage - DellBIOSProvider Prereq Check Not Equal to 0"
        Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
    }
} Else {
    Add-LogContent "WARN: The Requirements Application is being created, please run the SCCMPackager again to finish prerequisite setup and begin packaging software."
    $Global:TemplateApplicationCreatedFlag = $true
}

Pop-Location