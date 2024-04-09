
## macOS App Onboarding for Jamf School: V1.0                  
                                                                             
 App deployment/onboarding process for macOS with use for Jamf School that give's visual feedback to Admin in suite situations or end users for 1:1  deployments. 
 
 This workflow utilises
 - [Installomator](https://github.com/Installomator/Installomator)
 - [swiftDialog](https://github.com/bartreardon/swiftDialog)                

Both of which need to be installed on the target devices prior to running.
For use with Jamf School this could be
1) By scripting their installation before running this script                
2) Deploying via a package and then running this script 
3) By creating a custom package which first installs Installomator & swiftDialog and then runs this script as a postinstall script

Icons referenced in this script also need to be on the device prior to running this script. This should be done for Jamf School via a custom package.
If you use option 3 above icons can be included in the 'onboarder' package which then has everything needed for this workflow and can be deployed as a single package.

This script has been heavily inspired by *"Progress 1st swiftDialog.sh"* & *"Installomator 1st Auto-install DEPNotify.sh"* by
[Søren Theilgaard](https://github.com/Theile)               

Edit below here
App deployment/onboarding process for macOS with use for Jamf School that give's visual feedback to Admin in suite situations or end users for 1:1 deployments.

This workflow utilises
- Installomator - https://github.com/Installomator/Installomator
- Swiftdialog - https://github.com/bartreardon/swiftDialog                  

Both of which need to be installed on the target devices prior to running.
For use with Jamf School this could be
1) By scripting their installation before running this script
2) Deploying via a package and then running this script
3) By creating a custom package which first installs Installomator & Swiftdialog and then runs this script as a postinstall script


Icons referenced in this script also need to be on the device prior to running this script. This should be done for Jamf School via a custom package. If you use option 3 above icons can be included in the 'onboarder' package which then has everything needed for this workflow and can be deployed as a single package.