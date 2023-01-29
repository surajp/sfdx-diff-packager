#!/bin/bash
set -euo pipefail

OIFS="$IFS"
IFS=$'\n'
if [ $# -lt 1 ]
then
 echo 'Usage: ./diffpackager.sh <your commit hash to diff from> <your commit has to diff to>(optional, if not specified, defaults to "HEAD")'
 exit 1;
fi


# Given a component figure out its base path considering that there could be multiple sub-folders within the base component
# For eg: force-app/main/default/staticresources/test/folder1/folder2/file.js would give force-app/main/default/staticresources/test
getBaseFolder () {
  local defaultFolder="default" #we assume all metadata is stored with <app>/main/default
  local fullPath="$1"
  local defaultFolderPath=${fullPath/$defaultFolder*/$defaultFolder} # the full relative path of the `default` folder
  local componentBaseFolder=$(echo ${fullPath#*$defaultFolder} | cut -d / -f 1-3)
  echo $defaultFolderPath$componentBaseFolder
}

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
		baseFolder=`getBaseFolder "$var"` #the component's main folder
		tar -rf local/myfiles.tar $baseFolder # add files to a 'tar' archive. we will expand it to recreate the directory structure after we are done
	elif [[ "$var" = *"/staticresources/"* ]] #static resource meta files are named differently. zip files will need to be deployed with all files and subfolders included
	then
	  if [[ "$(dirname ""$var"")" != *"staticresources" ]] # if this is a folder, we grab all files and sub-folders within
	  then
		  baseFolder=`getBaseFolder "$var"` #the component's main folder
		  tar -rf local/myfiles.tar $baseFolder # add files to a 'tar' archive. we will expand it to recreate the directory structure after we are done
		  if [ -f "$baseFolder"*"-meta.xml" ] #for static resources, the meta.xml is at the same level as the folder, not inside the folder like aura and lwc
	    then
        tar -rf local/myfiles.tar "$baseFolder.resource-meta.xml" # the meta xml is named foldername.resource-meta.xml
	    fi
	  else
	    tar -rf local/myfiles.tar "$var" # if its not a folder, only grab the changed file
		  if [ -f "${var%.*}.resource-meta.xml" ] # unlike other components, static resource meta.xml files are named <filename without extension>.resource-meta.xml
		  then
			  tar -rf local/myfiles.tar "${var%.*}.resource-meta.xml"
      fi
    fi
	else
	  tar -rf local/myfiles.tar "$var"
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

