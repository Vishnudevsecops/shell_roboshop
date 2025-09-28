#!/bin/bash

ami_id="ami-09c813fb71547fc4f"
sg_id="sg-0473e0dab07b57594"
zone_id="Z01937573HQBFLFNZX4SW"
domain_name="techup.fun"

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
        record_name="$instance.$domain_name"
    else
        ip_address=$(aws ec2 describe-instances \
        --instance-ids $instance_id \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
        record_name="$domain_name"
    fi

    echo "$instance: $ip_address"

    aws route53 change-resource-record-sets \
        --hosted-zone-id $zone_id \
        --change-batch '
        {
            "Comment": "Updating record set"
            ,"Changes": [{
                "Action"              : "UPSERT"
                ,"ResourceRecordSet"  : {
                "Name"              : "'$record_name'"
                ,"Type"             : "A"
                ,"TTL"              : 1
                ,"ResourceRecords"  : [{
                "Value"         : "'$ip_address'"
            }]
        }
        }]
  }
  '
done