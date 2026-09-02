#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z07104562L34RC4JURX7T"
DOMAIN_NAME="rkdaws90.online"

## Validation ###

if [ $# -lt 2 ]; then
   echo -e " $R ERROR :: Atleast 2 arguments required $N"
   echo "USAGE: $0 [create/delete] [instance1] [instance2..]"
   exit 1
fi

   ACTION=$1
   shift # first argument will be removed

   if [ $Action -ne create] && [ $ACTION -ne "delete"]; then
   echo "ERROR :: First argument must be either create or delete"
   echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
   exit 1
   fi

   if [ $ACTION -ne "create" ] && [ $ACTION -ne "delete" ]; then
   echo -e "$R ERROR :: First argument must be either create or delte"
   echo "USAGE: $0 [create/delete] [instance1] [instance2..]"
   exit 1
   fi

   