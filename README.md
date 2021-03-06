# Simple Bash Shell Script that creates a packageable artifact from your Git diff

### Creates a packageable set of sfdx source files that were added or changed since a previous commit of your choosing. Deletions are not accounted for

## Requirements

Windows or linux machine with the following installations
- Bash Shell
- sfdx cli
- git
- tar

## Instructions for running the script

1) Copy the script to your source-tracked sfdx project folder
2) Create a folder named 'local' in your project root. Add it to the .gitignore file. If the directory exists, empty it before every run. Make sure there is an 'sfdx-project.json' file in the 'local' directory if you plan on running 'convert' or 'deploy' commands afterwards.
2) Run script in a bash shell.
3) Go to the 'local' folder and review the files. 
4) Run *force:source:convert* to convert the files to mdapi format
5) Run *force:mdapi:deploy* to deploy the files to your org


## Notes

- ## Please review the generated files thoroughly before deploying. This script is not fool-proof by any means. It has not been tested with all possible metadata components
- Script does not generate deployable artifacts for deletes
- If you get an 'invalid character' error, run 'dos2unix' command on the file.
