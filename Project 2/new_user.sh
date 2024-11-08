#!/bin/bash

# Check if the script is run as root - using EUID to check if the script is run as root, if not, print an error message
if [[ $EUID -ne 0 ]]; then
    echo "error: script not run using sudo (or as root user)"
    exit 1
fi

# Function to create a new group (same name as user)
createUserGroup() {
    local username="$1" # Takes username as a parameter, will be fetched from addUser function
    local gid="$2"  # Takes gid as a parameter, will be fetched from addUser function

# Check if the group already exists in the group file - grep syntax from https://unix.stackexchange.com/questions/65263/getting-a-list-of-users-by-grepping-etc-passwd, -q to avoid all the extra text when running grep
    if grep -q "^$username:" /etc/group; then
        echo "Group $username already exists."
        return 1
    fi

    # Create group entry in /etc/group - format taken from group file "username:x:$gid:", using concatenate expression from lecture
    echo "$username:x:$gid:$username" >> /etc/group

    # Verify the group was created successfully - using grep to check whether the entries exist in both /etc/group and /etc/gshadow, else print an error message
    if grep -q "^$username:" /etc/group; then
        echo "Group $username created successfully."
    else
        echo "Error: Failed to create group $username."
        return 1
    fi
}

# Function to create a new group that doesn't have the same name as the user
createNewGroup() {
  local groupName=$1 # groupname variable initialized to take the first argument to the function
  
  # creates new gid greater than the largest gid (in the 1000s range) currently in the /etc/group file - taken from https://www.kevinguay.com/posts/next-uid-gid/, explanation in addUser function
  local gid=$(cat /etc/group | cut -d ":" -f 3 | grep "^1...$" | sort -n | tail -n 1 | awk '{ print $1+1 }')

  # Create new group entry in /etc/group - format taken from lecture concatenation expression
  echo "$groupName:x:$gid:" >> /etc/group

  # Verify that the group was created successfully - same format as the addUserGroup function's check
  if grep -q "^$groupName:" /etc/group; then
    echo "Group $groupName created successfully."
  else
    echo "Error: Failed to create group $groupName."
    return 1
  fi
}
# Function that adds a user to a specified group
addUserToGroup() {
  local groupName=$1 # groupname variable initalizaed to take first argument to the function
  local username=$2 # username variable initlialized to take the second argument to the function

  # initialize the group variable by assigning the line of the group that the user intends to add their username to
  local group=$(grep "^$groupName:" /etc/group)
  
  # checking whether or not the last character of the group is a colon (indicating no other users in group)
  if [[ $group =~ :$ ]]; then
    # If there are no existing users in the group (check end of the line, add username with a comma to separate from other users- https://askubuntu.com/questions/1446406/end-of-line-in-sed-command#:~:text=The%20easiest%20in%20this%20case,character%2C%20meaning%20end%20of%20line
    sed -i "/^$groupName:/ s/$/$username/" /etc/group
  else
    # If existing users, add username with a comma
    sed -i "/^$groupName:/ s/$/,$username/" /etc/group
  fi
}

# Function to initialize the user's home directory - copies the contents of skel to the home directory
home_init() {
    local username="$1" # initialize the username variable taking the first argument to the function

    # Copy the contents of /etc/skel to the new user's home directory - if the skel directory exists, then use "cp" to copy all the contents recursively from the skel directory into the home directory of the user
    if [[ -d /etc/skel ]]; then
        cp -r /etc/skel/. "/home/$username/"
        chown -R "$username:$username" "/home/$username" # set the permissions for home directory and all subsequent files and directories to the newly created user and its matched group
        echo "Home directory for $username initialized with /etc/skel."
    else
        echo "Error: /etc/skel directory does not exist." # else, print an error message
        return 1
    fi
}

# Function to set the password for the user
setPasswd() {
  # default boolean assignment to use with the loop
  passwordSet=False

  # loop to check whether the password was set correctly. if the exit code of the passwd command does not equal 0, then the password is set incorrectly, so the user has to retry until they set it properly.
  while [[ $passwordSet == False ]]; do
    passwd ${password} # runs the password builtin utility
    if [[ $? -ne 0 ]]; then # checks the exit status
      echo "Failed to set password, incorrect entry. Please try again." # prints error message if doesn't pass check
    else
      passwordSet=True # reassign boolean placeholder to get out of the while loop
    fi
  done
}

