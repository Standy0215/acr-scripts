#! /bin/bash

# Author: Standy Shi

echo "Please input the resource ID of the ACR:"
read -r ACR_ID

#Get the basic info of the ACR
SUB_ID=`echo $ACR_ID | awk  -F "/" '{print $3}'`
RG=`echo $ACR_ID | awk  -F "/" '{print $5}'`
ACRName=`echo $ACR_ID | awk  -F "/" '{print $9}'`
LoginServer=`echo $ACR_ID | awk  -F "/" '{print $9 ".azurecr.io"}'`

#Colorful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Subcription: $SUB_ID\nResource Group: $RG\nACR Name: $ACRName\nLogin Server: $LoginServer\n${NC}"

#Functions for listing images
function image_list() {
    echo -e "${GREEN}Listing repositories...${NC}"
    local repositoryList=`az acr repository list -n $ACRName -otsv`
    echo -e "All the repositories in the ACR $ACRName"
    echo -e "================================\n"
    for repo in $repositoryList;
    do
        echo -e "$repo"
    done
    echo -e "\n================================\n"
    while true
    do

        echo -e "${GREEN}1. Show all the images in the Registry\n2. Show images in certain repository\n3. Exit\n${NC}"
        echo "Please input the number of the action you want to perform"
        local subSelection
        local inputRepo
        read subSelection

        case $subSelection in
        # List all the images in ACR
        1)
            echo -e "${GREEN}Listing images...${NC}"
            echo "All the images in $ACRName"
            echo -e "================================"

            for repo in $repositoryList;
            do
                tagList=`az acr repository show-tags -n $ACRName --repository $repo -otsv`
                echo -e "\n${GREEN}Images in repository $repo${NC}"
                for tag in $tagList;
                do
                    echo "$repo:$tag"
                done
            done
            echo -e "\n================================\n"
            echo -e "Completed!\n"
            ;;
        # List images in givin repository
        2)
            echo -e "Please input the repository name you want to check!"
            read inputRepo
            if printf "%s\n" "${repositoryList[@]}" | grep -q -x "$inputRepo"; then
                tagList=`az acr repository show-tags -n $ACRName --repository $inputRepo -otsv`
                echo -e "\n${GREEN}The images in repository $inputRepo${NC}"
                for tag in $tagList;
                do
                    echo "$inputRepo:$tag"
                done
                echo -e "\nCompleted!\n"
            else
                echo -e "${RED}Target repository doesn't exist!\n${NC}"
            fi
            ;;
        # Return
        3)
            echo -e "Exiting..."
            break
            ;;
        # Error input
        *)
            echo -e "${RED}Invalid input, please input the correct option!\n${NC}"
            ;;
        esac
    done
}

#Function for listing size of images
function image_size() {
    echo -e "${GREEN}Listing repositories...${NC}"
    local repositoryList=`az acr repository list -n $ACRName -otsv`
    echo -e "All the repositories in the ACR $ACRName"
    echo -e "================================\n"
    for repo in $repositoryList;
    do
        echo -e "$repo"
    done
    echo -e "\n================================\n"
    while true
    do
        echo -e "${GREEN}1. Show the size for all the images in the Registry\n2. Show the size for the images in certain repository\n3. Exit\n${NC}"
        echo "Please input the number of the action you want to perform"
        local subSelection
        local inputRepo
        read subSelection

        case $subSelection in
        # Show size of all the images in the registry
        1)
            echo -e "${GREEN}Executing...${NC}"
            echo -e "================================\n"
            for repo in $repositoryList;
            do
                echo -e "Size of the images in repository $repo\n"
                az acr manifest list-metadata -r $ACRName -n $repo --query '[].{Size: imageSize, Tags: tags[0],Created: createdTime, Architecture: architecture, OS: os}' -o tsv 2>/dev/null | awk '{byte=$1 /1024 /1024; print "Size: "byte " MB", "Tag: "$2, "Creation: " $3, "Architecture: " $4, "OS: " $5 }' | grep -v "Tag: None"
                echo -e "\n================================\n"
            done
            echo -e "Completed!\n"
            ;;
        # Show size of the images in givin repository
        2)
            echo -e "Please input the repository name you want to check!"
            read inputRepo
            if printf "%s\n" "${repositoryList[@]}" | grep -q -x "$inputRepo"; then
                echo -e "\n${GREEN}Size of the images in repository $inputRepo${NC}"
                az acr manifest list-metadata -r $ACRName -n $inputRepo --query '[].{Size: imageSize, Tags: tags[0],Created: createdTime, Architecture: architecture, OS: os}' -o tsv 2>/dev/null | awk '{byte=$1 /1024 /1024; print "Size: "byte " MB", "Tag: "$2, "Creation: " $3, "Architecture: " $4, "OS: " $5 }' | grep -v "Tag: None"
                echo -e "\nCompleted!\n"
            else
                echo -e "${RED}Target repository doesn't exist!\n${NC}"
            fi
            ;;
        # Return
        3)
            echo "Exiting..."
            break
            ;;
        # Error input
        *)
            echo -e "${RED}Invalid input, please input the correct option!\n${NC}"
            ;;

        esac

    done
}

#Function to output the basic information of ACR
function list_info() {
    echo -e "${GREEN}Executing...${NC}"
    echo -e "================================\n"
    az acr show -g $RG -n $ACRName --query '{adminUser: adminUserEnabled,anonymousPull: anonymousPullEnabled, location: location, retentionPolicy: policies.retentionPolicy.status, publicAccess: publicNetworkAccess, geoReplications: zoneRedundancy, SKU: sku.tier}' -otable
}

