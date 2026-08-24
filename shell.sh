#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z07104562L34RC4JURX7T"
DOMAIN_NAME="rkdaws90.online"

for instance in "$@"
do
    echo "Launching instance: $instance"

    if [ "$instance" == "mongodb" ]; then
        SG1="roboshopcommon"
        SG2="roboshop-mangodb"

    elif [ "$instance" == "mysql" ]; then
        SG1="roboshopcommon"
        SG2="Mysqlrs"

    elif [ "$instance" == "redis" ]; then
        SG1="roboshopcommon"
        SG2="Redis _RS"

    elif [ "$instance" == "rabbitmq" ]; then
        SG1="roboshopcommon"
        SG2="Rabbitmq rs"

    elif [ "$instance" == "catalogue" ] || [ "$instance" == "Catalouge" ]; then
        SG1="roboshopcommon"
        SG2="catalouge_RS"

    elif [ "$instance" == "user" ]; then
        SG1="roboshopcommon"
        SG2="User_RS"

    elif [ "$instance" == "cart" ]; then
        SG1="roboshopcommon"
        SG2="Cart_RS"

    elif [ "$instance" == "shipping" ]; then
        SG1="roboshopcommon"
        SG2="ShipmentRS"

    elif [ "$instance" == "payment" ]; then
        SG1="roboshopcommon"
        SG2="PaymentsRS"

    elif [ "$instance" == "dispatch" ]; then
        SG1="roboshopcommon"
        SG2="Dispatch RS"

    elif [ "$instance" == "frontend" ]; then
        SG1="roboshopcommon"
        SG2="Frontend_RS"

    else
        echo "ERROR: Unknown component: $instance"
        continue
    fi

    echo "Using Security Groups: $SG1 and $SG2"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-groups "$SG1" "$SG2" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    echo "Instance ID: $INSTANCE_ID"

    if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
        echo "ERROR: Failed to launch $instance"
        continue
    fi

    echo "Waiting for instance to be running..."

    aws ec2 wait instance-running \
        --instance-ids "$INSTANCE_ID"

    if [ "$instance" == "frontend" ]; then

        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)

        R53_RECORD="$DOMAIN_NAME"

    else

        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)

        if [ "$instance" == "Catalouge" ]; then
            R53_RECORD="catalogue.$DOMAIN_NAME"
        else
            R53_RECORD="$instance.$DOMAIN_NAME"
        fi

    fi

    echo "IP Address: $IP"
    echo "Route53 Record: $R53_RECORD"

    if [ -z "$IP" ] || [ "$IP" == "None" ]; then
        echo "ERROR: IP address not found for $instance"
        continue
    fi

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch '{
            "Comment": "update a record to new IP",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": "'"$R53_RECORD"'",
                        "Type": "A",
                        "TTL": 1,
                        "ResourceRecords": [
                            {
                                "Value": "'"$IP"'"
                            }
                        ]
                    }
                }
            ]
        }'

    echo "Route53 updated successfully for $R53_RECORD"
    echo "----------------------------------------"

done