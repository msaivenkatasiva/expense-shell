#!/bin/bash

ID=$(id -u)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE=/tmp/$SCRIPT_NAME-%$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

echo "please enter db password"
read -s msql_root_password

VALIDATE () {
    if [ $1 -ne 0 ]
    then    
        echo -e "$R error in $2 $N"
    else
        echo -e "$G $2 is success $N"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "please login with $R superuser $N"
else
    echo -e "$Y your are super user $N"
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "enabling nodejs"

dnf install nodejs -y
VALIDATE $? "installing nodejs"

id expense
if [ $? -ne 0 ]
then 
    useradd expense
    VALIDATE $? "adding user"
else
    echo -e "Expense user already created...$Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip 
VALIDATE $? "downloading zipfile"

cd /app

rm -rf /app/*
unzip /tmp/backend.zip
VALIDATE $? "extracted backend code"

npm install
VALIDATE $? "dependencies installing"

cp /home/ec2-user/expense-shell /etc/systemd/system/backend.service
VALIDATE $? "copying backend file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon Reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "Starting backend"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enabling backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing MySQL Client"

mysql -h db.daws78s.online -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Schema loading"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting Backend"