#Function to import images between registries
function import_images() {
    while true
    do
        echo -e "${GREEN}1. Import all the images from current ACR to remote ACR\n2. Import images in certain repository from current ACR to remote ACR\n3. Import all the images from remote ACR to current ACR\n4. Import images in certain repository from remote ACR to current ACR\n7. Exit\n${NC}"
        echo "Please input the number of the action you want to perform"
        read subSelection
        case $subSelection in
        # Import all the images from current ACR to remote ACR
        1)
            echo -e "Please input the name of the remote ACR:"
            read remoteRegistry
            local repositoryList=`az acr repository list -n $ACRName -otsv`
            for repo in $repositoryList;
            do  
                echo -e "\nImporting images in repository $repo..."
                local tagList=`az acr repository show-tags -n $ACRName --repository $repo -otsv`
                for tag in $tagList;
                do
                    echo -e "Importing $repo:$tag..."
                    az acr import --name $remoteRegistry --source $repo:$tag --image $repo:$tag --registry $ACR_ID
                done
                echo -e "\n================================\n"
            done
            echo -e "Completed!\n"
            ;;
        # Import images in givin repository from current ACR to remote ACR
        2)
            echo -e "${GREEN}Listing repositories...${NC}"
            local repositoryList=`az acr repository list -n $ACRName -otsv`
            echo -e "All the repositories in the ACR $ACRName"
            echo -e "================================\n"
            for repo in $repositoryList;
            do
                echo -e "$repo"
            done
            echo -e "\n================================\n"
            echo -e "Please input the name of the target repository!"
            read inputRepo
            
            if printf "%s\n" "${repositoryList[@]}" | grep -q -x "$inputRepo"; then
                echo -e "Please input the name of the remote ACR:"
                read remoteRegistry
                echo -e "\nImporting images in repository $inputRepo..."
                local tagList=`az acr repository show-tags -n $ACRName --repository $inputRepo -otsv`
                for tag in $tagList;
                do
                    echo -e "Importing $inputRepo:$tag..."
                    az acr import --name $remoteRegistry --source $inputRepo:$tag --image $inputRepo:$tag --registry $ACR_ID
                done
                echo -e "\n================================"
                echo -e "\nCompleted!\n"
            else
                echo -e "${RED}Target repository doesn't exist!\n${NC}"
            fi
            ;;
        # Import all the images from remote ACR to current ACR
        3)
            echo -e "Please input the resource ID of the remote ACR:"
            read -r remoteRegistry
            local remoteACRName=`echo $remoteRegistry | awk  -F "/" '{print $9}'`
            local repositoryList=`az acr repository list -n $remoteACRName -otsv`
            for repo in $repositoryList;
            do  
                echo -e "\nImporting images in repository $repo..."
                local tagList=`az acr repository show-tags -n $remoteACRName --repository $repo -otsv`
                for tag in $tagList;
                do
                    echo -e "Importing $repo:$tag..."
                    az acr import --name $ACRName --source $repo:$tag --image $repo:$tag --registry $remoteRegistry
                done
                echo -e "\n================================\n"
            done
            echo -e "Completed!\n"
            ;;
        # Import images in givin repository from remote ACR to current ACR
        4)
            echo -e "\nPlease input the resource ID of the remote ACR:"
            read remoteRegistry
            local remoteACRName=`echo $remoteRegistry | awk  -F "/" '{print $9}'`
            echo -e "${GREEN}Listing repositories...${NC}"
            local repositoryList=`az acr repository list -n $remoteACRName -otsv`
            echo -e "All the repositories in the remote ACR $remoteACRName"
            echo -e "================================\n"
            for repo in $repositoryList;
            do
                echo -e "$repo"
            done
            echo -e "\n================================\n"
            echo -e "Please input the name of the target repository!"
            read inputRepo
            
            if printf "%s\n" "${repositoryList[@]}" | grep -q -x "$inputRepo"; then
                echo -e "\nImporting images in repository $inputRepo..."
                local tagList=`az acr repository show-tags -n $remoteACRName --repository $inputRepo -otsv`
                for tag in $tagList;
                do
                    echo -e "Importing $inputRepo:$tag..."
                    az acr import --name $ACRName --source $inputRepo:$tag --image $inputRepo:$tag --registry $remoteRegistry
                done
                echo -e "\n================================\n"
                echo -e "Completed!\n"
            else
                echo -e "${RED}Target repository doesn't exist!\n${NC}"
            fi
            ;;
        # Import the image from public registry without credentail
#        5)
#            echo -e "Building..."
#            ;;
        # Import the image from private registry with credential
#        6)
#            echo -e "Building..."
#            ;;
        # Return
        7)
            echo -e "Exiting..."
            break
            ;;
        # Error input
        *)
            echo -e "${RED}Invalid input, please input the correct option!\n${NC}"
            ;;
       esac
    done 
}

# The entrypoint of the script
while true
do

    echo -e "${GREEN}1. Show images in ACR\n2. Show the size of the images in ACR\n3. List basic information of ACR\n4. Import images from another ACR\n9. Exit\n${NC}"

    echo "Please input the number of the action you want to perform"

    read selection

    case $selection in
    1)
        image_list
        ;;
    2)
        image_size
        ;;
    3)
        list_info
        ;;
    4)
        import_images
        ;;
    9)
        echo -e "Exiting..."
        break
        ;;
    *)
        echo -e "${RED}Invalid input, please input the correct option!\n${NC}"
        ;;
    esac
done
