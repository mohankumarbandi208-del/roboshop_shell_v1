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

dnf module disable redis -y &>> $logs_file
dnf module enable redis:7 -y &>> $logs_file
dnf install redis -y &>> $logs_file
validate $? "Installing redis"

sed -i -e 's/^bind 127.0.0.1/bind 0.0.0.0/' -e 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

systemctl enable redis
systemctl start redis
validate $? "Enable to start Redis"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file