#!/bin/bash

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

### Passed In Arguments ##

verNo=""
sourceIcons=""
runAfterInstall=0

#case $1 in
#	-ver | -v)  verNo=$2 ;;
#	-icons | -i) sourceIcons=$3 ;;
#	-run | -r ) runAfterInstall=1 ;;
#	*)
#		esac
		

while [ $# -gt 0 ]; do
	case $1 in
		-ver | -v)  verNo=$2 ; shift  ;;
		-icons | -i) sourceIcons=$2 ; shift  ;;
		-run | -r ) runAfterInstall=1  ;;
		(*)
	esac
	shift
done

echo $verNo
echo $sourceIcons
echo $runAfterInstall

### Argument Logic

if  [[ ! -n $verNo ]] ;then 
	echo "You must provide a version number for your pkg"
	exit 
fi

includeIcons=0
if [[ ! -n $sourceIcons ]]; then
	echo "No Icons needed"
else
	includeIcons=1
fi


if [[ $runAfterInstall = 1 ]]; then
	echo "A post script will be created"
else
	echo "no script needed"
fi

### Package Varibles ###
pkgName="SchoolAssembly"
version="$verNo"
identifier="com.cantscript.${pkgName}"
install_location="/"


### Temp Working Folder ###
tmpDir=/Users/Shared/assemblyPkgBuilder

### Download Locations ###
installomatorScript="$tmpDir/Installomator.sh"
assemblyScript="$tmpDir/SchoolAssembly.sh"

### Installed Locations ###
installomatorLoc=/payload/usr/local/Installomator
assemblyLoc=/payload/Library/Application\ Support/SchoolAssembly

### Current Logged In User ###
currentUser="$(stat -f "%Su" /dev/console | cut -d '.' -f1)"

### Funcations  ###
downloadAssemblyScript(){
	curl -L --silent --fail "https://raw.githubusercontent.com/cantscript/SchoolAssembly/main/SchoolAssembly.sh" >> $assemblyScript
}

downloadInstallomatorScript(){
	curl -L --silent --fail "https://raw.githubusercontent.com/Installomator/Installomator/main/Installomator.sh" >> $installomatorScript
}

scriptPermissions(){
	for script in $tmpDir/*.sh ; do
		chmod +x $script 
	done
}

buildPkgFolder(){
	buildFolder="$tmpDir/buildFolder"
	mkdir -p $buildFolder$installomatorLoc
	mkdir -p $buildFolder"$assemblyLoc"
	mkdir $buildFolder/scripts
}

packageCreation(){
	pkgbuild --root "${buildFolder}/payload" \
	--identifier "${identifier}" \
	--version "${version}" \
	--scripts "${buildFolder}/scripts" \
	--install-location "${install_location}" \
	"/Users/$currentUser/Desktop/${pkgName}-${version}.pkg"
}


mkdir $tmpDir

downloadAssemblyScript
downloadInstallomatorScript
scriptPermissions
buildPkgFolder 

mv $installomatorScript $buildFolder$installomatorLoc/Installomator.sh
mv $assemblyScript $buildFolder"$assemblyLoc"/SchoolAssembly.sh

# if [[ $sourceIcons == 1 ]]; then
# do the functions 
#fi
			
# if [[ $runAfterInstall == 1 ]]; then
# do the functions 
#fi
		
packageCreation

### Clean Up ###
rm -R $tmpDir