#!/bin/bash
set -euo pipefail

OIFS="$IFS"
IFS=$'\n'
if [ $# -lt 1 ]; then
  echo 'Usage: ./diffpackager.sh <your commit hash to diff from> <your commit has to diff to>(optional, if not specified, defaults to "HEAD")'
  exit 1
fi
# Salesforce deletes aura component files that were not included in the deployment. So, you have to ensure that you deploy all the files even if only 1 file in a component is changed. Eg: Even if you change just the .cmp file, you still have to deploy the controller, helper, css files, etc.
# script assumes you have a 'local' directory in the project root with an sfdx-project.json file in it. If not, create one
# if you get an 'invalid character' error, run 'dos2unix' command on the file
# delete the 'local/force-app' and 'local/deleted/myfiles.tar' before every new run
toHash=${2:-HEAD}

tmpWorkTree="/tmp/sfdxdelta"
targetdir="local/destructiveChanges"

# Create directory named 'local' if it doesn't exist
if [ ! -d "$targetdir" ]; then
  mkdir -p $targetdir
fi

deletedFiles=$(git diff --diff-filter=D --name-only $1 $toHash)

rm -rf "$tmpWorkTree"
git worktree add "$tmpWorkTree" $1 -f #checkout the starting branch to a temp directory so we can build the folder containing just the deleted files
currwd=$PWD
cd "$tmpWorkTree"

for var in $deletedFiles; do                                     # loop over all new and modified files in git diff
  if [[ "$var" = *"/aura/"* ]] || [[ "$var" = *"/lwc/"* ]]; then # for aura and lwc, grab the whole directory and not just the changed file
    tar -rf "$currwd/$targetdir/myfiles.tar" $(dirname "$var")   # add files to a 'tar' archive. we will expand it to recreate the directory structure after we are done
  else
    tar -rf "$currwd/$targetdir/myfiles.tar" "$var"
    if [ -f "$var-meta.xml" ]; then # if there is a meta.xml file, grab that as well
      tar -rf "$currwd/$targetdir/myfiles.tar" "$var-meta.xml"
    elif [[ "$var" = *"-meta.xml" ]]; then # if meta.xml was changed, add the actual file to the package as well
      if [[ -f "${var%%-meta.xml}" ]]; then
        tar -rf "$currwd/$targetdir/myfiles.tar" "${var%%-meta.xml}"
      fi
    fi
  fi
done
cd -
cd "$targetdir"
tar -xf myfiles.tar # expand tar file to recreate the directory structure, relative to the project root
sfdx force:source:convert -r ./force-app/ -d ./src
mv src/package.xml ./destructiveChanges.xml
#sfdx force:mdapi:deploy -c -d src -u myorg -w 20
git worktree remove "$tmpWorkTree"
rm -r myfiles.tar ./src ./force-app
cd -
