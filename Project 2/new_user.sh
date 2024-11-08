#!/bin/bash

# Function to create a new group (same name as user)
createGroup() {
    local username="$1" # Takes username as a parameter, will be fetched from addUser function
    local gid="$2"  # Takes gid as a parameter, will be fetched from addUser function

    # Check if the group already exists in the group file - grep syntax from https://unix.stackexchange.com/questions/65263/getting-a-list-of-users-by-grepping-etc-passwd, -q to avoid all the extra text when running grep
    if grep -q "^$username:" /etc/group; then
        echo "Group $username already exists."
        return 1
    fi

    # Create group entry in /etc/group - format taken from group file "username:x:$gid:", using concatenate expression from lecture
    echo "$username:x:$gid:" >> /etc/group

    # Create group entry in /etc/gshadow - https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/4/html/introduction_to_system_administration/s3-acctsgrps-gshadow#s3-acctsgrps-gshadow, using concatenate expression from lecture
    echo "$username:!:$(date +%s)::" >> /etc/gshadow

    # Verify the group was created successfully - using grep to check whether the entries exist in both /etc/group and /etc/gshadow, else print an error message
    if grep -q "^$username:" /etc/group && grep -q "^$username:" /etc/gshadow; then
        echo "Group $username created successfully."
    else
        echo "Error: Failed to create group $username."
        return 1
    fi
}

# Function to initialize the user's home directory - copies the contents of skel to the home directory
home_init() {
    local username="$1"

    # Copy the contents of /etc/skel to the new user's home directory - if the skel directory exists, then use "cp" to copy all the contents recursively from the skel directory into the home directory of the user
    if [ -d /etc/skel ]; then
        cp -r /etc/skel/* "/home/$username/"
        chown -R "$username:$username" "/home/$username" # set the permissions for home directory and all subsequent files and directories to the newly created user and its matched group
        echo "Home directory for $username initialized with /etc/skel."
    else
        echo "Error: /etc/skel directory does not exist." # else, print an error message
        return 1
    fi
}

# Function to create a new user
addUser() {
    local username="$1"
    local shell="$2"
    local additional_groups="$3"  # Accept additional groups

    # Check if user already exists using same grep test as above
    if grep -q "^$username:" /etc/passwd; then
        echo "User $username already exists."
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
    createGroup "$username" "$gid"

    # Create home directory for the user
    mkdir -p "/home/$username"

    # Create user entry in /etc/passwd with the same GID as the group - matching the values entered or created in the format taken from the passwd file, and concatenated to the passwd file in etc
    echo "$username:x:$uid:$gid::/home/$username:$shell" >> /etc/passwd

    # Initialize home directory with /etc/skel contents with the function created above
    home_init "$username"

    # Add user to additional groups (if any provided)
    if [ -n "$additional_groups" ]; then
        for group in $additional_groups; do
            # Ensure the group exists before assigning, else return an error
            if grep -q "^$group:" /etc/group; then
                usermod -aG "$group" "$username"  # Add user to the group - to be changed
                echo "Added $username to group $group."
            else
                echo "Error: Group $group does not exist."
                exit 1
            fi
        done
    fi
    echo "User $username created successfully with primary group $username."
}

# Function to handle options and their arguments
provideOptions() {
    # Default values are set to 
    local username=""
    local shell="/bin/bash"
    local additional_groups=""

    # using getopts to parse the command-line options
    while getopts ":u:s:g:" opt; do
        case $opt in
            u) username="$OPTARG" 
              ;;
            s) shell="$OPTARG" 
              ;;
            g) additional_groups="$OPTARG" 
              ;;
            :) echo "Usage: $0 -u username -s shell -g additional_groups"
              ;;
            \?) echo "Usage: $0 -u username -s shell -g additional_groups"
                exit 1 ;;
        esac
    done

    # Check if username is provided - -z checks whether the variable username has a value
    if [ -z "$username" ]; then
        echo "Error: Username is required."
        exit 1
    fi

    # Call addUser function with each of the arguments filled into their respective variables 
    addUser "$username" "$shell" "$additional_groups"
}

# run the provideOptions function to execute the functions of the script
provideOptions "$@"
