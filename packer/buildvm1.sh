#!/bin/bash

echo "************* set environment vars"
wget https://releases.hashicorp.com/packer/1.4.4/packer_1.4.4_linux_amd64.zip
unzip packer*
sudo cp -p packer /usr/local/bin/packer
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
export ARM_CLIENT_ID=$1
export ARM_CLIENT_SECRET=$2
export ARM_SUBSCRIPTION_ID=$3
export ARM_TENANT_ID=$4
export ARM_RESOURCE_GROUP_DISKS=$5

# export SIG variable
export sig_rg=$7
export siggallery_name=$8
export sig_def=$9

echo $7 $8 $9

export sigimagever="1.0.2"
export sigloc="westus2"
export sigtarget1="EastUS2"
export sigtarget2="WestUS2"
export sigreplica="2"
export ostype="Linux"
export sigoffer="rhel7x"
export sigsku="7.3"
export sigpublisher="rsazpublisher"



rm packer-build-output.log
echo "************* execute packer build drop path $6"
## execute packer build and send out to packer-build-output file
packer build  -var playbook_drop_path=$6 ./app1.json 2>&1 | tee packer-build-output.log

## export output variable to VSTS 
export manageddiskname=$(cat packer-build-output.log | grep ManagedImageName: | awk '{print $2}')
echo "variable $manageddiskname"
echo "##vso[task.setvariable variable=manageddiskname]$manageddiskname"

export managedimageid=$(cat packer-build-output.log | grep ManagedImageId: | awk '{print $2}')
echo "variable $managedimageid"
echo "##vso[task.setvariable variable=managedimageid]$managedimageid"

export managedimagelocation=$(cat packer-build-output.log | grep ManagedImageLocation: | awk '{print $2}')
echo "variable $managedimagelocation"
echo "##vso[task.setvariable variable=managedimagelocation]$managedimagelocation"

# [ -z "$manageddiskname" ] && exit 1 || exit 0
# [ -z "$managedimageid" ] && exit 1 || exit 0
# [ -z "$managedimagelocation" ] && exit 1 || exit 0

#AZ SIG commands

az login --service-principal -u $1 -p $2 --tenant $4
az account set --subscription $3

#az group create --name $sigrg --location $sigloc

#az sig create --resource-group $sigrg --gallery-name $siggalleryname
az sig create --resource-group $7 --gallery-name $8

# Create Image definition

az sig image-definition create --resource-group $7 --gallery-name $8 --gallery-image-definition $9 --publisher $sigpublisher --offer $sigoffer --sku $sigsku --os-type $ostype

echo "# Create Image version"

#az sig image-version create -g $sigrg --gallery-name $siggalleryname --gallery-image-definition $siggalleryimage --gallery-image-version $sigimagever --managed-image $managedimageid

az sig image-version create -g $7 --gallery-name $8 --gallery-image-definition $9 --gallery-image-version $sigimagever --managed-image $managedimageid

echo "# Add Image to Target regions"
#az sig image-version create --resource-group $sigrg --gallery-name $siggalleryname --gallery-image-definition $siggalleryimage --gallery-image-version $sigimagever --managed-image $managedimageid --target-regions "$sigtarget1" "$sigtarget2"

az sig image-version create --resource-group $7 --gallery-name $8 --gallery-image-definition $9 --gallery-image-version $sigimagever --managed-image $managedimageid --target-regions "$sigtarget1" "$sigtarget2"

[ -z "$manageddiskname" ] && exit 1 || exit 0
