#!/bin/bash

############################################################
# License information
#########################################################################################
#
#      Copyright (c) 2023, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
##########################################################################################

################################################################################
#                                                                              #
#                  macOS App Onboarding for Jamf School: V1.0                  #
#                                                                              #
#  App deployment/onboarding process for macOS with use for Jamf School that   #
#  give's visual feedback to Admin in suite situations or end users for 1:1    #
#  deployments.                                                                #
#                                                                              #
#  This workflow utilises                                                      #
#  - Installomator - https://github.com/Installomator/Installomator            #
#  - Swiftdialog - https://github.com/bartreardon/swiftDialog                  #
#                                                                              #
#  Both of which need to be installed on the target devices prior to running.  #
#  For use with Jamf School this could be                                      #
#  1) By scripting their installation before running this script               #
#  2) Deploying via a package and then running this script                     #
#  3) By creating a custom package which first installs Installomator &        #
#	  Swiftdialog and then runs this script as a postinstall script            #
#                                                                              #
#  Icons referenced in this script also need to be on the device prior to      #
#  running this script. This should be done for Jamf School via a custom       #
#  package.                                                                    #
#  If you use option 3 above icons can be included in the 'onboarder' package  #
#  which then has everything needed for this workflow and can be deployed as   #
#  a single package.                                                           #
#                                                                              #
#  This script has been heavily inspired by "Progress 1st swiftDialog.sh" &    #
#  "Installomator 1st Auto-install DEPNotify.sh" by                            #
#  Søren Theilgaard                                                            #
#  https://github.com/Theile                                                   #
#                                                                              #
#  Script by Anthony Darlow - December 2022                                    #
#  By using this script you do so understanding the script creator is not      #
#  responsible for any undesired outcomes of using this script and comes       #
#  without any support                                                         #
################################################################################


################################################################################
#                                                                              #
#                Variables - Set by Configuration Profile                      #
#                                                                              #
################################################################################

jsOnboarderLog=/var/tmp/jsmacOSOnboarder.log

if [ -f $jsOnboarderLog ]; then
	rm $jsOnboarderLog
fi

echo "For detailed Installomator logs: /private/var/log/Installomator.log" >> $jsOnboarderLog
echo "For detailed swiftDialog control logs: /var/tmp/dialog.log" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

### Preferences Reader Func ###

MANAGED_PREFERENCE_DOMAIN="com.jsmacos.onboarder5"

getPref() { # $1: key, $2: default value, $3: domain
	local key=${1:?"key required"}
	local defaultValue=${2-:""}
	local domain=${3:-"$MANAGED_PREFERENCE_DOMAIN"}
	
	value=$(osascript -l JavaScript \
		-e "$.NSUserDefaults.alloc.initWithSuiteName('$domain').objectForKey('$key').js")
	
	if [[ -n $value ]]; then
		echo $value
	else
		echo $defaultValue
	fi
}


# # # # # # # # # # # # # # # # # # # # # # #
#  Option to run local or through script.   #
#  Local uses Sudo, needs Password and      #
#  disables "full-screen blur".             #
#                                           #
#  If you run the script with "false"       #
#  locally (ie without the password) All    #
#  Installomator installs will error due to #
#  needing to be run as root.               #
#                                           #
#       true=Local false=Via Script         #
# # # # # # # # # # # # # # # # # # # # # # #
runOption=$(getPref "runLocal" "false")

### Logging Option ###
### false= Standard true= Verbose ###
installAppLogging=$(getPref "appLogging" "false")



######################################
#  Get details of Apps to Install    #
# from plist / profile and turn into #
#             an array               #
######################################


### Dump plist key into a variable ###
appList=$(getPref "AppInstalls")

### Change IFS for workflow ###
oldIFS=
IFS=,

