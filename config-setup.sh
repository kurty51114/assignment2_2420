#!/bin/bash

# Check if cloned directories exist
if [[ ! -d $HOME/cloned_files/bin ]]; then  # Check for the bin directory
    echo "Error: cloned bin directory does not exist."
    exit 1
fi

if [[ ! -d $HOME/cloned_files/config/kak ]]; then  # Check for the kak directory, which is nested in the .config directory (implicit check for .config directory)
    echo "Error: cloned config/kak directory does not exist."
    exit 1
fi

if [[ ! -d $HOME/cloned_files/config/tmux ]]; then  # Check for the tmux directory, which is nested in the .config directory (implicit check for .config directory)
    echo "Error: cloned config/tmux directory does not exist."
    exit 1
fi

if [[ ! -d $HOME/cloned_files/home ]]; then # Check for the home directory
    echo "Error: cloned home directory does not exist."
    exit 1
fi

# Note: if there were an error with any of the previous directories, the file tree system must be fully reviewed, as there could be issues with either the nested directory, the parent directory, or both.

# Check if required files exist by creating a list of the file paths, then using a for loop to iterate through each file and checking for its existence in the right location
required_files=(
    "$HOME/cloned_files/bin/sayhi"
    "$HOME/cloned_files/bin/install-fonts"
    "$HOME/cloned_files/config/kak/kakrc"
    "$HOME/cloned_files/config/tmux/tmux.conf"
    "$HOME/cloned_files/home/bashrc"
)

# loop through the list of required files and check if they exist
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: Required file $file does not exist."
        exit 1
    fi
done

# Generalized function to create a symbolic that takes two inputs: the source and the destination - creates a symbolic link from the source to the destination
create_symlink() {
# src: source file - first argument
  src=$1
# dest: destination file - second argument
  dest=$2

# checks to see if the destination already exists, if so, asks user to backup/remove the destination so that the symbolic link can be created
if [[ -e $dest ]]; then
  echo "$dest already exists, please delete/backup contents, remove $dest and then run the script again."
  read -r -p "remove destination? (Y/N)" response
  if [[ $response == "Y" || $response == "y" ]]; then
    rm $dest
  elif [[ $response == "N" || $respnse == "n" ]]; then
    echo "please remove $dest before running script again."
    exit 1
  else
    echo "invalid response. Please retry script."
    exit 1
  fi
fi

# Check if the symbolic link already exists - https://stackoverflow.com/questions/5767062/how-to-check-if-a-symlink-exists
  if [[ -L "$dest" ]]; then
    echo "symbolic link to $dest already exists."
# Check if the symbolic link was successfully created
  elif ln -s "$src" "$dest"; then
    echo "Linked $src to $dest."
# else, print an error message
  else
    echo "Error: Failed to link $src to $dest"
    exit 1
  fi
}


# Creating symbolic link for bin directory (sayhi, install-fonts)
create_symlink "$HOME/cloned_files/bin" "$HOME/bin" 

# Creating symbolic link for config directory (kakrc, tmux.conf)
create_symlink "$HOME/cloned_files/config" "$HOME/.config" 

# Creating symbolic link for bashrc file
create_symlink "$HOME/cloned_files/bashrc" "$HOME/.bashrc"

# Print a success message
echo "All symbolic links have been created successfully."
