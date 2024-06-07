#!/bin/bash

jsOnboarderLog=/Users/Shared/jsmacOSOnboarder.log

if [ -f $jsOnboarderLog ]; then
	rm $jsOnboarderLog
fi

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

for testIcon in "${apps[@]}"; do
	echo $testIcon
done

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
