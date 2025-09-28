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

cp $script_dir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$log_file
validate $? "Rabbitmq repo setup"   

dnf install rabbitmq-server -y &>>$log_file
validate $? "Rabbitmq installation"

systemctl enable rabbitmq-server &>>$log_file
validate $? "Rabbitmq enable"
systemctl start rabbitmq-server &>>$log_file
validate $? "Rabbitmq start"    

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

validate $? "Rabbitmq user creation"

echo -e "Script execution completed at : $(date) $G Successful $N" | tee -a $log_file
