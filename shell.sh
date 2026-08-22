#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z07104562L34RC4JURX7T"  
DOMAIN_NAME="rkdaws90.online"

for instance in $@

do 
echo "Launching instance: $instance"
   INSATANCE_ID=$(aws ec2 run-instances \
--image-id ami-0220d79f3f480ecf5 \
--instance-type t3.micro \
--security-groups "roboshopcommon" "roboshop-$instance" \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
--query 'Instances[0].InstanceId' \
--output text
   )
   echo "Instance ID: $Instance"

   if  [$instance == "frontned" ]; then
   IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
   --query 'Reservationns[*].Instance[*].PublicIpAddress' \
   --output text
   )
   R53_RECORD="$DOMAIN_NAME"
   else
   IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
   --query 'Reservationns[*].Instance[*].PrivateIpAddress' \
   --output text)

   R53_RECORD="$instance.$DOMAIN_NAME"
   fi

   ### Updating R53 Record ###

   aws route53 change-resource-record-sets \
   --hosted-zone-id  $ZONE_ID \
   --change-batch '
   {
   "Comment": "update a record to new IP",
   "Changes": [
   {
             "Action": "UPSERT"
             "ResourceRecordSet": {
             "Name": "'$R53_RECORD'",
             "Type": "A",
             "ResourceRecords" : [ 
             {
             "value" : "'$IP'"
             }
             ]
             }
             }
             ]
             }
               '
done


