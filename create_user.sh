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

# Function to generate a random user suffix
generate_random_suffix() {
  openssl rand -hex 4 
}

# Function to add a user with usr0x_ prefix
add_user() {
  check_container_running

  # Get the highest existing user number
  highest_user_num=$(grep "^users usr" "$CONFIG_FILE" | awk '{print substr($2, 4, 2)}' | sort -n | tail -1)

  # Calculate the next user number
  next_user_num=$((highest_user_num + 1))

  # Pad the user number with leading zeros if needed
  printf -v USER_NUMBER "%02d" $next_user_num 

  USERNAME="usr${USER_NUMBER}_$(generate_random_suffix)"
  PASSWORD=$(openssl rand -hex 8)

  # Find the line containing "log /dev/stdout" and insert the new user before it
  sed -i "/log \/dev\/stdout/i users $USERNAME:CL:$PASSWORD" "$CONFIG_FILE"

  # Restart the container
  docker restart $CONTAINER_NAME

  echo "User added successfully:"
  echo "Username: $USERNAME"
  echo "Password: $PASSWORD"
}

# Function to list configuration details
list_config() {
  check_container_running

  echo "Users:"
  grep "^users " "$CONFIG_FILE" | awk '{print $2}' | cut -d ":" -f 1,3 | sed 's/:/ \/ /' # user / pass format

  PORT=$(grep "^proxy -n -p" "$CONFIG_FILE" | awk '{print $3}' | cut -c3-)
  echo "Port: $PORT"

  NUM_USERS=$(grep "^users " "$CONFIG_FILE" | wc -l)
  echo "Number of users: $NUM_USERS"
}

# Function to remove a user (with interactive selection)
remove_user() {
  check_container_running

  # Extract users and passwords, handling blank lines more robustly
  USERS=()  # Initialize an empty array
  while IFS= read -r line; do
    if [[ "$line" == "users "* ]]; then # Check if the line starts with "users "
      user_pass=$(echo "$line" | awk '{print $2}' | cut -d ":" -f 1,3 | sed 's/:/ \/ /')
      USERS+=("$user_pass")
    fi
  done < "$CONFIG_FILE"

  NUM_USERS=${#USERS[@]}

  if [[ $NUM_USERS -eq 0 ]]; then
    echo "No users found to remove."
    return
  fi

  echo "Which user you want to remove?"
  for i in "${!USERS[@]}"; do
    echo "$((i+1)). ${USERS[i]}"
  done

  read -p "Enter the user number to remove: " USER_NUM

  if [[ ! $USER_NUM =~ ^[0-9]+$ ]] || [[ $USER_NUM -lt 1 ]] || [[ $USER_NUM -gt $NUM_USERS ]]; then
    echo "Invalid user number."
    return
  fi

  USER_TO_REMOVE=$(echo "${USERS[$((USER_NUM-1))]}" | cut -d " " -f 1)
  sed -i "/^users $USER_TO_REMOVE:/d" "$CONFIG_FILE"

  docker restart $CONTAINER_NAME
  echo "User '$USER_TO_REMOVE' removed successfully."
}

# Main script logic
case "$1" in
  add_user)
    add_user
    ;;
  list_config)
    list_config
    ;;
  remove_user)
    remove_user
    ;;
  *)
    echo "Usage: $0 {add_user|list_config|remove_user}"
    exit 1
    ;;
esac 
