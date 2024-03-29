#!/bin/bash

MANAGED_PREFERENCE_DOMAIN="com.ant.darlow4"

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
installApp=()
appCounter=1
indexPoint=0

### Create App Install array for Switdialog ###
while [ $appCounter -le $requiredApps ]; do
	installApp+=(${installArray[@]:$indexPoint:3})
	echo "R:$requiredApps | I: $indexPoint | Added App: $appCounter "
	indexPoint=$(($indexPoint+3))
	((appCounter++))
done
echo "The resulting array contains ${#installApp[@]} Apps to be installed"


### Success / Error Message ###
echo "-----------"
if [ $requiredApps = ${#installApp[@]} ]; then
	echo "SUCCESS: $requiredApps apps where read from Prefs & ${#installApp[@]} Apps have been added to Onboarder script"
else
	echo "ERROR: $requiredApps apps where read from Prefs but ${#installApp[@]} Apps have been added to Onboarder script"
fi

if [ $installAppLogging != 0 ]; then
	for items in "${installApp[@]}"; do
		echo "----------"
		echo "Display Name: "$( echo "$items" | cut -d ':' -f2 | cut -d '"' -f1 | tr -d '\')""
		echo "Icon Location: "$(echo "$items" | cut -d ':' -f3 | cut -d '"' -f1)""
		echo "App Name: "$(echo "$items" | cut -d ':' -f4 | cut -d '"' -f1 | tr -d '\')""
		
	done
fi

### Return IFS to original state ###
IFS=$oldIFS

### End Process ###
echo "----------"
echo "<- Ending..."


