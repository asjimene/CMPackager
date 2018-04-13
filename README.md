# SCCM Application Packager

This Application is a PowerShell Script that can be used to create applications in SCCM, it takes care of downloading, packaging, distributing and deploying the applications described in XML "recipe" files. The goal is to be able to package any frequently updating application with little to no work after creating the recipes.

## Getting Started

1. Download the Project
2. Set up your SCCM Preferences in the SCCMPackager.prefs file (it is a standard XML file)
3. Create the Requirements Template Application in SCCM and set any Rules that you need in that Application (Instructions Below)
4. Check out the Recipes in the "Disabled" Folder, Modify them to your needs, and copy them into the "Recipes" Folder (Note: Some Recipes Require 7-Zip which is not included)
5. Run the SCCMPackager.ps1 (I have mine set up as a scheduled task to run twice a day)

### Prerequisites

SCCM ConfigMgr Console - Tested on SCCM 1710
Some Recipes require the 7za.exe from the 7-Zip Project, which can be found here: [Project Page](https://www.7-zip.org/) 7za.exe should be placed in the same folder as the SCCMPackager.ps1 Application.

### Installing

Setting Up the Requirements Template Application

1. Set the Name for your requirements Template Application in SCCM
2. Create an Application in your SCCM environment with that same name
3. Use a "script installer" and for the installation program, just use something that will close immediately, i just used "hostname"
NOTE: There is now a default recipe in the Recipes folder that does step 1, 2 and 3 for you! All you have to do now is add the requirements to the deployment type created there.
4. Add any requirements that you plan to use for the packager to this App, OS Version, and architecture are most common

## Contributing

Feel free to create your own packages, Contribute to the main code, or provide feedback!

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
