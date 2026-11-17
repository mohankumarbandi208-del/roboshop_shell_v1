#!/bin/bash
#get the user type
user_id=$(id -u)

# define the logs folder
logs_folder="/var/log/roboshop"

#define logs file
logs_file="${logs_folder}/${0}.log"

#define colours
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="e[0m"

if [ $user_id -ne 0 ]; then
    echo "Please run this script with sudo access"
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date "%F %T"

}
validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(tiemstamp) [ERROR] ${2} ${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] ==== Script started Execution =====" | tee -a $logs_file

dnf module enable mysql:8.4 -y &>> $logs_file
validate $? "enabling MYSQL:8.4 version"

dnf install mysql-server -y &>> $logs_file
validate $? "Installing sql-server"

systemctl enable mysql &>> $log_file
systemctl start mysqld

validate $? "start and enable MySQL"

#setting root password
mysql_secure_installation --set-root-pass RoboShop@1
validate $? "Setup MySQL root password"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file