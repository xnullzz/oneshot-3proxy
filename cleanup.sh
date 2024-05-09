#!/bin/bash

if [ -f ./.env ]; then
    source ./.env
    if [ -n "$CONTAINER_ID" ]; then
        if docker ps -a --format "{{.ID}}" | grep -q "$CONTAINER_ID"; then
            echo "Stopping and removing container with ID: $CONTAINER_ID"
            docker stop $CONTAINER_ID > /dev/null
            docker rm $CONTAINER_ID > /dev/null
            echo "Container removed successfully."
	    echo "Removing 3proxy.cfg and .env files"
	    rm -rfv {3proxy.cfg,.env}
        else
            echo "Container with ID $CONTAINER_ID not found."
        fi
    else
        echo "Container ID not found in .env file."
    fi
else
    echo ".env file not found."
fi

