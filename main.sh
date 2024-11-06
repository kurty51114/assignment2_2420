#!/bin/bash

# variable storing default file name storing packages for installation
PACKAGE_FILE="list"

# variable storing an array to be used to hold the names of all the packages requested to be installed, which already includes tmux and kakoune which are used in the setup/config
packages=("tmux" "kakoune")

# function to show the usage of the script with option descriptions
usage() {
    echo "Usage: $0 [-p package1 package2 ...] [-s]"
    echo "Options:"
    echo "  -p  option to enter names of packages for installation. If entering multiple packages, separate by spaces."
    echo "  -s  Run the symbolic link setup script [config-setup.sh]."
    exit 1
}

# process options shown in usage function - p and s
while getopts ":p:s" opt; do
    case ${opt} in
        p)
            # shifts the positional arguments with the option -p to remove it - purpose is to add the remaining arguments to the packages array - https://www.geeksforgeeks.org/shift-command-in-linux-with-examples/
            shift
            # append all the rest of the arguments to the list of packages array
            packages+=("$@")
            ;;
        s)
            # run the symbolic link setup script + handle any errors
            ./symlink_configs.sh
            if [ $? -ne 0 ]; then
                echo "Error: Failed to run symlink_configs.sh"
                exit 1
            fi
            ;;
        \?)
            # option if the option provided is not listed above
            echo "Error: Invalid option -$OPTARG" >&2
            usage
            ;;
    esac
done

# shift the OPTIND variable so that it will be used properly in the following step to write the package list to a file
shift $((OPTIND -1)
   
# clear any previous packages file that may have been created if the script was run before
rm -f "$PACKAGE_FILE"
# iterate through all of the array items in packages and appending them to the list of packages file
for package in "${packages[@]}"; do
    echo "$package" >> "$PACKAGE_FILE"
done

# run pacinstall.sh with the generated package list file
./pacinstall.sh -f "$PACKAGE_FILE"
    
# error checking whether the command ran properly  - https://askubuntu.com/questions/29370/how-to-check-if-a-command-succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to run pacinstall.sh"
    exit 1
fi

echo "All requested operations completed successfully."