### Logic to define how many apps are to be installed ###
echo ">>>> Starting...App Installs" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "Converting Prefs into script Vars" >> $jsOnboarderLog
installArray=($appList)
installItemsNo=${#installArray[@]}
let requiredApps=$installItemsNo/3
echo "There are $installItemsNo items, resulting in $requiredApps Apps to be installed" >> $jsOnboarderLog
echo "-----------" >> $jsOnboarderLog

### Pre-flight varibles ###
apps=()
appCounter=1
indexPoint=0
echo "Iterating through apps to be installed" >> $jsOnboarderLog
echo "R= # of required apps | I= Start index point of array | Current App count" >> $jsOnboarderLog

### Create App Install array for Switdialog ###
while [ $appCounter -le $requiredApps ]; do
	apps+=(${installArray[@]:$indexPoint:3})
	echo "R:$requiredApps | I: $indexPoint | Added App: $appCounter " >> $jsOnboarderLog
	indexPoint=$(($indexPoint+3))
	((appCounter++))
done
echo "The resulting array contains ${#apps[@]} Apps to be installed" >> $jsOnboarderLog


### Success / Error Message ###
echo "-----------" >> $jsOnboarderLog
if [ $requiredApps = ${#apps[@]} ]; then
	echo "SUCCESS: $requiredApps apps where read from Prefs & ${#apps[@]} Apps have been added to Onboarder script" >> $jsOnboarderLog
else
	echo "ERROR: $requiredApps apps where read from Prefs but ${#apps[@]} Apps have been added to Onboarder script" >> $jsOnboarderLog
fi

echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

if [[  $installAppLogging == "true" ]]; then
	for items in "${apps[@]}"; do
		echo "Verbose App Logging details for Apps to be Installed" >> $jsOnboarderLog
		echo "Icon Location: "$( echo "$items" | cut -d ':' -f2 | cut -d '"' -f1 | tr -d '\')"" >> $jsOnboarderLog
		echo "Display Name: "$(echo "$items" | cut -d ':' -f3 | cut -d '"' -f1)"" >> $jsOnboarderLog
		echo "Installomator Label: "$(echo "$items" | cut -d ':' -f4 | cut -d '"' -f1 | tr -d '\')"" >> $jsOnboarderLog
		echo "" >> $jsOnboarderLog
		echo "################################" >> $jsOnboarderLog
		echo "################################" >> $jsOnboarderLog
		echo "" >> $jsOnboarderLog
		
	done
fi

### Return IFS to original state ###
IFS=$oldIFS

### End Process ###
echo "<<<< Ending...App Installs" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

######################################
#  Get details of Apps to Watch      #
# from plist / profile and turn into #
#             an array               #
######################################


### Dump plist key into a variable ###
watchList=$(getPref "AppWatch")

### Change IFS for workflow ###
oldIFS=
IFS=,

### Logic to define how many apps are to be watched ###
echo ">>>> Starting...App Watch Paths" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "Converting Prefs into script Vars" >> $jsOnboarderLog
watchArray=($watchList)
watchItemsNo=${#watchArray[@]}
let requiredWatchApps=$watchItemsNo/3
echo "There are $watchItemsNo items, resulting in $requiredWatchApps Apps to be watched" >> $jsOnboarderLog
echo "-----------" >> $jsOnboarderLog

### Pre-flight varibles ###
storeInstalls=()
watchCounter=1
indexPoint=0
echo "Iterating through apps to be watched" >> $jsOnboarderLog
echo "R= # of required apps | I= Start index point of array | Current App count" >> $jsOnboarderLog


### Create App watch list array for Switdialog ###
while [ $watchCounter -le $requiredWatchApps ]; do
	storeInstalls+=(${watchArray[@]:$indexPoint:3})
	echo "R:$requiredWatchApps | I: $indexPoint | Added App: $watchCounter " >> $jsOnboarderLog
	indexPoint=$(($indexPoint+3))
	((watchCounter++))
done
echo "The resulting array contains ${#storeInstalls[@]} Apps to be watched" >> $jsOnboarderLog


### Success / Error Message ###
echo "-----------" >> $jsOnboarderLog
if [ $requiredWatchApps = ${#storeInstalls[@]} ]; then
	echo "SUCCESS: $requiredWatchApps apps where read from Prefs & ${#storeInstalls[@]} Apps have been added to Onboarder script" >> $jsOnboarderLog
else
	echo "ERROR: $requiredWatchApps apps where read from Prefs but ${#storeInstalls[@]} Apps have been added to Onboarder script" >> $jsOnboarderLog
fi

echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

if [[  $installAppLogging == "true" ]]; then
	for items in "${storeInstalls[@]}"; do
		echo "Verbose App Logging details for Apps to be Watched" >> $jsOnboarderLog
		echo "Icon Location: "$( echo "$items" | cut -d ':' -f2 | cut -d '"' -f1 | tr -d '\')"" >> $jsOnboarderLog
		echo "App Location: "$(echo "$items" | cut -d ':' -f3 | cut -d '"' -f1)"" >> $jsOnboarderLog
		echo "Display Name: "$(echo "$items" | cut -d ':' -f4 | cut -d '"' -f1 | tr -d '\')"" >> $jsOnboarderLog
		echo "" >> $jsOnboarderLog
		echo "################################" >> $jsOnboarderLog
		echo "################################" >> $jsOnboarderLog
		echo "" >> $jsOnboarderLog
	done
fi

### Return IFS to original state ###
IFS=$oldIFS

### End Process ###
echo "<<<< Ending...App Watch Paths" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

####Personalise Window Text with logged-in user or computer name####
windowGreeting=""
currentUser="$(stat -f "%Su" /dev/console | cut -d '.' -f1)" #true
compName="$(hostname -f | sed -e 's/^[^.]*\.//')"            #false
personalOption=$(getPref "userGreeting" "false")
if [[ $personalOption = "true" ]]; then
	windowGreeting=$currentUser
else
	windowGreeting=$compName
fi

####Main Window Text Options###
dialogTitle="Let's build $windowGreeting's Mac"
dialogMessage=$(getPref "mainMessage" "Lets install some apps on your device! This might take a while....")


####Complete Window Text Options###
endTitle=$(getPref "completeTitle" "Complete")
endMessage=$(getPref "completeMessage" "Your device is now ready. Go be awesome!")

echo "Converted prefs to script varibles" >> $jsOnboarderLog
echo "Continuing...." >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

################################################################################
#                                                                              #
#                 Script Starts Here - Do Not Edit Below                       #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
#                         Pre-flight Checks and Options                        #
#                                                                              #
################################################################################

#####Swift Dialog Variables & Controls#####
dialogPath=/usr/local/bin/dialog
cmdLog=/var/tmp/dialog.log

####Installomator Variables & Controls####
installoPath=/usr/local/Installomator/Installomator.sh
installoOptions="NOTIFY=silent BLOCKING_PROCESS_ACTION=ignore INSTALL=force IGNORE_APP_STORE_APPS=yes LOGGING=REQ"

####Check User is Logged In by checking for Finder & Dock process####
until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
	echo "Finder & Dock are NOT running; pausing for 1 second" >> $jsOnboarderLog
	sleep 3
done

echo "" >> $jsOnboarderLog

####Keep the Mac Awake####
echo "Caffeinating Mac...." >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
/usr/bin/caffeinate -d -i -m -u &
caffeinatepid=$!

###Install Dialog, if required###
	
echo "Checking swiftDialog status...." >> $jsOnboarderLog
if [[ -f $dialogPath ]]; then
	echo "swiftDialog already installed....progressing" >> $jsOnboarderLog
else
	echo "swiftDialog required....starting download" >> $jsOnboarderLog
	$installoPath dialog $installoOptions
	echo "-----------" >> $jsOnboarderLog
	echo "swiftDialog installed" >> $jsOnboarderLog
	echo "----------" >> $jsOnboarderLog
	sleep 3
fi

#####Installomator Installs####
# Get the number of steps required for the progress bar
progressSteps1=${#apps[@]}

####App Store Installs####
# Get the number of steps required for the progress bar
progressSteps2=${#storeInstalls[@]}

####Total Steps Required####
totalSteps=$(($progressSteps1 + $progressSteps2))

echo "" >> $jsOnboarderLog
echo "There will be a total of $totalSteps steps to complete this macOS onboarding experience" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog


################################################################################
#                                                                              #
#                   Start swiftDialog & Installomator Process                  #
#                                                                              #
################################################################################

echo "Pre-flight stage complete. Starting swiftDialog window....." >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

####swiftDialog Start Window Functions####
main_window_local(){
	$dialogPath --title "$dialogTitle" --message "$dialogMessage" --alignment "center" --progress "$totalSteps" --button1text "Please Wait" --button1disabled --width "60%" --height "60%" --position "centre" --icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns" --listitem Onboarding\ Starting.... 
}

main_window(){
	$dialogPath --title "$dialogTitle" --message "$dialogMessage" --alignment "center" --progress "$totalSteps" --button1text "Please Wait" --button1disabled --width "60%" --height "60%" --position "centre" --icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns" --blurscreen --listitem Onboarding\ Starting.... 
}

####Start swiftDialog Window depending on local or script####
if [[ $runOption == "true" ]]; then
	main_window_local &
else
	main_window  &
fi

####Add titles to be installed with Installomator to list and set status to waiting####
sleep 2
for title in "${apps[@]}"; do
	echo "listitem: add, title: "$(echo "$title" | cut -d ':' -f3 | cut -d '"' -f1)", icon: "$(echo "$title" | cut -d ':' -f2 | cut -d '"' -f1)", statustext: waiting, status: wait " >> $cmdLog
done 
echo "listitem: delete, title: Onboarding Starting...." >> $cmdLog

# Rest before start install and set progress bar to starting point
progressCount=0
sleep 2
echo "progress: $progressCount" >> $cmdLog


####Install Apps using Intstallomator####
for app in "${apps[@]}"; do
	sleep 0.5
	echo "listitem: title: "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)", status: pending, statustext: Installing" >> $cmdLog
	echo "progresstext: Install of "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)" in Progress" >> $cmdLog
	echo "Install of "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)">>>>in Progress>>>>" >> $jsOnboarderLog
	if [[ $runOption == "true" ]]; then
		runInstallo="$(sudo $installoPath "$(echo "$app" | cut -d ':' -f4 | cut -d '"' -f1)" $installoOptions)"
	else
		runInstallo="$($installoPath "$(echo "$app" | cut -d ':' -f4 | cut -d '"' -f1)" $installoOptions)"
	fi 
	exitStatus="$( echo "${runInstallo}" | grep --binary-files=text -i "exit" | tail -1 | sed -E 's/.*exit code ([0-9]).*/\1/g' || true )" 
	if [[ ${exitStatus} -eq 0 ]] ; then
		echo "listitem: title: "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)", status: success, statustext: Installed" >> $cmdLog
		progressCount=$(( progressCount + 1)) 
		echo "progress: $progressCount" >> $cmdLog
		echo "progresstext: Install of "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)" complete" >> $cmdLog
		echo "Install of "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)"++++complete++++" >> $jsOnboarderLog
	else
		echo "listitem: title: "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)", status: error, statustext: Installation Error" >> $cmdLog
		progressCount=$(( progressCount + 1)) 
		echo "progress: $progressCount" >> $cmdLog
		echo "progresstext: Install of "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)" Error installation" >> $cmdLog
		echo "ERROR: Installation of "$(echo "$app" | cut -d ':' -f3 | cut -d '"' -f1)"----failed-----" >> $jsOnboarderLog
	fi	
	#Rest before next item
	sleep 1
done
	
echo "" >> $jsOnboarderLog
echo "Installation Phase Complete....Continuing...." >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

################################################################################
#                                                                              #
#                    Start Monitoring App Store Installs                       #
#                                                                              #
################################################################################

echo "Starting App Store Watch Path Phase" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

####Start Mac App Store Checks####
echo "progresstext: Checking Mac App Store Installations..." >>$cmdLog
echo "icon: /System/Applications/App Store.app/Contents/Resources/AppIcon.icns" >>$cmdLog


for masApp in "${storeInstalls[@]}"; do
	sleep 0.5
	echo "listitem: add, title: "$(echo "$masApp" | cut -d ':' -f4 | cut -d '"' -f1)", statustext: checking, status: wait, icon: "$(echo "$masApp" | cut -d ':' -f2 | cut -d '"' -f1)"" >> $cmdLog
done 
sleep 1

####Check for Apps already installed while Installomator was hard at work and set status####
	
echo "Checking for Apps already installed via Mac App Store...." >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

for masApp in "${storeInstalls[@]}"; do
	sleep 0.5
	if [ -e "$(echo "$masApp" | cut -d ':' -f3 | cut -d '"' -f1 | cut -c 1)" ]; then
		echo "listitem: title: "$(echo "$masApp" | cut -d ':' -f4 | cut -d '"' -f1)", status: success, statustext:  Installed " >> $cmdLog
		echo ""$(echo "$masApp" | cut -d ':' -f4 | cut -d '"' -f1)" ++++Installed++++" >> $jsOnboarderLog
		progressCount=$(( progressCount + 1)) 
		echo "progress: $progressCount" >> $cmdLog
		sleep 1
	fi
done

####Sets status for apps not yet installed & adds them to a new Var####
waitInstalls=()
for masApp in "${storeInstalls[@]}"; do
	if [ ! -e "$(echo "$masApp" | cut -d ':' -f3 | cut -d '"' -f1 | cut -c 1)" ]; then
		echo "listitem: title: "$(echo "$masApp" | cut -d ':' -f4 | cut -d '"' -f1)", status: wait, statustext:  Waiting for Installation" >> $cmdLog
		echo ""$(echo "$masApp" | cut -d ':' -f4 | cut -d '"' -f1)", status: wait, statustext:  Waiting for Installation" >> $jsOnboarderLog
		waitInstalls+=("$masApp")
	fi 
done
# echo ${waitInstalls[@]} >> $jsOnboarderLog


####Runs through the "Waiting to Install" Apps and updates install status once installs - until all is complete####
while [ $progressCount != $totalSteps ]; do
	for waitApp in "${waitInstalls[@]}"; do
		sleep 0.5
		if [ -e "$(echo "$waitApp" | cut -d ':' -f3 | cut -d '"' -f1 | cut -c 1)" ]; then
			echo "listitem: title: "$(echo "$waitApp" | cut -d ':' -f4 | cut -d '"' -f1)", status: success, statustext:  Installed " >> $cmdLog
			echo ""$(echo "$waitApp" | cut -d ':' -f4 | cut -d '"' -f1)" ++++Installed++++" >> $jsOnboarderLog
			progressCount=$(( progressCount + 1)) 
			echo "progress: $progressCount" >> $cmdLog
			####Remove installed app from the list####
			delete="$waitApp"
			tempList=()
			for listApps in "${waitInstalls[@]}"; do
				[[ $listApps != $delete ]] && tempList+=("$listApps")
			done
			waitInstalls=("${tempList[@]}")
			unset tempList 
			echo "waitInstalls now contains ${waitInstalls[@]}" >> $jsOnboarderLog
		else [ ! -e "$(echo "$waitApp" | cut -d ':' -f3 | cut -d '"' -f1 | cut -c 1)" ];
			echo ""$(echo "$waitApp" | cut -d ':' -f3 | cut -d '"' -f1 | cut -c 1)" still waiting..." >> $jsOnboarderLog
		fi
	done
	####Changes progress text once all apps are installed and waiting for the final while loop logic####
	echo $progressCount
	if [ $progressCount = $totalSteps ]; then
		echo "progresstext: Finishing Up..." >> $cmdLog
		echo "icon: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarFavoritesIcon.icns" >>$cmdLog
	fi
	sleep 10
done
	
echo "" >> $jsOnboarderLog
echo "Watch Phase Complete....Continuing...." >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

killall Dock
echo "Killing Dock...." >> $jsOnboarderLog
sleep 1

echo "Quiting swiftDialog...." >> $jsOnboarderLog
echo "quit:" >> $cmdLog
sleep 0.1

################################################################################
#                                                                              #
#                                  Finish Up                                   #
#                                                                              #
################################################################################

echo "Displaying Complete message...." >> $jsOnboarderLog
####All Done Window####
$dialogPath --mini --title "$endTitle" --message "$endMessage" --alignment "center" --icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarFavoritesIcon.icns" --button1text "OK" --position "center"


echo "" >> $jsOnboarderLog
echo "Script Complete!" >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog

echo "Killing Caffeinate...." >> $jsOnboarderLog
####Kill Caffeinate####
kill $caffeinatepid