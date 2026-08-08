#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.LOG"

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[-m"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")


if [ $USERID -ne 0 ]; then
echo -e " $TIMESTAMP [ERROR] $R Please run this script with root access $N" | TEE -a $LOGS_FILE
exit 1
fi
VALIDATE(){
    if [ $1 -ne 0 ]; then
    echo -e " $2.... $R FAILURE $N" | tee -a $LOGS_FILE
    exit 1
    else
    echo -e "$TIMESTAMP [INFO] $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
fi 


}
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "ADDING Mongo repo"

dnf install mongodb-org -y &>> $LOGS_FILE
VALIDATE $? "Installing Mongodb"

systemctl enable --now mongod
VALIDATE $? "starting and enabling Mongodb"
