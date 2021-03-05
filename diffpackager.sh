#!/bin/bash
set -euo pipefail

OIFS="$IFS"
IFS=$'\n'
if [ $# -lt 1 ]
then
 echo 'Usage: ./diffpackager.sh <your commit hash to diff from> <your commit has to diff to>(optional, if not specified, defaults to "HEAD")'
 exit 1;
fi
# Salesforce deletes aura component files that were not included in the deployment. So, you have to ensure that you deploy all the files even if only 1 file in a component is changed. Eg: Even if you change just the .cmp file, you still have to deploy the controller, helper, css files, etc.
# script assumes you have a 'local' directory in the project root with an sfdx-project.json file in it. If not, create one
# if you get an 'invalid character' error, run 'dos2unix' command on the file
# delete the 'local/force-app' and 'local/myfiles.tar' before every new run
toHash=${2:-HEAD}

# Create directory named 'local' if it doesn't exist
if [ ! -d "local" ]; then
 mkdir local 
fi

for var in `git diff --diff-filter=ACMRT --name-only $1 $toHash` # loop over all new and modified files in git diff
do
	if [[ "$var" = *"/aura/"* ]] || [[ "$var" = *"/lwc/"* ]] # for aura and lwc, grab the whole directory and not just the changed file
	then
		tar -rf local/myfiles.tar `dirname "$var"` # add files to a 'tar' archive. we will expand it to recreate the directory structure after we are done
	else tar -rf local/myfiles.tar "$var"
		if [ -f "$var-meta.xml" ] # if there is a meta.xml file, grab that as well
		then
			tar -rf local/myfiles.tar "$var-meta.xml"
		elif [[ "$var" = *"-meta.xml" ]]; then # if meta.xml was changed, add the actual file to the package as well
		  if [[ -f "${var%%-meta.xml}" ]]; then
			  tar -rf local/myfiles.tar "${var%%-meta.xml}"
		  fi
		fi
	fi
done
cd local
tar -xf myfiles.tar # expand tar file to recreate the directory structure, relative to the project root
#Uncomment these lines if you wish to package the source and deploy to an org 
#sfdx force:source:convert -r .\force-app\ -d src -p mypackagename
#sfdx force:mdapi:deploy -c -d src -u myorg -w 20
cd -
