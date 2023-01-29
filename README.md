# Simple Bash/Powershell script that creates a packageable artifact from your Git diff

### Creates a packageable set of sfdx source files that were added or changed since a previous commit of your choosing. Deletions are not accounted for

## Usage

`./diffpackager.sh <from commit hash> <to commit hash>(optional)`

or

`. diffpackager.ps1 <from commit hash> <to commit hash>(optional)`

## Requirements

### Linux

- Bash Shell
- sfdx cli
- git
- tar

### Windows

- Powershell
- sfdx cli
- git

## Instructions for running the script in linux

1. Copy `diffpackager.sh` to your project root folder.
2. Create a folder named 'local' in your project root. Add it to the .gitignore file. If the directory exists, empty it before every run. Make sure there is an 'sfdx-project.json' file in the 'local' directory if you plan on running 'convert' or 'deploy' commands afterwards.
3. Run script in a bash shell.
4. Go to the 'local' folder and review the files.
5. Run _force:source:convert_ to convert the files to mdapi format.
6. Run _force:mdapi:deploy_ to deploy the files to your org.
7. Alternatively, run _force:source:deploy_ to deploy the files.

## Instructions for running the script in Windows

1. Copy `diffpackager.ps1` to your project root folder.
2. Add the deployment directory (where you want the packageable files to be copied) to the .gitignore file, if its within your project root. If the directory exists, empty it before every run. Make sure there is an 'sfdx-project.json' file in the directory if you plan on running 'convert' or 'deploy' commands afterwards.
3. Run the script in using Powershell.
4. Go to the destination folder and review the files.
5. Run _force:source:convert_ to convert the files to mdapi format.
6. Run _force:mdapi:deploy_ to deploy the files to your org.
7. Alternatively, run _force:source:deploy_ to deploy the files.
8. The default destination folder is named 'local' within the current directory. You can change it at the top of the script if you wish to.

## Notes

- **Please review the generated files thoroughly before deploying. This script is not fool-proof by any means. It has not been tested with all possible metadata components.**
- Script does not generate deployable artifacts for deletes.
- If you get an 'invalid character' error, run 'dos2unix' command on the file. (bash)

## Contributions

- Thanks to [Greg Butt](https://github.com/gbutt) for pointing out the need to handle static resources separately. You can check out his script [here](https://gist.github.com/gbutt/8ced61b167df1c79e37f849cfcbfe889#file-create-diff-package-sh)
