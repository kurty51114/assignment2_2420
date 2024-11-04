#!/bin/bash

# Function used to display usage of this script in the getopts loop below
usage() {
    echo "Usage: $0 -f <package-list-file>"
    exit 1
}

# Using getopts to provide option for file, otherwise print error message
while getopts ":f:" opt; do
    case "$opt" in
        f) package_file="$OPTARG" 
          ;;
        :) usage
          ;;
        *) usage 
           exit 1 
          ;;
    esac
done

# Check if the file exists and is readable - https://askubuntu.com/questions/558977/checking-for-a-file-and-whether-it-is-readable-and-writable
if [[ ! -f "$package_file" || ! -r "$package_file" ]]; then
    echo "Error: File '$package_file' does not exist or is not readable."
    exit 1
fi

# Install packages using pacman - https://unix.stackexchange.com/questions/274396/how-do-you-make-a-list-file-for-pacman-to-install-from
if ! sudo pacman -S --noconfirm - < "$package_file"; then
    echo "A problem occurred during install. Some packages might not have been installed."
    exit 1
fi

echo "Packages in list have been installed."
