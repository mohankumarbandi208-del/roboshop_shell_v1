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
#starting script
echo "$(timestamp) [INFO] ==== Script started Execution =====" | tee -a $logs_file

#install Nodejs
dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "installing nodejs"

#Creating User
id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating user"
else
    echo -e "$(timestamp) [INFO] system user roboshop already exist....${Y}SKIPPING${N}"
fi

#Removing old code 
rm -rf /app
validate $? "Removing old code"

#creating app directory
mkdir /app
validate $? "create app directory"

#download code
curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>> $logs_file
cd /app
unzip /tmp/catalogue.zip &>> $logs_file
validate $? "Downloading catalogue"

#install dependencies
cd /app
npm install &>> $logs_file
validate $? "Installing dependencies"

#configure the catalogue service file
sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/catalogue.service"
cp "$scripts_dir/catalogue.service" /etc/systemd/system/catalogue.service
validate $? "copying catalogue service file"

#restart catalogue
systemctl daemon-reload &>> $logs_file
systemctl enable catalogue &>> $logs_file
systemctl start catalogue &>> $logs_file
validate $? "Starting and enabling catalogue"

#Adding Mongo repo
cp "$scripts_dir/mongo.repo" /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo repo"

#install mongodb
dnf install mongodb-mongosh -y &>> $logs_file
validate $? "Installing MongoDB Client"

#collect the count of the products and if u got ERROR move to logs file
product_count=$(mongosh --host "mongodb.$domain_name" --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()' 2>> $logs_file)
validate $? "Connecting to MongoDB"

# If products are not loaded load the data from the database
if [ "$product_count" -eq 0 ]; then
    mongosh --host "mongodb.$domain_name" </app/db/master-data.js &>> $logs_file
    validate $? "Loading products"
else
    echo -e "$(timestamp) [INFO] Products are already loaded...${Y}SKIPPING${N}"
fi

systemctl restart catalogue
validate $? "Restarting Catalogue"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file
