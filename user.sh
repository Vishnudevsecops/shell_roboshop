#!/bin/bash
# -------------------------
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

# Function to validate installation status
validate(){
    if [ $1 -ne 0 ]; then
        echo -e "error:: $2 $R failed $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 $G Completed $N" | tee -a $log_file
    fi

}

dnf module disable nodejs -y &>>$log_file
validate $? "Nodejs module disable"
dnf module enable nodejs:20 -y &>>$log_file
validate $? "Nodejs module enable"
dnf install nodejs -y &>>$log_file
validate $? "Nodejs"

#check if roboshop user exist
id roboshop &>>$log_file

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "roboshop user"
else
    echo -e "roboshop user already exist..... $Y Skipped $N" | tee -a $log_file
fi

#create app directory
mkdir -p /app &>>$log_file
validate $? "/app directory creation"

#download user code
curl -o curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$log_file
validate $? "user download"
cd /app
validate $? "changing directory to /app"

#remove old content
rm -rf /app/* &>>$log_file
validate $? "removing old content"

#unzip the content
unzip /tmp/user.zip &>>$log_file
validate $? "user unzip"

cd /app || { echo "Failed to change to /app"; exit 1; }
npm install &>>$log_file
validate $? "npm dependencies"

#copy service file
cp $script_dir/user.service /etc/systemd/system/user.service &>>$log_file
validate $? "user service file copy"

systemctl daemon-reload &>>$log_file
validate $? "daemon reload"
systemctl enable user &>>$log_file
validate $? "user enable"
systemctl start user &>>$log_file
validate $? "user start"

systemctl restart user &>>$log_file
validate $? "user restart"

