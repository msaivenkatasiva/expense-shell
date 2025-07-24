#!/bin/bash

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
Y="\e[32m"
G="\e[33m"
N="\e[0m"

echo "please enter DB password"
read -s mysql_root_password


VALIDATE () {
    if [ $1 -ne 0 ]
    then
        echo -e "$R error in $2 $N"
    else
        echo -e "$2 is $G success $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo -e "$Y please login with $N $R superuser $N"
fi

dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "installing mysql server"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "enabling mysql server"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "starting mysql server"

#below command is not idempotent
#mysql_secure_installation --set-root-pass ExpenseApp@1

#idempotent
mysql -h db.devopswithmsvs.uno -uroot -p${mysql_root_password} -e 'show databases;' &>>$LOGFILE
if [ $? -ne 0 ]
then
    mysql_secure_installation --set-root-pass ${mysql_root_password} &>>$LOGFILE
else    
    echo -e "mysql_root_password is already exists $Y SKIPPING $N"
fi


