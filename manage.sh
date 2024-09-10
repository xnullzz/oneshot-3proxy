#!/bin/bash

# Script for managing users in a 3proxy Docker container

CONTAINER_NAME="3proxy_temp"  # Name of your 3proxy container
CONFIG_FILE="3proxy.cfg"      # Path to the 3proxy configuration file
CHANGES_MADE="false"         # Flag to track if changes have been made

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Function to check if the container is running
check_container_running() {
  if [[ "$(docker inspect -f '{{.State.Running}}' $CONTAINER_NAME 2>/dev/null)" != "true" ]]; then
    echo -e "${RED}Error: Container '$CONTAINER_NAME' is not running.${NC}"
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

  echo -e "${GREEN}User added successfully:${NC}"
  echo -e "${BLUE}Username: $USERNAME${NC}"
  echo -e "${BLUE}Password: $PASSWORD${NC}"
}

# Function to list configuration details
list_config() {
  check_container_running

  echo -e "${YELLOW}Users:${NC}"
  grep "^users " "$CONFIG_FILE" | awk '{print $2}' | cut -d ":" -f 1,3 | sed 's/:/ \/ /' # user / pass format

  PORT=$(grep "^proxy -n -p" "$CONFIG_FILE" | awk '{print $3}' | cut -c3-)
  echo -e "${YELLOW}Port: $PORT${NC}"

  NUM_USERS=$(grep "^users " "$CONFIG_FILE" | wc -l)
  echo -e "${YELLOW}Number of users: $NUM_USERS${NC}"
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
    echo -e "${RED}No users found to remove.${NC}"
    return
  fi

  echo -e "${YELLOW}Which user you want to remove?${NC}"
  for i in "${!USERS[@]}"; do
    echo "$((i+1)). ${USERS[i]}"
  done

  read -p "Enter the user number to remove: " USER_NUM

  if [[ ! $USER_NUM =~ ^[0-9]+$ ]] || [[ $USER_NUM -lt 1 ]] || [[ $USER_NUM -gt $NUM_USERS ]]; then
    echo -e "${RED}Invalid user number.${NC}"
    return
  fi

  USER_TO_REMOVE=$(echo "${USERS[$((USER_NUM-1))]}" | cut -d " " -f 1)
  sed -i "/^users $USER_TO_REMOVE:/d" "$CONFIG_FILE"

  echo -e "${GREEN}User '$USER_TO_REMOVE' removed successfully.${NC}"
}

# Function to commit changes (restart container)
commit_changes() {
  check_container_running
  docker restart $CONTAINER_NAME
  CHANGES_MADE="false"
  echo -e "${GREEN}Changes committed successfully.${NC}"
}

# Function to display the menu (modified)
display_menu() {
  if [[ "$FIRST_RUN" == "true" ]]; then
    echo -e "${GREEN}Hi there! This is oneshot_3proxy management system. What would you like to do?${NC}"
    FIRST_RUN="false" 
  else
    echo -e "${YELLOW}Anything else you want to do?${NC}"
  fi
  echo "1. Add user"
  echo "2. Remove user"
  echo "3. List config"
  echo "4. Commit changes"
  echo "5. Exit"
}

# Main script logic (menu loop)
FIRST_RUN="true" # Flag for the initial menu display
while true; do
  display_menu
  read -p "Enter your choice: " CHOICE

  case "$CHOICE" in
    1)
      add_user
      CHANGES_MADE="true"
      ;;
    2)
      remove_user
      CHANGES_MADE="true"
      ;;
    3)
      list_config
      ;;
    4)
      commit_changes
      ;;
    5)
      if [[ "$CHANGES_MADE" == "true" ]]; then
        read -p "$(echo -e "${RED}You have uncommitted changes. Commit before exiting? (y/n): ${NC}")" COMMIT_CHOICE
	if [[ "$COMMIT_CHOICE" == "y" ]]; then
          commit_changes
        fi
      fi
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Please try again.${NC}"
      ;;
  esac
done
