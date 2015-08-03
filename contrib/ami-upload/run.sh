#!/bin/bash


export EC2_ACCESS_KEY=XXXXXXXXXXXXXX
export EC2_SECRET_KEY=XXXXXXXXXXXXX
# aws region where the ami will be uploaded. use AWS UI to then Copy to other regions.
export REGION=us-west-2
# aws account number where the ami will be uploaded
export EC2_ACCOUNT=XXXXXXXXXXXXXXXXXX
export EC2_PRIVATE_KEY=XXXXXXXXXXXXX
export EC2_CERT=XXXXXXXXXXXXX
# use the virt raw image from the ci job that uses the ami kickstart
export RAW_FILE=/path/to/cloudrouter-raw-virt

# this script will use the jenkins ci account in aws
# it will use the base ami mentioned in upload_fedora_ebs.py ami-dbddd2eb
# to create a base instance and attach a volume to it to dd the 
# ${RAW_FILE} into and then take a snapshot of that volume to 
# make the AMI. 
sudo -E python upload_fedora_ebs.py --arch x86_64 -d -D ${RAW_FILE}

