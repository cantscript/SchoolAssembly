#!/bin/bash


################################################################################
#                                                                              #
#                            School Assembly: V2.1.0                           #
#                                                                              #
#  This script has been heavily inspired by "Progress 1st swiftDialog.sh" &    #
#  "Installomator 1st Auto-install DEPNotify.sh" by                            #
#  Søren Theilgaard                                                            #
#  https://github.com/Theile                                                   #
#                                                                              #
#  Script by Anthony Darlow - April 2024.                                      #
#  Version Edit - June 2024                                                    #
#  By using this script you do so understanding the script creator is not      #
#  responsible for any undesired outcomes of using this script and comes       #
#  without any support                                                         #
################################################################################

#####Swift Dialog Variables & Controls#####
dialogPath=/usr/local/bin/dialog
cmdLog=/var/tmp/dialog.log

####Installomator Variables & Controls####
installoPath=/usr/local/Installomator/Installomator.sh
installoOptions="NOTIFY=silent BLOCKING_PROCESS_ACTION=ignore INSTALL=force IGNORE_APP_STORE_APPS=yes LOGGING=REQ"

####Onboarder Logs####
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

doneFlag=/Users/Shared/.SchoolAssembled

if [ -f $doneFlag ]; then 
	echo "School already Assembled! Done flag present" >> $jsOnboarderLog
	exit 
fi

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

####Check User is Logged In by checking for Finder & Dock process####
until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
	echo "Finder & Dock are NOT running; pausing for 1 second" >> $jsOnboarderLog
	sleep 3
done

################################################################################
#                                                                              #
#                    Read Profile Functions & Profile Check                    #
#                                                                              #
################################################################################



MANAGED_PREFERENCE_DOMAIN="com.cantscript.schoolassembly"

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

getPrefIsManaged() { # $1: key, $2: domain
	local key=${1:?"key required"}
	local domain=${2:-"$MANAGED_PREFERENCE_DOMAIN"}
	
	osascript -l JavaScript -e "$.NSUserDefaults.alloc.initWithSuiteName('$domain').objectIsForcedForKey('$key')"
}

echo "Checking configuration is present" >> $jsOnboarderLog

###Check if pref is managed###
configPresent=$(getPrefIsManaged "AppInstalls")
if [[ $configPresent = false ]]; then
	$dialogPath --mini --title "Error" --message "No Configuration Profile Installed. \nPlease install Configuration before proceeding. \n\n Contact IT for help" --alignment "center" --icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns" --button1text "Quit" --position "center"
	echo "Configuration is not present. Please make sure you have installed configuration profile or populated the pref domain com.jsmacos.onboarder" >> $jsOnboarderLog
	echo "Qutting...." >> $jsOnboarderLog
	exit 
else
	echo "Configuration found, continuing...." >> $jsOnboarderLog
	echo "" >> $jsOnboarderLog
	echo "################################" >> $jsOnboarderLog
	echo "################################" >> $jsOnboarderLog
	echo "" >> $jsOnboarderLog
fi


################################################################################
#                                                                              #
#  Get details of Apps to install via installomator from profile into array    #
#                                                                              #
################################################################################

### Logging Option ###
### false= Standard true= Verbose ###
installAppLogging=$(getPref "appLogging" "false")


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
		echo "Icon Location: "$( echo "$items" | cut -d '"' -f3 | cut -c2-)"" >> $jsOnboarderLog
		echo "Display Name: "$(echo "$items" | cut -d '"' -f5 | cut -c2-)"" >> $jsOnboarderLog
		echo "Installomator Label: "$(echo "$items" | cut -d '"' -f7 | tr -d ':')"" >> $jsOnboarderLog
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

################################################################################
#                                                                              #
#          Get details of watch paths for apps from profile into array         #
#                                                                              #
################################################################################

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
		echo "Icon Location: "$( echo "$items" | cut -d '"' -f3 | cut -c2-)"" >> $jsOnboarderLog
		echo "App Location: "$(echo "$items" | cut -d '"' -f5 | cut -c2-)"" >> $jsOnboarderLog
		echo "Display Name: "$(echo "$items" | cut -d '"' -f7 | tr -d ':')"" >> $jsOnboarderLog
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

################################################################################
#                                                                              #
#                        Other managed preferance keys                         #
#                                                                              #
################################################################################

runOption=$(getPref "runLocal" "false") #true = local, false = via script (run as root)


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
#                         Pre-flight Checks and Options                        #
#                                                                              #
################################################################################


echo "" >> $jsOnboarderLog

####Keep the Mac Awake####
echo "Caffeinating Mac...." >> $jsOnboarderLog
echo "" >> $jsOnboarderLog
/usr/bin/caffeinate -d -i -m -u &
caffeinatepid=$!


################################################################################
#                                                                              #
#                   Start swiftDialog & Installomator Process                  #
#                                                                              #
################################################################################
	
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

if [ $progressSteps1 != 0 ]; then
	for title in "${apps[@]}"; do
		echo "listitem: add, title: "$(echo "$title" | cut -d '"' -f5 | cut -c2-)", icon: "$(echo "$title" | cut -d '"' -f3 | cut -c2-)", statustext: waiting, status: wait " >> $cmdLog
	done 
	echo "listitem: delete, title: Onboarding Starting...." >> $cmdLog
else
	echo "listitem: delete, title: Onboarding Starting...." >> $cmdLog
	echo "listitem: add, title: No Apps to Install, icon: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarInfo.icns, statustext: Complete, status: success" >> $cmdLog
	echo "progresstext: Continuing" >> $cmdLog
	sleep 2
fi


# Rest before start install and set progress bar to starting point
progressCount=0
sleep 2
echo "progress: $progressCount" >> $cmdLog


