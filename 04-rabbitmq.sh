#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="smachiv.store"
scripts_dir=$(dirname "$(realpath "$0")")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
if [ $user_id -ne 0 ]; then
    echo "Please run this script with sudo access.."
    exit 1
fi

mkdir -p $logs_folder

timestamp(){
    date "+%F %T" 
}

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}
echo "$(timestamp) [INFO] ==== Script started Execution =====" | tee -a $logs_file
cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "Adding RabbbitMQ repo"

dnf install erlang rabbitmq-server -y &>> $logs_file
validate $? "Installing rabbitmq-server"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
validate $? "enabling and starting rabbitmq-server"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

#checking user details and creating user
rabbitmqctl list_users | grep -qw "roboshop"
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123
    validate $? "Adding user and setting permissions"
else
    echo -e "$(timestamp) [INFO] RabbitMQ user already exist...${Y}SKIPPING${N}"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $logs_file
validate $? "Setting permissions for Rabbitmq user for roboshop"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file

