#!/bin/bash

ami_id="ami-09c813fb71547fc4f"
sg_id="sg-0473e0dab07b57594"

for instance in $@
do 
    instance_id=$(aws ec2 run-instances \
    --image-id $ami_id --instance-type t3.micro \
    --security-group-ids $sg_id \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' --output text)

    echo "Waiting for instance $instance_id to be in 'running' state..."
    aws ec2 wait instance-running --instance-ids "$instance_id"
    
    if [ $instance != "frontend" ]; then
        ip_address=$(aws ec2 describe-instances \
        --instance-ids $instance_id \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)
    else
        ip_address=$(aws ec2 describe-instances \
        --instance-ids $instance_id \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    fi

    echo "Instance ID: $instance_id, IP Address: $ip_address"

    
done