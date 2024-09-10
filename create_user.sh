#!/bin/bash

# Script for managing users in a 3proxy Docker container

CONTAINER_NAME="3proxy_temp"  # Name of your 3proxy container
CONFIG_FILE="3proxy.cfg"      # Path to the 3proxy configuration file

# Function to check if the container is running
check_container_running() {
  if [[ "$(docker inspect -f '{{.State.Running}}' $CONTAINER_NAME 2>/dev/null)" != "true" ]]; then
    echo "Error: Container '$CONTAINER_NAME' is not running."
    exit 1
  fi
}

# Function to generate a random username
generate_random_username() {
  openssl rand -hex 4
}

# Function to generate a random password
generate_random_password() {
  openssl rand -hex 8
}

# Function to add a random user to the end of the users list
add_random_user() {
  check_container_running

  USERNAME=$(generate_random_username)
  PASSWORD=$(generate_random_password)

  # Find the line containing "log /dev/stdout" and insert the new user before it
  sed -i "/log \/dev\/stdout/i users $USERNAME:CL:$PASSWORD" "$CONFIG_FILE" 

  # Restart the container
  docker restart $CONTAINER_NAME

  echo "Random user added successfully:"
  echo "Username: $USERNAME"
  echo "Password: $PASSWORD"
}

# Function to remove a user
remove_user() {
  if [[ -z "$1" ]]; then
    echo "Usage: remove_user <username>"
    return 1
  fi

  USERNAME="$1"

  check_container_running

  # Check if the user exists
  if ! grep -q "^users $USERNAME:" "$CONFIG_FILE"; then
    echo "Error: User '$USERNAME' does not exist."
    return 1
  fi

  # Remove the user from the configuration file
  sed -i "/^users $USERNAME:/d" "$CONFIG_FILE"

  # Restart the container
  docker restart $CONTAINER_NAME

  echo "User '$USERNAME' removed successfully."
}

# Function to list users
list_users() {
  check_container_running

  # Extract and display usernames from the configuration file
  grep "^users " "$CONFIG_FILE" | cut -d ":" -f 2 | awk '{print $1}'
}

# Main script logic
case "$1" in
  add_random_user)
    add_random_user
    ;;
  remove_user)
    shift
    remove_user "$@"
    ;;
  list_users)
    list_users
    ;;
  *)
    echo "Usage: $0 {add_random_user|remove_user|list_users} [arguments]"
    exit 1
    ;;
esac
