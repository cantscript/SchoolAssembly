#!/bin/bash

##################################################################################
#                                                                                #
#                                    LICENCE                                     #
#                                                                                #
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    #
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      #
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   #
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        #
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, #
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE #
#  SOFTWARE.                                                                     #
#                                                                                #
##################################################################################

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

### Passed In Arguments ##

verNo=""
sourceIcons=""
runAfterInstall=0

showHelp(){
	echo ""
	echo "For detailed help visit the School Assembly Wiki - https://github.com/cantscript/SchoolAssembly/wiki"
	echo ""
	echo "-v | --ver"
	echo "Version: Required"
	echo "-----------------"
	echo "There must be a version number supplied when building a SchoolAssembly Package"
	echo "e.g. 1.0.1"
	echo ""
	echo ""
	echo "-i | --icons"
	echo "Source Icons: Optional"
	echo "----------------------"
	echo "Use this option to package any icons that that are required to be on the machine"
	echo "locally when running the SchoolAssembly script. Supply the file path to a folder"
	echo "that contains the required icons. White spaces must be escaped with '\'"
	echo "e.g. /users/myuser/Documents/My\ Icons"
	echo ""
	echo ""
	echo "-r | --run"
	echo "Run School Assembly Script after package installation: Optional"
	echo "---------------------------------------------------------------"
	echo "Use this option if you wish to invoke the School Assembly script after installation"
	echo "of the package. In order for the School Assembly workflow to be successful the device"
	echo "must have the required configuration profile installed. Alternatively invoke the"
	echo "School Assembly via Jamf School"
	echo ""
	echo ""
	echo "-s | --sign"
	echo "Sign Package: Optional"
	echo "-----------------------"
	echo "Use this option if you wish to sign the resulting .pkg with your developer ID. This"
	echo "is not required to deploy with Jamf School, as Jamf School will sign any deployed"
	echo "pkg with a cert enrolled devices trust. Use this option if you intend to deploy the"
	echo "resulting pkg manually."
	echo ""
	echo ""

	exit
}

while [ $# -gt 0 ]; do
	case $1 in
		--ver | -v)  verNo=$2 ; shift  ;;
		--icons | -i) sourceIcons=$2 ; shift  ;;
		--sign | -s ) signId=$2 ; shift ;;
		--run | -r ) runAfterInstall=1  ;;
		--help | -h ) showHelp  ;;
		(*)
	esac
	shift
done

### Argument Logic

if  [[ ! -n $verNo ]] ;then 
	echo "You must provide a version number for your pkg"
	exit 
fi


if [[ ! -n $sourceIcons ]]; then
	includeIcons=0
else
	includeIcons=1
fi

### Package Varibles ###
pkgName="SchoolAssembly"
version="$verNo"
identifier="com.cantscript.${pkgName}"
install_location="/"


### Temp Working Folder ###
tmpDir=/tmp/assemblyPkgBuilder

### Download Locations ###
installomatorScript="$tmpDir/Installomator.sh"
assemblyScript="$tmpDir/SchoolAssembly.sh"

### Installed Locations ###
installomatorLoc=/payload/usr/local/Installomator
assemblyLoc=/payload/usr/local/SchoolAssembly
iconDestination=/payload/Library/Application\ Support/SchoolAssembly

### Current Logged In User ###
#currentUser="$(stat -f "%Su" /dev/console | cut -d '.' -f1)"
currentUser="$(stat -f "%Su" /dev/console)"

### Functions  ###
downloadAssemblyScript(){
	if ! curl -L --silent --fail "https://raw.githubusercontent.com/cantscript/SchoolAssembly/main/SchoolAssembly.sh" >> $assemblyScript; then
		echo "could not download School Assembly Script"
	fi
}

downloadInstallomatorScript(){
	if ! curl -L --silent --fail "https://raw.githubusercontent.com/Installomator/Installomator/main/Installomator.sh" >> $installomatorScript; then
		echo "could not download Installomator Script"
	fi
	
	###Set Debug Mode in Installomator to 0 (Production) 
	sed -i -e 's/DEBUG=1/DEBUG=0/g' $installomatorScript
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

componentPackage(){
	pkgbuild --root "${buildFolder}/payload" \
	--identifier "${identifier}" \
	--version "${version}" \
	--scripts "${buildFolder}/scripts" \
	--install-location "${install_location}" \
	"$tmpDir/${pkgName}-${version}.pkg"
}
			
componentPackageSigned(){
	pkgbuild --root "${buildFolder}/payload" \
	--identifier "${identifier}" \
	--version "${version}" \
	--scripts "${buildFolder}/scripts" \
	--install-location "${install_location}" \
	--sign ${signId} \
	"$tmpDir/${pkgName}-${version}.pkg"
}
			
convertToDistribution(){
	productbuild --identifier "${identifier}" \
	--version "${version}" \
	--package "$tmpDir/${pkgName}-${version}.pkg" \
	"/Users/$currentUser/Desktop/${pkgName}-${version}.pkg"
}
			
convertToDistributionSigned(){
	productbuild --identifier "${identifier}" \
	--version "${version}" \
	--package "$tmpDir/${pkgName}-${version}.pkg" \
	--sign ${signId} \
	"/Users/$currentUser/Desktop/${pkgName}-${version}.pkg"
}
			
copyIcons(){
	mkdir -p $buildFolder"$iconDestination"
	for file in "$sourceIcons"/* ; do
		iconName=$(basename "$file")
		cp "$file" $buildFolder"$iconDestination"/$iconName
	done
}
			
addPostScript(){
	postScript=$buildFolder/scripts/postinstall
	cat <<EOF >$postScript
#!/bin/bash

/usr/local/SchoolAssembly/SchoolAssembly.sh

EOF
	
	chmod +x $postScript
}

### Workflow Starts Here ###

mkdir $tmpDir

downloadAssemblyScript
downloadInstallomatorScript
scriptPermissions
buildPkgFolder 

mv $installomatorScript $buildFolder$installomatorLoc/Installomator.sh
mv $assemblyScript $buildFolder"$assemblyLoc"/SchoolAssembly.sh

if [[ $includeIcons == 1 ]]; then
	copyIcons
fi
			
if [[ $runAfterInstall == 1 ]]; then
	addPostScript 
fi
	
if  [[ ! -n $signId ]] ;then 
	componentPackage 
	convertToDistribution
	echo "Creating unsigned Pkg"
elif [[ -n $signId ]] ;then
	componentPackageSigned 
	convertToDistributionSigned
	echo "Creating signed Pkg"
else
	echo "There was an error"
fi

### Clean Up ###
 rm -R $tmpDir