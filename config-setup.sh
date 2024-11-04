#!/bin/bash

# Check if cloned directories exist
if [[ ! -d ./bin ]]; then  # Check for the bin directory
    echo "Error: ./bin directory does not exist."
    exit 1
fi

if [[ ! -d ./.config/kak ]]; then  # Check for the kak directory
    echo "Error: ./.config/kak directory does not exist."
    exit 1
fi

if [[ ! -d ./.config/tmux ]]; then  # Check for the tmux directory
    echo "Error: ./.config/tmux directory does not exist."
    exit 1
fi

# Note: if there were an error with any of the previous directories, the file tree system must be fully reviewed, as there could be issues with either the nested directory, the parent directory, or both.

# Check if required files exist by creating a list of the file paths, then using a for loop to iterate through each file and checking for its existence in the right location
required_files=(
    "./bin/sayhi"
    "./bin/install-fonts"
    "./config/kak/kakrc"
    "./config/tmux/tmux.conf"
    "./home/bashrc"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: Required file $file does not exist."
        exit 1
    fi
done

# Generalized function to create a symbolic that takes two inputs: the source and the destination - creates a symbolic link and handles errors
create_symlink() {
    src=$1
    dest=$2
    dest_dir=$(dirname "$dest")

    if [[ ln -s "$src" "$dest" ]]; then
        echo "Linked $src to $dest"
    elif [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
        echo "Destination folder not created by default, created directory $dest_dir."
    else
        echo "Error: Failed to link $src to $dest"
        exit 1
    fi
}

# Symbolic links for bin scripts
create_symlink "./bin/sayhi" ~/bin/sayhi
create_symlink "./bin/install-fonts" ~/bin/install-fonts

# Symbolic links for files in .config
create_symlink "./config/kak/kakrc" ~/.config/kak/kakrc
create_symlink "./config/tmux/tmux.conf" ~/.config/tmux/tmux.conf

# Symbolic link for bashrc
create_symlink "./home/bashrc" ~/.bashrc

echo "All symbolic links have been created successfully."
