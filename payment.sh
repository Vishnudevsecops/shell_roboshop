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

dnf install python3 gcc python3-devel -y &>>$log_file
validate $? "Python3 installation"

#check if roboshop user exist
id roboshop &>>$log_file

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "roboshop user"
else
    echo -e "roboshop user already exist..... $Y Skipped $N" | tee -a $log_file
fi

mkdir /app &>>$log_file
validate $? "/app directory creation"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$log_file
validate $? "payment download"  
cd /app 

unzip /tmp/payment.zip &>>$log_file
validate $? "payment unzip" 

cd /app 
pip3 install -r requirements.txt &>>$log_file
validate $? "payment dependencies"  

cp $script_dir/payment.service /etc/systemd/system/payment.service &>>$log_file
validate $? "payment service file copy"
systemctl daemon-reload &>>$log_file
validate $? "daemon reload"
systemctl enable payment &>>$log_file
validate $? "payment enable"
systemctl start payment &>>$log_file
validate $? "payment start" 

