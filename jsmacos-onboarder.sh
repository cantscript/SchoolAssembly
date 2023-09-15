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
#                         Variables - Admin Defined                            #
#                                                                              #
################################################################################

# # # # # # # # # # # # # # # # # # # # # # #
#  Option to run local or through script.   #
#  Local uses Sudo, needs Password and      #
#  disables "full-screen blur".             #
#                                           #
#  If you run the script with option '1'    #
#  locally (ie without the password) All    #
#  Installomator installs will error due to #
#  needing to be run as root.               #
#                                           #
#          0=Local 1=Via Script             #
# # # # # # # # # # # # # # # # # # # # # # #
runOption=1

#####Swift Dialog Variables & Controls#####
dialogPath=/usr/local/bin/dialog
cmdLog=/var/tmp/dialog.log

####Installomator Variables & Controls####
installoPath=/usr/local/Installomator/Installomator.sh
installoOptions="NOTIFY=silent BLOCKING_PROCESS_ACTION=ignore INSTALL=force IGNORE_APP_STORE_APPS=yes LOGGING=REQ"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#                              Automator Labels                                  #
#                             Format needs to be:-                               #
#                            1) Installomator label                              #
#                        2) Display Text (Escape spaces with \)                  #
#                        3) Icon Location (Escape spaces with \)                 #
#                                                                                #
# Example: googlechromepkg,Google\ Chrome,/Users/ladmin/Desktop/Chrome\ Icon.png #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

apps=(googlechromepkg,Google\ Chrome,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Chrome\ Icon.png
	microsoftexcel,Excel,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Excel\ Icon.png
	microsoftword,Word,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Word\ Icon.png
	microsoftoutlook,Outlook,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Outlook\ Icon.png
	microsoftteams,Teams,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Teams\ Icon.png
	microsoftonedrive,One\ Drive,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/OneDrive\ Icon.png
)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#                              Monitor App Store Installs                            #
#                                Format needs to be:-                                #
#                 1) Name of App (Display text can be anything you like)             #
#                       2) Install Location (Escape spaces with \)                   #
#                           3) Icon Location (Escape spaces with \)                  #
#                                                                                    #
# Example: Keynote,/Applications/Keynote.app,/Users/ladmin/Desktop/Keynote\ Icon.png #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

storeInstalls=(Keynote,/Applications/Keynote.app,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Keynote\ Icon.png
	Numbers,/Applications/Numbers.app,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Numbers\ Icon.png
	Pages,/Applications/Pages.app,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Pages\ Icon.png
	Swift\ Playgrounds,/Applications/Playgrounds.app,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Playgrounds\ Icon.png
	Jamf\ Student,/Applications/Jamf\ Student.app,/Library/Application\ Support/macOS\ App\ Onboarder/App\ Icons/Student\ Icon.png
)

####Personalise Window Text with logged-in user or computer name####
windowGreeting=""
currentUser="$(stat -f "%Su" /dev/console | cut -d '.' -f1)" #option 0
compName="$(hostname -f | sed -e 's/^[^.]*\.//')"            #option 1
personalOption=1
if [ $personalOption = 0 ]; then
	windowGreeting=$currentUser
else
	windowGreeting=$compName
fi

####Main Window Text Options###
dialogTitle="Let's build $windowGreeting's Mac"
dialogMessage="\n**Hello you _awesome_ person!** \n\nWe need to install some apps for you, this might take a while. Grab a coffee while you wait."

####Complete Window Text Options###
endTitle="Your Mac is ready to go"
endMessage="Go And Be Awesome! Thanks! IT"

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

####Check User is Logged In by checking for Finder & Dock process####
until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
	echo "Finder & Dock are NOT running; pausing for 1 second"
	sleep 3
done

####Keep the Mac Awake####
/usr/bin/caffeinate -d -i -m -u &
caffeinatepid=$!

###Install Dialog###
$installoPath dialog $installoOptions
sleep 3

#####Installomator Installs####
# Get the number of steps required for the progress bar
progressSteps1=${#apps[@]}

####App Store Installs####
# Get the number of steps required for the progress bar
progressSteps2=${#storeInstalls[@]}

####Total Steps Required####
totalSteps=$(($progressSteps1 + $progressSteps2))
echo $totalSteps 

################################################################################
#                                                                              #
#                   Start swiftDialog & Installomator Process                  #
#                                                                              #
################################################################################

####swiftDialog Start Window Functions####
main_window_local(){
	$dialogPath --title "$dialogTitle" --message "$dialogMessage" --alignment "center" --progress "$totalSteps" --button1text "Please Wait" --button1disabled --width "60%" --height "60%" --position "centre" --icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns" --listitem Onboarding\ Starting.... 
}

main_window(){
	$dialogPath --title "$dialogTitle" --message "$dialogMessage" --alignment "center" --progress "$totalSteps" --button1text "Please Wait" --button1disabled --width "60%" --height "60%" --position "centre" --icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns" --blurscreen --listitem Onboarding\ Starting.... 
}

####Start swiftDialog Window depending on local or script####
if [ $runOption = 0 ]; then
	main_window_local &
else
	main_window  &
fi

####Add titles to be installed with Installomator to list and set status to waiting####
sleep 2
for title in "${apps[@]}"; do
	echo "listitem: add, title: "$(echo "$title" | cut -d ',' -f2)", icon: "$(echo "$title" | cut -d ',' -f3)", statustext: waiting, status: wait " >> $cmdLog
done 
echo "listitem: delete, title: Onboarding Starting...." >> $cmdLog

# Rest before start install and set progress bar to starting point
progressCount=0
sleep 2
echo "progress: $progressCount" >> $cmdLog


####Install Apps using Intstallomator####
for app in "${apps[@]}"; do
	sleep 0.5
	echo "listitem: title: "$(echo "$app" | cut -d ',' -f2)", status: pending, statustext: Installing" >> $cmdLog
	echo "progresstext: Install of "$(echo "$app" | cut -d ',' -f2)" in Progress" >> $cmdLog
	if [ $runOption = 0 ]; then
		runInstallo="$(sudo $installoPath "$(echo "$app" | cut -d ',' -f1)" $installoOptions)"
	else
		runInstallo="$($installoPath "$(echo "$app" | cut -d ',' -f1)" $installoOptions)"
	fi 
	exitStatus="$( echo "${runInstallo}" | grep --binary-files=text -i "exit" | tail -1 | sed -E 's/.*exit code ([0-9]).*/\1/g' || true )"
	if [[ ${exitStatus} -eq 0 ]] ; then
		echo "listitem: title: "$(echo "$app" | cut -d ',' -f2)", status: success, statustext: Installed" >> $cmdLog
		progressCount=$(( progressCount + 1)) 
		echo "progress: $progressCount" >> $cmdLog
		echo "progresstext: Install of "$(echo "$app" | cut -d ',' -f2)" complete" >> $cmdLog
	else
		echo "listitem: title: "$(echo "$app" | cut -d ',' -f2)", status: error, statustext: Installation Error" >> $cmdLog
		progressCount=$(( progressCount + 1)) 
		echo "progress: $progressCount" >> $cmdLog
		echo "progresstext: Install of "$(echo "$app" | cut -d ',' -f2)" Error installation" >> $cmdLog
	fi	
	#Rest before next item
	sleep 1
done

################################################################################
#                                                                              #
#                    Start Monitoring App Store Installs                       #
#                                                                              #
################################################################################

####Start Mac App Store Checks####
echo "progresstext: Checking Mac App Store Installations..." >>$cmdLog
echo "icon: /System/Applications/App Store.app/Contents/Resources/AppIcon.icns" >>$cmdLog


for masApp in "${storeInstalls[@]}"; do
	sleep 0.5
	echo "listitem: add, title: "$(echo "$masApp" | cut -d ',' -f1)", statustext: checking, status: wait, icon: "$(echo "$masApp" | cut -d ',' -f3)"" >> $cmdLog
done 
sleep 1

####Check for Apps already installed while Installomator was hard at work and set status####
for masApp in "${storeInstalls[@]}"; do
	sleep 0.5
	if [ -e "$(echo "$masApp" | cut -d ',' -f2)" ]; then
		echo "listitem: title: "$(echo "$masApp" | cut -d ',' -f1)", status: success, statustext:  Installed " >> $cmdLog
		progressCount=$(( progressCount + 1)) 
		echo "progress: $progressCount" >> $cmdLog
		sleep 1
	fi
done

####Sets status for apps not yet installed & adds them to a new Var####
waitInstalls=()
for masApp in "${storeInstalls[@]}"; do
	if [ ! -e "$(echo "$masApp" | cut -d ',' -f2)" ]; then
		echo "listitem: title: "$(echo "$masApp" | cut -d ',' -f1)", status: wait, statustext:  Waiting for Installation" >> $cmdLog
		waitInstalls+=("$masApp")
	fi 
done
echo ${waitInstalls[@]}


####Runs through the "Waiting to Install" Apps and updates install status once installs - until all is complete####
while [ $progressCount != $totalSteps ]; do
	for waitApp in "${waitInstalls[@]}"; do
		sleep 0.5
		if [ -e "$(echo "$waitApp" | cut -d ',' -f2)" ]; then
			echo "listitem: title: "$(echo "$waitApp" | cut -d ',' -f1)", status: success, statustext:  Installed " >> $cmdLog
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
			echo "waitInstalls now contains ${waitInstalls[@]}"
		else [ ! -e "$(echo "$waitApp" | cut -d ',' -f2)" ];
			echo ""$(echo "$waitApp" | cut -d ',' -f2)" still waiting..."
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

killall Dock

echo "quit:" >> $cmdLog
sleep 0.1

################################################################################
#                                                                              #
#                                  Finish Up                                   #
#                                                                              #
################################################################################

####All Done Window####
$dialogPath --mini --title "$endTitle" --message "$endTitle" --alignment "center" --icon "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarFavoritesIcon.icns" --button1text "OK" --position "center"

####Kill Caffeinate####
kill $caffeinatepid