# Function to create a new user, set gid, uid and edit necessary files by calling other functions
addUser() {
    local username="$1" # initialize the username variable - takes first argument to the addUser function
    local shell="$2" # initialize the shell variable - takes second argument to the addUser function
    local additional_groups="$3"  # Accept additional groups

    # Check if user already exists using same grep test as above
    if grep -q "^${username}:" /etc/passwd; then
        echo "User ${username} already exists."
        return 1
    fi

    # Very complicated pipeline, taken from https://www.kevinguay.com/posts/next-uid-gid/ but used for finding the next available UID (starting from 1000 for regular users)
    # to break down the pipeline:
    # cat /etc/passwd /etc/group - outputs the contents of both passwd and group files in etc to stdout
    # cut -d ":" -f 3 - from each line, only the third entry is extracted which is the uid in passwd and gid in group
    # grep -E "^1...$" - applies a filter using grep that looks for exactly the values with 4 digits long and start with the number 1 (to get uids in the 1000s)
    # sort -n - sorts the values numerically increasing
    # tail -n 1 - takes the highest value of all of the sorted numbers
    # awk '{ print $1+1}' - returns the highest value and adds 1 to it for the next available unique uid value
    local uid=$(cat /etc/passwd /etc/group | cut -d ":" -f 3 | grep "^1...$" | sort -n | tail -n 1 | awk '{ print $1+1 }')

    # sets the gid to the same as the uid (just to match). This works because we used the previous command to find the highest value of both uid and gid even compared to each other, thus ensuring it is a unique value for both the gid and uid.
    local gid=$uid

    # Create the group first with the same GID using the function created above
    createUserGroup "$username" "$gid"

    # Create home directory for the user
    mkdir -p "/home/$username"

    # Create user entry in /etc/passwd with the same GID as the group - matching the values entered or created in the format taken from the passwd file, and concatenated to the passwd file in etc
    echo "${username}:x:${uid}:${gid}::/home/${username}:${shell}" >> /etc/passwd

    # Initialize home directory with /etc/skel contents with the function created above
    home_init "$username"

    # Add user to additional groups (if any provided)
    if [ -n "$additional_groups" ]; then
        # iterate over the string of additional groups separated by spaces - https://stackoverflow.com/questions/25870689/simple-unix-way-of-looping-through-space-delimited-strings
        for group in ${additional_groups}; do
            # Ensure the group exists before assigning, else return an error
            if grep -q "^${group}:" /etc/group; then
              addUserToGroup ${group} ${username}
              echo "Added ${username} to group ${group}."
            else
              # if the group does not exist, print error message, and ask user whether they want to create the new group
                echo "Error: Group ${group} does not exist."
                read -p "Create group? (Y/N)" answer
                # if the input is y or Y, creates new group and adds the user to the group with the functions created
                if [[ ${answer} == Y || ${answer} == y ]]; then
                  createNewGroup ${group}
                  addUserToGroup ${group} ${username}
                  # if the input is N or n, exits
                elif [[ ${answer} == N || ${answer} == n ]]; then
                  exit 1
                else
                  # if the input is neither option, exits and the user has to redo the group
                  echo "invalid entry. please try again."
                  exit 1
                fi
            fi
        done
    fi
    echo "User ${username} created successfully with primary group ${username}."
}

# Function to handle options and their arguments
provideOptions() {
    # Default values are initialized for username and shell. 
    local username=""
    local shell="/bin/bash"
    local additional_groups=""

    # using getopts to parse the command-line options
    while getopts ":u:s:g:" opt; do
        case $opt in
            u) 
              # this option sets username as the argument to the option u
              username="$OPTARG"
              ;;
            s)
              # this option checks if the argument passed to this option is a valid shell, if not, exits
              if grep -q -x ${OPTARG} /etc/shells; then
                shell="$OPTARG"
              else
                echo "Error: not a valid shell"
                exit 1
              fi
              ;;
            g) 
              # this options sets the additional groups as the argument(s) to the option g
              additional_groups="$OPTARG" 
              ;;
            :) echo "Usage: $0 [-u username] [-s shell (full path)] [-g additional_groups]"
              ;;
            \?) echo "Usage: $0 [-u username] [-s shell (full path)] [-g additional_groups]"
                exit 1
              ;;
        esac
    done

    # Check if username is provided - -z checks whether the variable username has a value
    if [ -z "$username" ]; then
        echo "Error: Username is required."
        echo "Usage: $0 [-u username] [-s shell (full path)] [-g additional_groups]"
        exit 1
    fi

    # Call addUser function with each of the arguments filled into their respective variables 
    addUser "$username" "$shell" "$additional_groups"
}

# run the provideOptions function to execute the functions of the script
provideOptions "$@"