####Install Apps using Intstallomator####
if [ $progressSteps1 != 0 ]; then
	for app in "${apps[@]}"; do
		sleep 0.5
		echo "listitem: title: "$(echo "$app" | cut -d '"' -f5 | cut -c2-)", status: pending, statustext: Installing" >> $cmdLog
		echo "progresstext: Install of "$(echo "$app" | cut -d '"' -f5 | cut -c2-)" in Progress" >> $cmdLog
		echo "Install of "$(echo "$app" | cut -d '"' -f5 | cut -c2-)">>>>in Progress>>>>" >> $jsOnboarderLog
	if [[ $runOption == "true" ]]; then
		runInstallo="$(sudo $installoPath "$(echo "$app" | cut -d '"' -f7 | tr -d ':')" $installoOptions)"
		else
			runInstallo="$($installoPath "$(echo "$app" | cut -d '"' -f7 | tr -d ':')" $installoOptions)"
		fi 
		exitStatus="$( echo "${runInstallo}" | grep --binary-files=text -i "exit" | tail -1 | sed -E 's/.*exit code ([0-9]).*/\1/g' || true )" 
		if [[ ${exitStatus} -eq 0 ]] ; then
			echo "listitem: title: "$(echo "$app" | cut -d '"' -f5 | cut -c2-)", status: success, statustext: Installed" >> $cmdLog
				progressCount=$(( progressCount + 1))
			echo "progress: $progressCount" >> $cmdLog
			echo "progresstext: Install of "$(echo "$app" | cut -d '"' -f5 | cut -c2-)" complete" >> $cmdLog
			echo "Install of "$(echo "$app" | cut -d '"' -f5 | cut -c2-)"++++complete++++" >> $jsOnboarderLog
		else
			echo "listitem: title: "$(echo "$app" | cut -d '"' -f5 | cut -c2-)", status: error, statustext: Installation Error" >> $cmdLog
				progressCount=$(( progressCount + 1)) 
			echo "progress: $progressCount" >> $cmdLog
			echo "progresstext: Install of "$(echo "$app" | cut -d '"' -f5 | cut -c2-)" Error installation" >> $cmdLog
			echo "ERROR: Installation of "$(echo "$app" | cut -d '"' -f5 | cut -c2-)"----failed-----" >> $jsOnboarderLog
		fi	
			#Rest before next item
			sleep 1
	done
else
		echo "No Installomator Apps to Install" >> $jsOnboarderLog
fi

	
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
	echo "listitem: add, title: "$(echo "$masApp" | cut -d '"' -f7 | tr -d ':')", statustext: checking, status: wait, icon: "$(echo "$masApp" | cut -d '"' -f3 | cut -c2-)"" >> $cmdLog
done 
sleep 1

####Check for Apps already installed while Installomator was hard at work and set status####
	
echo "Checking for Apps already installed via Mac App Store...." >> $jsOnboarderLog
echo "" >> $jsOnboarderLog

for masApp in "${storeInstalls[@]}"; do
	sleep 0.5
	targetApp=$(echo "$masApp" | cut -d '"' -f5 | cut -c2-)
	removeWS=$(echo "$targetApp" | awk '{ print substr( $0, 1, length($0)-1 ) }')
	if [ -e "$removeWS" ]; then
		echo "listitem: title: "$(echo "$masApp" | cut -d '"' -f7 | tr -d ':')", status: success, statustext:  Installed " >> $cmdLog
		echo ""$(echo "$masApp" | cut -d '"' -f7 | tr -d ':')" ++++Installed++++" >> $jsOnboarderLog
		progressCount=$(( progressCount + 1)) 
		echo "progress: $progressCount" >> $cmdLog
		sleep 1
	fi
done

####Sets status for apps not yet installed & adds them to a new Var####
waitInstalls=()
for masApp in "${storeInstalls[@]}"; do
	targetApp=$(echo "$masApp" | cut -d '"' -f5 | cut -c2-)
	removeWS=$(echo "$targetApp" | awk '{ print substr( $0, 1, length($0)-1 ) }')
	if [ ! -e "$removeWS" ]; then
		echo "listitem: title: "$(echo "$masApp" | cut -d '"' -f7 | tr -d ':')", status: wait, statustext:  Waiting for Installation" >> $cmdLog
		echo ""$(echo "$masApp" | cut -d '"' -f7 | tr -d ':')", status: wait, statustext:  Waiting for Installation" >> $jsOnboarderLog
		waitInstalls+=("$masApp")
	fi 
done
# echo ${waitInstalls[@]} >> $jsOnboarderLog


####Runs through the "Waiting to Install" Apps and updates install status once installs - until all is complete####
while [ $progressCount != $totalSteps ]; do
	for waitApp in "${waitInstalls[@]}"; do
		sleep 0.5
		targetApp=$(echo "$waitApp" | cut -d '"' -f5 | cut -c2-)
		removeWS=$(echo "$targetApp" | awk '{ print substr( $0, 1, length($0)-1 ) }')
		if [ -e "$removeWS" ]; then
			echo "listitem: title: "$(echo "$waitApp" | cut -d '"' -f7 | tr -d ':')", status: success, statustext:  Installed " >> $cmdLog
			echo ""$(echo "$waitApp" | cut -d '"' -f7 | tr -d ':')" ++++Installed++++" >> $jsOnboarderLog
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
		else 
			[ ! -e "$removeWS" ];
			echo ""$(echo "$waitApp" | cut -d '"' -f7 | tr -d ':')" still waiting..." >> $jsOnboarderLog
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
touch $doneFlag
echo "" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog
echo "################################" >> $jsOnboarderLog

echo "Killing Caffeinate...." >> $jsOnboarderLog
####Kill Caffeinate####
kill $caffeinatepid