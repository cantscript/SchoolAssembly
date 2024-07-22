## School Assembly: V3.0                  

**New for Version 3.0 - Assembly Builder** <br>
Reduce School Assembly deployment complexity by creating a single package with all resources rather than following many steps


Assembly Builder is a script that accepts a number of build options and results in a _**single package**_ which includes the School Assembly tool, installomator and optionally any icons required. 

---

<p align="center">
<img width="256" alt="mac1024" src="https://github.com/cantscript/SchoolAssembly/blob/main/Images/SchoolAssemblyIcon.png">
</p>


App deployment/onboarding tool for macOS design for use Jamf School. School Assembly give's visual feedback to Admins or End User while installing applications on deployment of device. Admins no longer need to edit anything in the script for easier manipulation and ongoing maintenance

<img width="576" src="https://github.com/cantscript/SchoolAssembly/blob/main/Images/School%20Assembly%20Window.png">

---

### School Assembly Tool Dependancies

This workflow utilises
- [Installomator](https://github.com/Installomator/Installomator)
- [swiftDialog](https://github.com/bartreardon/swiftDialog)

Installomator must be installed on the target device(s) prior to running.
swiftDialog will be installed via Installomator in script logic, if not already installed.

Use one of the following to deliver Installomator to target device(s) with Jamf School <br>
1) RECOMMENDED (V3.0+) Use Assembly Builder and deploy to devices <br>
2) By scripting installation before running School Assembly Tool                <br>
3) Deploying via a package and then running School Assembly Tool


See **[Wiki](https://github.com/darlow86/JSmacOS-Onboarder/wiki)** for more information

---

### Deployment (Quick Guide)

To use the School Assembly tool follow the steps below
* Install [Installomator](https://github.com/Installomator/Installomator) on the target device(s) via Jamf School prior to using the tool
* Package any icon images and deploy to the target device(s) via Jamf School prior to using the tool
* Create a configuration profile to control the School Assembly tool, there is an [Example Configuration Profile](https://github.com/cantscript/SchoolAssembly/blob/main/plist%20example/com.cantscript.schoolassembly.plist) available
* Upload the configuration profile into Jamf School and deploy to target device(s)
* Build School Assembly Package using Assembly Builder
* Scope and deploy to target device(s)
* School Assembly tool will run on target device(s), installing swiftDialog if required

If there is no user logged into the device the tool will wait until, checking every 5 seconds, until there is a user logged in before running

If there is no configuration profile installed a notification will be displayed onscreen and the tool will exit

Logs for the School Assembly script can be found at `/var/tmp/jsmacOSOnboarder.log` \
Once School Assembly has ran it creates a done flag in the following location which will prevent further runs of School Assembly, until removed: `/Users/Shared/.SchoolAssembled`

For full detailed deployment steps visit the **[Wiki](https://github.com/darlow86/JSmacOS-Onboarder/wiki)**

---


### Configuration Profile Manifest

When creating the configuration profile for School Assembly you may wish to use popular GUI tools [Profile Creator](https://github.com/ProfileCreator/ProfileCreator) or [iMazing Profile Editor](https://imazing.com/profile-editor)

Install the [Configuration Profile Manifest](https://github.com/cantscript/SchoolAssembly/blob/main/Profile%20Configuration%20Manifest/com.cantscript.schoolassembly.plist) to your local machine to build the required configuration profile through Profile Creator or iMazing Profile Editor

For guides on where to install the manifest plist visit [Profile Creator Manifest Instructions](https://github.com/ProfileCreator/ProfileManifests/wiki/Getting-Started#how-to-create-a-profile-manifest) or [iMazing Profile Editor Instructions](https://imazing.com/guides/imazing-profile-editor-working-with-custom-preference-manifests) 


---

### User Guide

Please use the **[Wiki](https://github.com/darlow86/JSmacOS-Onboarder/wiki)** to find full usage guide

---

### Thanks!

This script has been heavily inspired by *"Progress 1st swiftDialog.sh"* & *"Installomator 1st Auto-install DEPNotify.sh"* by
[Søren Theilgaard](https://github.com/Theile)

With help from [scriptingosx](https://scriptingosx.com/) with reading profile keys in bash scripts
