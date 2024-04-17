
## School Assembly: V2.0                  

**Renamed Project: Same tool, new name!**

**Newly updated project which now uses a Configuration Profile to control the script!**
Admins no longer need to edit anything in the script for easier manipulation and ongoing maintenance 

App deployment/onboarding tool for macOS design for use Jamf School. School Assembly give's visual feedback to Admins or End User while installing applications on deployment of device

---

### School Assembly Tool Dependancies

This workflow utilises
- [Installomator](https://github.com/Installomator/Installomator)
- [swiftDialog](https://github.com/bartreardon/swiftDialog)

Installomator must be installed on the target device(s) prior to running.
swiftDialog will be installed via Installomator in script logic, if not already installed.

Use one of the following to deliver Installomator to target device(s) with Jamf School
1) By scripting installation before running School Assembly Tool                
2) Deploying via a package and then running School Assembly Tool


_**App Icons**_

App icons referenced by a configuration profile need to be on the device prior to running this tool. If you deploy Installomator by a package you could create a custom package which includes both Installomator and the required app icons and deploy that you your target device(s)

**V2.0 does not allow for images references to be from the internet.** \
*(This is a current limitation of the School Assembly Tool logic in this version. I hope to fix this in a future version)*

---

### Deployment (Quick Guide)

To use the School Assembly tool follow the steps below
* Install [Installomator](https://github.com/Installomator/Installomator) on the target device(s) via Jamf School prior to using the tool
* Package any icon images and deploy to the target device(s) via Jamf School prior to using the tool
* Create a configuration profile to control the School Assembly tool, there is an [Example Configuration Profile](https://github.com/darlow86/JSmacOS-Onboarder/blob/add-plist/Example%20JSmacOS%20Onboarder%20Profile.mobileconfig) available
* Upload the configuration profile into Jamf School and deploy to target device(s)
* Copy the [School Assembly script](https://github.com/darlow86/JSmacOS-Onboarder/blob/add-plist/jsmacos-onboarder.sh) into Jamf School
* Scope and deploy to target device(s)
* School Assembly tool will run on target device(s), installing swiftDialog if required

If there is no user logged into the device the tool will wait until, checking every 5 seconds, until there is a user logged in before running

If there is no configuration profile installed a notification will be displayed onscreen and the tool will exit

Logs for the School Assembly script can be found at /var/tmp/jsmacOSOnboarder.log

For full detailed deployment steps visit the **[Wiki](https://github.com/darlow86/JSmacOS-Onboarder/wiki)**

---


### Configuration Profile Manifest

When creating the configuration profile for School Assembly you may wish to use popular GUI tools [Profile Creator](https://github.com/ProfileCreator/ProfileCreator) or [iMazing Profile Editor](https://imazing.com/profile-editor)

Install the [Configuration Profile Manifest](https://github.com/darlow86/JSmacOS-Onboarder/tree/add-plist/Profile%20Configuration%20Manifest) to your local machine to build the required configuration profile through Profile Creator or iMazing Profile Editor

For guides on where to install the manifest plist visit [Profile Creator Manifest Instructions](https://github.com/ProfileCreator/ProfileManifests/wiki/Getting-Started#how-to-create-a-profile-manifest) or [iMazing Profile Editor Instructions](https://imazing.com/guides/imazing-profile-editor-working-with-custom-preference-manifests) 


---

### User Guide

Please use the **[Wiki](https://github.com/darlow86/JSmacOS-Onboarder/wiki)** to find full usage guide

---

### Thanks!

This script has been heavily inspired by *"Progress 1st swiftDialog.sh"* & *"Installomator 1st Auto-install DEPNotify.sh"* by
[Søren Theilgaard](https://github.com/Theile)

With help from [scriptingosx](https://scriptingosx.com/) with reading profile keys in bash scripts
