#!/bin/bash
ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="smachiv.shop"
hosted_zone="Z10174963E55RGLCKCJWD"

for instance in $@
do
    echo "Starting Instance : $instance"
    #launch the instance with selected ami
    #defince the instance type here t3.micro
    #assign the security groups
    #assign the name to the instance
    #get the instance ID in text format
    Instance_id=$(aws ec2 run-instances \
            --image-id $ami_id \
            --instance-type $instance_type \
            --security-groups "roboshop-common" "roboshop-$instance" \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]"\
            --query 'Instances[0].InstanceId' \
            --output text
        )
    echo "$instance Instance ID : $Instance_id"

    #Get the IP address of the instances
    if [$instance=="frontend"]; then
        IP=$(aws ec2 describe-instances --instance-ids $Instance_id \
             --query 'Reservations[].Instances[].PublicIpAddress' --output text
             )
        #define the Route 53 record
        r53_record=$domain_name

    else
        IP=$(aws ec2 describe-instances --instance-ids $Instance_id \
             --query 'Reservations[].Instances[].PrivateIpAddress' --output text
             )
        #define the Route 53 record
        r53_record=$instance.$domain_name
    fi

    #Update the R53 Record
    echo "Record: ${r53_record}"
    aws route53 change-resource-record-sets \
    --hosted-zone-id $hosted_zone \
    --change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$r53_record'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{"Value": "'$IP'"}]
                }
            }
        ]
    }'

    echo "Updated R53 record for $instance"
    echo "$r53_record"


done