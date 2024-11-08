# assignment2_2420

## Introduction

This repository contains the scripts and configuration files for Assignment 2 for ACIT 2420, designed to automate the process of setting up a Linux (Arch repo) system with user-defined packages and configuration files.

## Description

The repository consists of multiple scripts that facilitate the installation of packages and setup of configuration files for various aspects of setup. It includes two main components:

1. **Project 1: Configuration Scripts** - Automates the installation of packages and the setup of symbolic links for configuration files.
2. **Project 2: New User Script** - Creates a new user, sets their shell, home directory, and adds them to appropriate groups.


## Assignment Breakdown

### Project 1: Configuration Scripts

This part of the assignment focuses on automating the setup of software by creating configuration scripts. The following tasks are covered:

- **Package Installation**: The script installs packages from a specified list, which can be passed to `pacinstall.sh` via `main.sh`. The `pacinstall.sh` script takes care of the package installation process using `pacman`.
- **Symbolic Link Setup**: The script creates symbolic links from the configuration files provided (e.g., `bashrc`, `tmux.conf`, `kakrc`) to appropriate locations in the user's home directory, using `config-setup.sh`.

### Files

#### pacinstall.sh

This script handles the installation of packages listed in a specified file. It uses `pacman` to install packages on an Arch-based system. The script accepts the `-f` option, allowing you to specify a file containing the list of packages to install. If no file is provided, it will default to installing packages from a predefined list. The script checks for the existence of the specified package file and ensures it is readable before attempting installation.

#### main.sh

`main.sh` is the main script that orchestrates the installation and configuration setup. It accepts two options: `-f` for specifying the package list file and `-s` for running the symbolic link setup script (`config-setup.sh`). The script checks for the package file and appends additional packages if necessary, then runs the `pacinstall.sh` script to install the packages. It also invokes `config-setup.sh` to set up symbolic links for configuration files.

#### config-setup.sh

This script sets up symbolic links for the configuration files required by the assignment. It first checks if the necessary directories and files are present. It verifies that the directories `bin` and `config/kak` exist, along with the required files such as `sayhi`, `install-fonts`, `kakrc`, and `tmux.conf`. If the files are found, the script creates symbolic links in the appropriate locations, such as linking `bin` to `~/bin` and `config` to `~/.config`. The script also creates a symbolic link for the `bashrc` file to `~/.bashrc`.

---
### Project 2: New User Script

This project involves creating a script to handle the setup of a new user account. The script:

- **Creates a New User**: Defines the new user's shell, home directory, and primary group.
- **Copies Skel Files**: The script ensures that the contents of the `/etc/skel` directory are copied to the new user's home directory.
- **Sets the User Password**: A password is created for the new user using the `passwd` utility.
- **Handles Additional Groups**: If any additional groups are provided, the script ensures that the user is added to them after the account is created.

### Files

#### new_user.sh

The `new_user.sh` script automates the process of creating a new user on the system, initializing their home directory, and adding them to appropriate groups. It contains several functions:

- **createUserGroup**: This function creates a new group with the same name as the user and assigns it a unique GID. It checks if the group already exists, adding it to both the /etc/group and /etc/gshadow files. If successfully created, it returns a success message.

- **createNewGroup**: This function creates a specified group that doesn't share the same name as the user. It assigns a unique GID to the group and verifies that it was successfully created by checking /etc/group.

- **addUserToGroup**: This function adds the user to a specified group. It modifies the group entry in /etc/group, appending the user’s name. If no users are present in the group, the username is added without a comma separator.

- **home_init**: This function initializes the user's home directory by copying the contents of /etc/skel (the skeleton directory) into the new home directory. Ownership is set to the user and their primary group.

- **setPasswd**: This function sets the user's password. It prompts the user to enter the password, checking for errors, and continues until successfully set.

- **addUser**: This function creates the user entry in the /etc/passwd file with a unique UID and GID, initializes the home directory with home_init, and adds the user to any additional specified groups. It first checks if the user already exists, then determines the next available UID/GID and sets up both.

- **provideOptions**: This function parses command-line arguments passed to the script. The -u option specifies the username, -s sets the shell, and -g handles additional groups. If the username is provided, the function calls addUser to create the user with the specified settings.

## How to Use
1. Clone this repository to your home directory on linux.
2. Place your package list file (e.g., `packages.txt`) in the same directory as the scripts.
3. To install the packages, run `main.sh` with the `-f` option to specify the package list file:

   `./main.sh -f <package_list_file>`

4. To set up the symbolic links for the configuration files, run `main.sh` with the `-s` option:

   `./main.sh -s`

5. Alternatively, you can run both the package installation and configuration setup in one go by using:

   `./main.sh -f <package_list_file> -s`

6. To create a new user with `new_user.sh`, you can run the following command with the desired options:

   `./new_user.sh -u <username> -s <shell> -g <additional_groups>`


---
### Example Usage

- To install packages from `my-packages.txt` and set up the symbolic links:

  `./main.sh -f my-packages.txt -s`

- To create a new user `bobtom` with `/bin/bash` as the shell and add them to the `sudo` and `developers` groups:

  `./new_user.sh -u bobtom -s /bin/bash -g "sudo developers"`
