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
    echo "Please run this script with sudo access.."
    exit 1
fi

mkdir -p $logs_folder

echo "Script started execution at $(date +"%F %T")" &>> $logs_file

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

cp mongo.repo vim /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo repo"

dnf install mongodb-org -y &>> $logs_file
validate $? "Installing Mongodb"

systemctl enable mongod &>> $logs_file
validate $? "Enabling mongod"

systemctl start mongod &>> $logs_file
validate $? "Starting mongod"

sed -i 's/127.0.0.1/0.0.0.0/' /etc//mondod.conf
validate $? "Configuring Mongod "

systemctl restart mongod &>> $logs_file
validate $? "Restarting mongod"

