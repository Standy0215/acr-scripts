# acr-scripts
A shell script for easy management of Azure Container Registry

## Prerequisties:
The user who executes the script should have the contributor role to the given registries.

## How to use:
Store the script in your device and give execution to the script
`chmod +x acr-gather.sh`

Then run the script and follow the guidance to perform the actions.
`./acr-gather.sh`


## Supported functions
1. List images
- List all the images in registry
-  List images in certain repository
2. List image size
- List the size for all the images in the registry
- List the size of the images in certain repository
3. Show ACR basic info
4. Import images between registries
- Import all the images from current registry to remote registry
- Import images in certain repository from current registry to remote registry
- Import all the images from remote registry to current registry
- Import images in certain repository from remote registry to current registry
