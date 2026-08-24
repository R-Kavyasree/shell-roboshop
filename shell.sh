#!/bin/bash

AMI_ID="ami-0c02fb55956c7d316"
INSTANCE_TYPE="t3.micro"
COMMON_SG="roboshop"

instance=$1

if [ -z "$instance" ]; then
    echo "Usage: sh shell.sh <component>"
    echo "Example: sh shell.sh rabbitmq"
    exit 1
fi

echo "Launching instance: $instance"

# Get Security Group ID
SECURITY_GROUP=$(aws ec2 describe-security-groups \
    --group-names "$COMMON_SG" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

if [ "$SECURITY_GROUP" == "None" ] || [ -z "$SECURITY_GROUP" ]; then
    echo "ERROR: Security group '$COMMON_SG' not found"
    exit 1
fi

echo "Using Security Group: $SECURITY_GROUP"

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SECURITY_GROUP" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
    echo "ERROR: Instance launch failed"
    exit 1
fi

echo "Waiting for instance to reach running state..."

aws ec2 wait instance-running \
    --instance-ids "$INSTANCE_ID"

echo "Instance $instance is running"

# Get private IP
PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

echo "Private IP: $PRIVATE_IP"

# Component-specific setup
case "$instance" in

    mongodb
        echo "MongoDB server launched"
        ;;

    mysql
        echo "MySQL server launched"
        ;;

    redis
        echo "Redis server launched"
        ;;

    rabbitmq
        echo "RabbitMQ server launched"
        ;;

    catalogue
        echo "Catalogue server launched"
        ;;

    user
        echo "User server launched"
        ;;

    cart
        echo "Cart server launched"
        ;;

    shipping
        echo "Shipping server launched"
        ;;

    payment
        echo "Payment server launched"
        ;;

    dispatch
        echo "Dispatch server launched"
        ;;

    frontend
        echo "Frontend server launched"
        ;;

    *
        echo "WARNING: No specific setup for $instance"
        ;;

esac

echo "-----------------------------------"
echo "Component : $instance"
echo "Instance  : $INSTANCE_ID"
echo "Private IP: $PRIVATE_IP"
echo "-----------------------------------"