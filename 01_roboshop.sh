#!/bin/bash

ami_id="ami-09c813fb71547fc4f"
sg_id="sg-0473e0dab07b57594"

for instance in $@
do 
    instace_id=$(aws ec2 run-instances --image-id $ami_id --instance-type t3.micro --security-group-ids $sg_id --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$instance}]' --query 'Instances[0].InstanceID' --output text)

    if [ $? != frontend ]; then
        ip_address=$(aws ec2 describe-instances --instance-ids $instace_id --query 'Reservations[0].Instances[0].PrivateIPAddress' --output text)
    else
        ip_address=$(aws ec2 describe-instances --instance-ids $instace_id --query 'Reservations[0].Instances[0].PublicIPAddress' --output text)
    fi

    echo "Instance ID: $instace_id, IP Address: $ip_address"

    
done