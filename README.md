
## macOS Onboarding Tool for Jamf School: V2.0                  

::*Newly updated project which now uses a Configuration Profile to control the script!*::
Admins no longer need to edit anything in the script for easier manipulation and ongoing maintenance 

App deployment/onboarding tool for macOS design for use Jamf School. Onboarder give's visual feedback to Admins or End User while installing applications on deployment of device

---

### macOS Onboarding Tool Dependancies

This workflow utilises
- [Installomator](https://github.com/Installomator/Installomator)
- [swiftDialog](https://github.com/bartreardon/swiftDialog)

Installomator must be installed on the target device(s) prior to running.
swiftDialog will be installed via Installomator in script logic, if not already installed.

Use one of the following to deliver Installomator to target device(s) with Jamf School
1) By scripting installation before running macOS Onboarder Tool                
2) Deploying via a package and then running macOS Onboarder Tool


_**App Icons**_

App icons referenced by a configuration profile need to be on the device prior to running this tool. If you deploy Installomator by a package you could create a custom package which includes both Installomator and the required app icons and deploy that you your target device(s)

V2.0 does not allow for images references to be from the internet. 

*This is a current limitation of the macOS Onboarder Tool logic in this version. I hope to fix this in a future version*

---

### Configuration Profile Manifest

---

### User Guide

Please use the wiki to find full usage guide

---

### Thanks!

This script has been heavily inspired by *"Progress 1st swiftDialog.sh"* & *"Installomator 1st Auto-install DEPNotify.sh"* by
[Søren Theilgaard](https://github.com/Theile)
With help from [scriptingosx](https://scriptingosx.com/) with reading profile keys in bash scripts
