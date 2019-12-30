# CMPackager

This Application is a PowerShell Script that can be used to create applications in SCCM, it takes care of downloading, packaging, distributing and deploying the applications described in XML "recipe" files. The goal is to be able to package any frequently updating application with little to no work after creating the recipes.


## Getting Started

1. Download the Project
2. Set up your SCCM Preferences in the CMPackager.prefs file (it is a standard XML file)
3. Check out the Recipes in the "Disabled" Folder, Modify them to your needs, and copy them into the "Recipes" Folder
4. Run CMPackager.ps1 - Recipes in the "Recipes" folder will be packaged if required. Note that some packages require admin to be packaged (App is installed then uninstalled to grab version info)


### Prerequisites

MEM ConfigMgr Console - Tested on SCCM 1906 - works best if the console has been opened at least once.


### Enabling the Packaging of Microsoft Surface Device Drivers and Firmware

1. Add the "MicrosoftSurfaceDrivers.xml" Recipe to the "Recipes" folder
2. Navigate to ".\ExtraFiles\Scripts" and open "MicrosoftDrivers.csv", Remove any Drivers that you want packaged, All models currently supported by the script should already be there.
3. Run CMPackager as usual, the first run will create the recipes and place them in the recipes folder, future runs will update the recipes and download the drivers.


## Contributing

Feel free to create your own Recipes, Contribute to the main code, or provide feedback!

* If you have questions feel free to post an issue with the "Question" label here on GitHub, or ask me on Twitter (publicly is preferred, but I don't mind DMs)


## Authors

* **Andrew Jimenez** - *Main Author* - [asjimene](https://github.com/asjimene)

See also the list of [contributors](https://github.com/asjimene/SCCM-Application-Packager/graphs/contributors) who participated in this project.


## Acknowledgments

Used and Modified code from the following, Thanks to all for their work: 

* Janik von Rots - [Copy-CMDeploymentTypeRule](https://janikvonrotz.ch/2017/10/20/configuration-manager-configure-requirement-rules-for-deployment-types-with-powershell/) 

* Jaap Brasser - [Get-ExtensionAttribute](http://www.jaapbrasser.com) 

* Nickolaj Andersen - [Get-MSIInfo](http://www.scconfigmgr.com/2014/08/22/how-to-get-msi-file-information-with-powershell/)


## NOTE

This Project does not provide Applications directly, Recipies provide the links to the Applications. Downloading and packaging software using this tool does not grant you a license for the software. Please ensure you are properly licensed for all software you package and distribute!
