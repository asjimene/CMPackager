# SCCM Application Packager

This Application is a PowerShell Script that can be used to create applications in SCCM, it takes care of downloading, packaging, distributing and deploying the applications described in XML "recipe" files. The goal is to be able to package any frequently updating application with little to no work after creating the recipes.

## Getting Started

1. Download the Project
2. Set up your SCCM Preferences in the SCCMPackager.prefs file (it is a standard XML file)
3. Check out the Recipes in the "Disabled" Folder, Modify them to your needs, and copy them into the "Recipes" Folder (Note: Some Recipes Require 7-Zip which is not included)
4. Run the SCCMPackager.ps1 - This will automatically create an Application Requirements Template App and Appropriate Global Conditions. Check the ExtraFiles\Scripts folder for more information
5. Run the SCCMPackager.ps1 once more - This will add the requirements to the Application Requirements Template App, and begin packaging software
6. Future runs will update the Application Requirements Template app's requirements list.

### Prerequisites

SCCM ConfigMgr Console - Tested on SCCM 1710

Some Recipes require the 7za.exe from the 7-Zip Project, which can be found here: [Project Page](https://www.7-zip.org/) - 7za.exe should be placed in the same folder as the SCCMPackager.ps1 Application.

### Installing

Setting Up the Requirements Template Application

1. Run the SCCMPackager.ps1 with the "_Application Requirements Template.xml" in the Recipes folder. The first run will create the "Application Requirements Template 1" Application in SCCM and exit.
2. Run the SCCMPackager.ps1 with the "_Application Requirements Template.xml" in the Recipes folder again. This run will add all Requiremtents to the template Application. It will then process all other recipes as normal.

### Enabling the Packaging of Microsoft Surface Device Drivers and Firmware

1. Open the "_Application Requirements Template.xml" and remove the comments on the following lines:
	#Add-LogContent "Updating Microsoft Surface Drivers Recipes";
	#Invoke-Expression ".\ExtraFiles\Scripts\CreateMicrosoftDriverRecipes.ps1";
2. Navigate to ".\ExtraFiles\Scripts" and open "MicrosoftDrivers.csv", Remove any Drivers that you want packaged, All models currently supported by the script should already be there.
3. Run the SCCMPackager App as usual (with the "_Application Requirements Template.xml" Recipe in the recipes folder), the first run will create the recipes and put them in the recipes folder, future runs will update the recipes and download the drivers.


## Contributing

Feel free to create your own Recipes, Contribute to the main code, or provide feedback!

* If you have questions feel free to post an issue with the "Question" tag here on GitHub, or ask me on Twitter (publicly is preferred, but I don't mind DMs)


## Authors

* **Andrew Jimenez** - *Main Author* - [asjimene](https://github.com/asjimene)

See also the list of [contributors](https://github.com/asjimene/SCCM-Application-Packager/graphs/contributors) who participated in this project.


## Acknowledgments

Used and Modified code from the following, Thanks to all their work: 

* Janik von Rots - [Copy-CMDeploymentTypeRule](https://janikvonrotz.ch/2017/10/20/configuration-manager-configure-requirement-rules-for-deployment-types-with-powershell/) 

* Jaap Brasser - [Get-ExtensionAttribute](http://www.jaapbrasser.com) 

* Nickolaj Andersen - [Get-MSIInfo](http://www.scconfigmgr.com/2014/08/22/how-to-get-msi-file-information-with-powershell/)


## NOTE
This Project does not provide Applications directly, Recipies provide the links to the Applications. Downloading and packaging software using this tool does not grant you a license for the software. Please ensure you are properly licensed for all software you package and distribute!
