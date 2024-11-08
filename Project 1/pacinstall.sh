#!/bin/bash

# Function used to display usage of this script in the getopts loop below - following format of https://stackoverflow.com/questions/9725675/is-there-a-standard-format-for-command-line-shell-help-text
usage() {
    echo "Usage: $0 [-f package-list-file]"
    exit 1
}

# Using getopts to provide option for file, otherwise print error message. takes f option with the argument being the name of the package file. The other options provided are for error handling, and would only run if the script was run standalone and the user input was incorrect. it will always run properly if using the main.sh file.
while getopts ":f:" opt; do
    case "$opt" in
        f) package_file="$OPTARG" 
          ;;
        :) usage
          exit 1
          ;;
        *) usage 
           exit 1 
          ;;
    esac
done

# Check if the file exists and is readable - https://askubuntu.com/questions/558977/checking-for-a-file-and-whether-it-is-readable-and-writable, prints an error message if any issues occurred
if [[ ! -f "$package_file" || ! -r "$package_file" ]]; then
    echo "Error: File '$package_file' does not exist or is not readable."
    exit 1
fi

# Install packages using pacman - https://unix.stackexchange.com/questions/274396/how-do-you-make-a-list-file-for-pacman-to-install-from, prints error message if there were any issues
if ! sudo pacman -S --noconfirm - < "$package_file"; then
    echo "A problem occurred during install. Some packages might not have been installed."
    exit 1
fi

# Prints successful installation message
echo "Packages in list have been installed."
