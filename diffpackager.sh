#!/bin/bash
OIFS="$IFS"
IFS=$'\n'
# Salesforce deletes aura component files that were not included in the deployment. So, you have to ensure that you deploy all the files even if only 1 file in a component is changed. Eg: Even if you change just the .cmp file, you still have to deploy the controller, helper, css files, etc.
# Replace f7815723e99 with your commit id
for var in `git diff --diff-filter=ACMRT --name-only f7815723e99 HEAD`;do if [[ "$var" = *"/aura/"* ]];then tar -rf local/myfiles.tar `dirname "$var"`;else tar -rf local/myfiles.tar "$var";if [ -f "$var-meta.xml" ];then  tar -rf local/myfiles.tar "$var-meta.xml";fi;fi;done
cd local
tar -xvf myfiles.tar
#Uncomment these lines if you wish to package the source and deploy to an org 
#cd local
#sfdx force:source:convert -r .\force-app\ -d src -p mypackagename
#sfdx force:mdapi:deploy -c -d src -u myorg -w 20
