#!/bin/bash

#exit on any error, undefined variable or error in a pipe
set -euo pipefail 
#-------------------------
# Color Codes
# -------------------------
R="\e[31m" #Red
G="\e[32m" #Green
Y="\e[33m" #Yellow
N="\e[0m"  #No Color    

#check if current user has root access
user_rootaccess=$(id -u)

mongodb_host="mongodb.techup.fun"
script_dir=$(pwd)
#create folder in log folder 
logs_folder="/var/log/shell-roboshop"
#removing .sh from script name to create a log file
script_name=$( echo $0 | cut -d "." -f1 )
log_file="$logs_folder/$script_name.log" 

mkdir -p $logs_folder
echo "script started excuting at : $(date)" | tee -a $log_file
#if user does not have root access
if [ $user_rootaccess -ne 0 ]; then 
    echo "Error:: Please run the script using root access"
    exit 1
fi

#nodejs 
dnf module disable nodejs -y &>>$log_file
dnf module enable nodejs:20 -y &>>$log_file
dnf install nodejs -y &>>$log_file
echo -e "Nodejs installation completed" "$G Successful $N | tee -a $log_file

#check if roboshop user exist
id roboshop &>>$log_file

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
else
    echo -e "roboshop user already exist..... $Y Skipped $N" | tee -a $log_file
fi

#create app directory
mkdir -p /app &>>$log_file
echo -e "/app directory created...." $G Successful $N | tee -a $log_file

#download catalogue code
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
echo -e "catalogue code downloaded" $G Successful $N | tee -a $log_file
cd /app

#remove old content
rm -rf /app/* &>>$log_file
echo -e "old content removed" $G Successful $N | tee -a $log_file
#unzip the content
unzip /tmp/catalogue.zip &>>$log_file
echo -e "catalogue unzip completed" $G Successful $N | tee -a $log_file

cd /app || { echo "Failed to change to /app"; exit 1; }
npm install &>>$log_file
echo -e "npm dependencies installed" $G Successful $N | tee -a $log_file
#copy service file
cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service &>>$log_file
echo -e "catalogue service file copied" $G Successful $N | tee -a $log_file

systemctl daemon-reload &>>$log_file
systemctl enable catalogue &>>$log_file
systemctl start catalogue &>>$log_file
echo -e "catalogue service started" $G Successful $N | tee -a $log_file

# copy mongodb repo file 
cp $script_dir/mongodb.repo /etc/yum.repos.d/mongo.repo &>>$log_file
echo -e "Mongodb repo file copied" $G Successful $N | tee -a $log_file
dnf install mongodb-mongosh -y &>>$log_file
echo -e "Mongosh client installed" $G Successful $N | tee -a $log_file

# Check if the catalogue database is already populated
INDEX=$(mongosh $mongodb_host --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -le 0 ]; then
    mongosh --host $mongodb_host </app/db/master-data.js &>>$log_file
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue &>>$log_file
echo -e "Loading products and restarting catalogue ... $G SUCCESS $N"
echo -e "script executed successfully at : $(date)"..... $G Successful $N | tee -a $log_file
