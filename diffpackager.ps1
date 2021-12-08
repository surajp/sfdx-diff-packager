# Delete the '$ToFolder/force-app' folder before every new run, ideally.

# if the from commit hash was not specified, exit immediately
if ($args.count -lt 1) {
	Write-Host 'Usage: ./diffpackager.sh <your commit hash to diff from> <your commit has to diff to>(optional, if not specified, defaults to "HEAD")'
	exit 1
}

$ToFolder = "local" # replace this with the absolute or relative path to your preferred destination directory

# Salesforce deletes aura component files that were not included in the deployment.
# So, you have to ensure that you deploy all the files even if only 1 file in a component is changed. Eg: Even if you change just the .cmp file, you still have to deploy the controller, helper, css files, etc.
$ToHash = $args[1]
if ($null -eq $ToHash) {
	$ToHash = 'HEAD'
}


# Create destination directory if it doesn't exist
if (!(Test-Path -Path $ToFolder)) {
	New-Item "$ToFolder" -ItemType Directory
}

$ChangedFiles = $(git diff --diff-filter=ACMRT --name-only $args[0] $ToHash)
foreach ($var in $ChangedFiles) {
 # loop over all new and modified files in git diff
	if (Test-Path -Path "$var" -PathType Container) { 
	  # If this is a directory, copy it over as is, recursively. Most likely this won't have an accompanying -meta.xml file
		Copy-Item "$var" -Destination "$ToFolder" -Recurse -Force
	}
	# for aura and lwc, grab the whole directory and not just the changed file
	elseif ("$var" -like "*/aura/*" || "$var" -like "*/lwc/*") {
		$pathParts = ($var -split '\\')
		$parentDir = (($pathParts[0..$pathParts.count - 2]) -join '\')
		Copy-Item "$parentDir" -Destination "$ToFolder" -Recurse -Force
	}
	else {
		New-Item -ItemType File "$ToFolder/$var" -Force
		Copy-Item "$var" -Destination "$ToFolder/$var" -Force
		if (Test-Path -Path "$var-meta.xml") {
			# if there is a meta.xml file, grab that as well
			Copy-Item "$var-meta.xml" -Destination "$ToFolder/$var-meta.xml" -Force
		}
		# if it was the meta.xml file that was changed, grab that as well as its accompanying source file, if one exists
		elseif ("$var" -like "*-meta.xml") {
			$SourceFile = "$var" -replace "-meta.xml", ""
			if (Test-Path -Path "$actualFile") {
				Copy-Item "$SourceFile" -Destination "$ToFolder/$SourceFile" -Force
			}
		}
	}
}
#Uncomment these lines if you wish to package the source and deploy to an org 
#cd $ToFolder
#sfdx force:source:convert -r .\force-app\ -d src -p mypackagename
#sfdx force:mdapi:deploy -c -d src -u myorg -w 20 ...
# OR
# sfdx force:source:deploy -p force-app...
