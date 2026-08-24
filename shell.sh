#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z07104562L34RC4JURX7T"
DOMAIN_NAME="rkdaws90.online"

for instance in "$@"
do
    echo "Launching instance: $instance"

    case "$instance" in

        mongodb
            SECURITY_GROUPS=("roboshopcommon" "roboshop-mangodb")
            ;;

        mysql
            SECURITY_GROUPS=("roboshopcommon" "Mysqlrs")
            ;;

        redis
            SECURITY_GROUPS=("roboshopcommon" "Redis _RS")
            ;;

        rabbitmq
            SECURITY_GROUPS=("roboshopcommon" "Rabbitmq rs")
            ;;

        catalogue
            SECURITY_GROUPS=("roboshopcommon" "catalouge_RS")
            ;;

        user
            SECURITY_GROUPS=("roboshopcommon" "User_RS")
            ;;
        cart
            SECURITY_GROUPS=("roboshopcommon" "Cart_RS")
            ;;

        shipping
            SECURITY_GROUPS=("roboshopcommon" "ShipmentRS")
            ;;

        payment
            SECURITY_GROUPS=("roboshopcommon" "PaymentsRS")
            ;;

        dispatch
            SECURITY_GROUPS=("roboshopcommon" "Dispatch RS")
            ;;

        frontend
            SECURITY_GROUPS=("roboshopcommon" "Frontend_RS")
            ;;

        *
            echo "ERROR: Unknown component: $instance"
            continue
            ;;
    esac

    echo "Using Security Groups: ${SECURITY_GROUPS[*]}"

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type t3.micro \
        --security-groups "${SECURITY_GROUPS[@]}" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text
    )

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
            --output text
        )

        R53_RECORD="$DOMAIN_NAME"

    else

        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
        )

        R53_RECORD="$instance.$DOMAIN_NAME"

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