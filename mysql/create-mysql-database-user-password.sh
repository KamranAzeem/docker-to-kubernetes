#!/bin/bash

MYSQL_ADMIN_USER=root
DATABASE_NAME=$1

echo
if [ -z "${DATABASE_NAME}" ]; then
  echo "Please provide name of the database to be created."
  echo "Usage: $0 <database-name>"
  echo
  echo "To keep things simple, this script will create a USER_NAME for this database with the same name as database-name."
  echo "Note: The dots (.) in database-name will be converted to underscores (_)"
  echo "It will also auto-generate a random password, assign it to the user, and will show it on the screen only once."
  echo

  exit
fi

# Note: Not using `mysqladmin ping`, because it can cause confusion.
#       https://stackoverflow.com/questions/18522847/mysqladmin-ping-error-code

echo "Checking if MySQL server instance can be connected as user ${MYSQL_ADMIN_USER} ..."
mysql -e "select 1;" > /dev/null
if [ $? -ne 0 ] ; then
  echo "User ${MYSQL_ADMIN_USER} cannot connect to MySQL instance. Aborting ..."
  exit
fi

echo "Found DATABASE_NAME set as ${DATABASE_NAME}"
DATABASE_NAME=$(echo ${DATABASE_NAME} | tr '.' '_')
USER_NAME=${DATABASE_NAME}
PASSWORD=$(openssl rand -base64 18)

echo "Creating database: ${DATABASE_NAME} ..."
mysql -u ${MYSQL_ADMIN_USER} -e "create database ${DATABASE_NAME};"
echo "Creating user: ${USER_NAME} ..."
mysql -u ${MYSQL_ADMIN_USER} -e "grant all on ${DATABASE_NAME}.* to '${USER_NAME}'@'%' identified by '${PASSWORD}'; "
mysql -u ${MYSQL_ADMIN_USER} -e "flush privileges;"

echo 
echo "Database: ${DATABASE_NAME}"
echo "User: ${USER_NAME}"
echo "Password: ${PASSWORD}"

# create database wbitt_com;
# grant all on wbitt_com.* to 'wbitt_com'@'%' identified by 'randompassword';

##########################################################################
# Below is how you setup mysql password-less login for a particular user.
# USE AT YOUR OWN RISK!
#
# cat ~/.my.cnf 
# [mysql]
# user=root
# password=super-secret-password
###########################################################################
