$Windows10Versions = "10586","14393","15063","16299","17134","17763"
$ModelQueries = (Import-CSV "$PSScriptRoot\MicrosoftDrivers.csv").ModelName
$ManufacturerQueries = "Microsoft Corporation"

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

if (-not (Get-CMGlobalCondition -Name "AutoPackage - OSArchitecture x64")) {
    New-CMGlobalConditionWqlQuery -DataType String -Class Win32_ComputerSystem -Namespace root\cimv2 -Property OSArchitecture -WhereClause "OSArchitecture = `'64-bit`'" -Name "AutoPackage - OSArchitecture x64" -Description "Returns True if Win32_ComputerSystem is True. Use as existential rule for 64-bit operating system"
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
    if (-not ($ExistingRequirements -contains "AutoPackage - OSArchitecture x64 Equals True")) {
        Add-LogContent "OSArchitecture x64 is being added"
        $rule = Get-CMGlobalCondition -Name "AutoPackage - OSArchitecture x64" | New-CMRequirementRuleCommonValue -Value1 $true -RuleOperator IsEquals
        $rule.Name = "AutoPackage - OSArchitecture x64 Equals True"
        Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
    }

    # Add Windows 10 Versions to Template
    Add-LogContent "Processing - Add Windows 10 Versions to Template"
    foreach ($Version in $Windows10Versions) {
        if (-not ($ExistingRequirements -contains "AutoPackage - Windows 10 Build Number Integer Greater than or equal to $Version")) {
            Add-LogContent "$Version is being added"
            $rule = Get-CMGlobalCondition -Name "AutoPackage - Windows 10 Build Number Integer" | New-CMRequirementRuleCommonValue -Value1 $Version -RuleOperator GreaterEquals
            $rule.Name =  "AutoPackage - Windows 10 Build Number Integer Greater than or equal to $Version"
            Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
        }
    }

    # Add Model Queries to Template
    Add-LogContent "Processing - Add Models to Template"
    foreach ($Model in $ModelQueries) {
        if (-not ($ExistingRequirements -contains "AutoPackage - Computer Model Equals $Model")) {
            Add-LogContent "$Model is being added"
            $rule = Get-CMGlobalCondition -Name "AutoPackage - Computer Model" | New-CMRequirementRuleCommonValue -Value1 $Model -RuleOperator IsEquals 
            $rule.Name = "AutoPackage - Computer Model Equals $Model"
            Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
        }
    }

    # Add Manufacturer Queries to Template
    Add-LogContent "Processing - Add Manufacturers to Template"
    foreach ($Manufacturer in $ManufacturerQueries) {
        if (-not ($ExistingRequirements -contains "AutoPackage - Computer Manufacturer Equals $Manufacturer")) {
            Add-LogContent "$Manufacturer is being added"
            $rule = Get-CMGlobalCondition -Name "AutoPackage - Computer Manufacturer" | New-CMRequirementRuleCommonValue -Value1 $Manufacturer -RuleOperator IsEquals 
            $rule.Name = "AutoPackage - Computer Manufacturer Equals $Manufacturer"
            Set-CMScriptDeploymentType -ApplicationName $Global:RequirementsTemplateAppName -DeploymentTypeName $ApplicationTemplateDTName -AddRequirement $rule
        }
    }
} Else {
    Add-LogContent "WARN: The Requirements Application is being created, please run the SCCMPackager again to finish prerequisite setup and begin packaging software."
    $Global:TemplateApplicationCreatedFlag = $true
}

Pop-Location