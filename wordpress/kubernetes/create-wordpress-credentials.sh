#!/bin/bash
# This script reads mysql.env and creates equivalent kubernetes secrets.
# It needs to be capable for creating k8s secrets by reading ENV variables as well,
#   as, that is the case with CI systems.
if [ ! -f ./wordpress.env ]; then
  echo "Could not find ENV variables file for wordpress. The file is missing: ./wordpress.env"
  exit 1
fi

echo "First, deleting the old secret: wordpress-credentials"
kubectl delete secret wordpress-credentials || true

echo "Found wordpress.env file, creating kubernetes secret: wordpress-credentials"

source ./wordpress.env

kubectl create secret generic wordpress-credentials \
  --from-literal=WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST} \
  --from-literal=WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME} \
  --from-literal=WORDPRESS_DB_USER=${WORDPRESS_DB_USER} \
  --from-literal=WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD}


