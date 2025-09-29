# #!/bin/bash
# # -------------------------
# # Color Codes
# # -------------------------
# R="\e[31m" #Red
# G="\e[32m" #Green
# Y="\e[33m" #Yellow
# N="\e[0m"  #No Color    

# #check if current user has root access
# user_rootaccess=$(id -u)

# mongodb_host="mongodb.techup.fun"
# mysql_host="mysql.techup.fun"
# script_dir=$(pwd)
# #create folder in log folder 
# logs_folder="/var/log/shell-roboshop"
# #removing .sh from script name to create a log file
# script_name=$( echo $0 | cut -d "." -f1 )
# log_file="$logs_folder/$script_name.log" 

# mkdir -p $logs_folder
# echo "script started excuting at : $(date)" | tee -a $log_file
# #if user does not have root access
# if [ $user_rootaccess -ne 0 ]; then 
#     echo "Error:: Please run the script using root access"
#     exit 1
# fi

# # Function to validate installation status
# validate(){
#     if [ $1 -ne 0 ]; then
#         echo -e "error:: $2 $R failed $N" | tee -a $log_file
#         exit 1
#     else
#         echo -e "$2 $G Completed $N" | tee -a $log_file
#     fi

# }

# dnf install maven -y &>>$log_file
# validate $? "Maven installation"

# id roboshop &>>$log_file

# if [ $? -ne 0 ]; then
#     useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
#     validate $? "roboshop user"
# else
#     echo -e "roboshop user already exist..... $Y Skipped $N" | tee -a $log_file
# fi

# mkdir -p /app &>>$log_file
# validate $? "/app directory creation"

# curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file   
# validate $? "shipping download"

# cd /app 
# validate $? "Changing to app directory"

# rm -rf /app/*
# validate $? "Removing existing code"

# unzip /tmp/shipping.zip -d /app &>>$log_file
# validate $? "shipping unzip"

# mvn clean package &>>$log_file
# validate $? "maven build"
# mv target/shipping-1.0.jar shipping.jar &>>$log_file
# validate $? "shipping rename"

# cp $script_dir/shipping.service /etc/systemd/system/shipping.service &>>$log_file
# validate $? "shipping service file copy"


# systemctl daemon-reload &>>$log_file
# validate $? "daemon reload"
# systemctl enable shipping &>>$log_file
# validate $? "shipping enable"

# dnf install mysql -y &>>$log_file
# validate $? "mysql client"

# mysql -h $mysql_host -uroot -pRoboShop@1 -e 'use cities' &>>$log_file
# if [ $? -ne 0 ]; then
#     mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/schema.sql &>>$log_file
#     mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$log_file
#     mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$log_file
# else
#     echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
# fi

# systemctl restart shipping &>>$log_file
# validate $? "shipping restart"

# echo -e "shipping setup completed $G Successful $N" | tee -a $log_file


#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.techup.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
MYSQL_HOST=mysql.techup.fun

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf install maven -y &>>$LOG_FILE

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping application"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip shipping"

mvn clean package  &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
systemctl daemon-reload
systemctl enable shipping  &>>$LOG_FILE

dnf install mysql -y  &>>$LOG_FILE

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping