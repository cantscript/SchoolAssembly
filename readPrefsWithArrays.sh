#!/bin/bash

MANAGED_PREFERENCE_DOMAIN="com.jsmacos.onboarder"

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

######################################
#  Get details of Apps to Install    #
# from plist / profile and turn into #
#             an array               #
######################################

### Logging Option ###
### 0=Standard 1= Verbose ###
installAppLogging=1

### Dump plist key into a variable ###
appList=$(getPref "AppInstalls")

### Change IFS for workflow ###
oldIFS=
IFS=,

### Logic to define how many apps are to be installed ###
echo "-> Starting..."
echo "Converting Prefs into script Vars"
installArray=($appList)
installItemsNo=${#installArray[@]}
let requiredApps=$installItemsNo/3
echo "There are $installItemsNo items, resulting in $requiredApps Apps to be installed"
echo "-----------"

### Pre-flight varibles ###
apps=()
appCounter=1
indexPoint=0

### Create App Install array for Switdialog ###
while [ $appCounter -le $requiredApps ]; do
	apps+=(${installArray[@]:$indexPoint:3})
	echo "R:$requiredApps | I: $indexPoint | Added App: $appCounter "
	indexPoint=$(($indexPoint+3))
	((appCounter++))
done
echo "The resulting array contains ${#apps[@]} Apps to be installed"


### Success / Error Message ###
echo "-----------"
if [ $requiredApps = ${#apps[@]} ]; then
	echo "SUCCESS: $requiredApps apps where read from Prefs & ${#apps[@]} Apps have been added to Onboarder script"
else
	echo "ERROR: $requiredApps apps where read from Prefs but ${#apps[@]} Apps have been added to Onboarder script"
fi

if [ $installAppLogging != 0 ]; then
	for items in "${apps[@]}"; do
		echo "----------"
		echo "Icon Location: "$( echo "$items" | cut -d ':' -f2 | cut -d '"' -f1 | tr -d '\')""
		echo "Display Name: "$(echo "$items" | cut -d ':' -f3 | cut -d '"' -f1)""
		echo "Installomator Label: "$(echo "$items" | cut -d ':' -f4 | cut -d '"' -f1 | tr -d '\')""
		
	done
fi

### Return IFS to original state ###
IFS=$oldIFS

### End Process ###
echo "----------"
echo "<- Ending..."


