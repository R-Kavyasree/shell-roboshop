#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"

sudo mkdir -p "$LOGS_FOLDER"
sudo chown -R ec2-user:ec2-user "$LOGS_FOLDER"
sudo chmod -R 755 "$LOGS_FOLDER"

LOGS_FILE="$LOGS_FOLDER/03-mysql.sh.LOG"
SCRIPT_DIR=$PWD

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [ "$USERID" -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R Please run this script with root access $N" | tee -a "$LOGS_FILE"
    exit 1
fi

VALIDATE() {

    if [ "$1" -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2.... $R FAILURE $N" | tee -a "$LOGS_FILE"
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 ... $G SUCCESS $N" | tee -a "$LOGS_FILE"
    fi
}

dnf module disable nodejs -y &>> "$LOGS_FILE"
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y&>> "$LOGS_FILE"
VALIDATE $? "Enabling nodejs "

dnf install nodejs -y &>> "$LOGS_FILE"
VALIDATE $? "Installing  nodejs "


id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created .. $Y Skipping $N"
fi

rm -rf /app
VALIDATE $? "Removing existing code"

rm -rf /tmp/catalogue.zip
VALIDATE $? "Removed catalogue.zip"

mkdir -p /app
VALIDATE $? "Creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "Downloading catalogue code"

cd /app
unzip -o /tmp/catalogue.zip
VALIDATE $? "Extracted code"

npm install
VALIDATE $? "Installing dependencies"

cp "$SCRIPT_DIR/Catalouge.service" /etc/systemd/system/Catalouge.service
VALIDATE $? "Created systemctl service"

cp "$SCRIPT_DIR/mongo.repo" /etc/yum.repos.d/mongo.repo
VALIDATE $? "Added mongodb repo"

dnf install mongodb-mongosh -y
VALIDATE $? "Installed mongodb client"


INDEX=$(mongosh --host mongodb.rkdaws90.online  --eval 'db.getMongo().indexof("catalouge")')

if [ $INDEX -lt 0 ]; then
mongosh --host mongodb.rkdaws.online </app/db/master-data.js
VALIDATE $? "Load products"

else

echo -e "Products already loaded .... $Y SKIPPING $N"

fi

systemctl enable catalouge
systemctl restart catalouge

VALIDATE $? "Restarting catalogue"


