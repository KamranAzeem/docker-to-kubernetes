#!/bin/bash
# This script reads mysql.env and creates equivalent kubernetes secrets.
# It needs to be capable for creating k8s secrets by reading ENV variables as well,
#   as, that is the case with CI systems.
if [ ! -f ./mysql.env ]; then
  echo "Could not find ENV variables file for mysql - ./mysql.env"
  exit 1
fi

echo "First delete the old secret: mysql-credentials"
kubectl delete secret mysql-credentials  || true

echo "Found mysql.env file, creating kubernetes secret: mysql-credentials"
source ./mysql.env


kubectl create secret generic mysql-credentials \
  --from-literal=MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

#  --from-literal=MYSQL_DATABASE=${MYSQL_DATABASE} \
#  --from-literal=MYSQL_USER=${MYSQL_USER} \
#  --from-literal=MYSQL_PASSWORD=${MYSQL_PASSWORD}


