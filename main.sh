#!/bin/bash

# Default name for file storing the package list - will be able to take the filename as an argument later on (assumes that there already is a packages.txt file that exists in the same directory as this script)
PACKAGE_FILE="packages.txt"

# Default list of packages (to be used to reset the default packages file if more packages are added to it by the user to be installed)
packages=("tmux" "kakoune")

# Function to show script usage - first line displays the format of the command, then the subsequent lines show the options available, whether it be running the package installer with package file or symbolic link script
usage() {
    echo "Usage: $0 [-f package_file] [-s]"
    echo "Options:"
    echo "  -f  Specify a file containing the list of packages to install (one package per line). "
    echo "  -s  Run the symbolic link setup script."
    exit 1
}

# Process options - three possible options, 1 being no options selected (shows usage with usage function), f being the package file with the file name, s being the symbolic link script, and error handling with any other option inputs
while getopts ":f:s" opt; do
    case ${opt} in
        f)
          # Set the specified package file to PACKAGE_FILE
          PACKAGE_FILE="$OPTARG"
          # Ensure the specified package file exists, else print out an error message and create the new file
          if [ ! -f "$PACKAGE_FILE" ]; then        
            echo "No specified package list $PACKAGE_FILE installed. Installing default packages."
          else
            # Add the contents of the specified package file to the packages.txt file
            cat "$PACKAGE_FILE" >> packages.txt
                
            # Add default packages from the packages array, appending each package to a new packages.txt file - this will be used to install the default packages if the user has added more packages to the package file
            for package in "${packages[@]}"; do
              echo "$package" >> packages.txt
            done
          fi

          # Run pacinstall.sh with the generated package list file
          ./pacinstall.sh -f packages.txt

          # Check for errors in running pacinstall.sh - $? is a special variable that holds the exit status of the last command run, -ne compares the exit status to 0 (0 being successful, any other number being an error)
          if [ $? -ne 0 ]; then
            echo "Error: Failed to run pacinstall.sh"
            exit 1
          fi

          # Clean up the temporary package list - remove the packages.txt file
          rm packages.txt
          echo "All requested operations completed successfully.";;
        s)
          # Run the symbolic link setup script and check for errors by using the $? variable to check the exit status of the last command run, and -ne to compare the exit status to 0 (0 being successful, any other number being an error). if an error is found, print out an error message and exit the script
          ./config-setup.sh
          if [ $? -ne 0 ]; then
            echo "Error: Failed to run config-setup.sh"
            exit 1
          fi
          ;;
        \?)
          echo "Error: Invalid option -$OPTARG"
          usage
          ;;
    esac
done
if [[ $OPTIND -eq 1 || $OPTIND -eq 2 ]]; then
  usage
fi
