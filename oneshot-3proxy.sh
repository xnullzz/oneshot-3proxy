#!/bin/bash

CONTAINER_NAME="3proxy_temp"
USERNAME=$(openssl rand -hex 4)
PASSWORD=$(openssl rand -hex 8)
PORT="3128"

TEMP_CREDS=$(openssl rand -base64 12)

cat << EOF > 3proxy.cfg
proxy -n -p$PORT -a

auth strong
users $USERNAME:CL:$PASSWORD

log /dev/stdout
logformat "%t %r %b %T"
EOF

docker run -d -p $PORT:$PORT --name $CONTAINER_NAME -v $(pwd)/3proxy.cfg:/etc/3proxy/3proxy.cfg 3proxy

CONTAINER_ID=$(docker inspect --format='{{.Id}}' $CONTAINER_NAME | cut -c1-12)

echo "CONTAINER_ID=$CONTAINER_ID" > .env

echo "Temporary credentials for accessing the proxy server:"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "Please note that these credentials will only be valid until the Docker container is stopped."
