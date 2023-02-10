#!/usr/bin/env bash
#set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

### Check script parameters
if [[ ${#} == 1 && ${1} == "install" ]]; then
    if type mariadb > /dev/null 2>&1 ; then
        echo "mariadb is already installed !!!"
        exit 0
    fi
elif [[ ${#} == 1 && ${1} == "uninstall" ]]; then
    if type mariadb > /dev/null 2>&1 ; then
        echo "uninstalling mariadb ... !!!"
        sudo apt purge mysql-* -y
        sudo apt purge mariadb-* -y
        sudo apt autoremove -y
        exit 0
    else
        echo "mariadb is not installed yet !!!"
        exit 0
    fi
else
    echo "Usage: ${SCRIPT_NAME} install/uninstall"
    exit -1
fi

read -p "Enter MariaDB root password: " ROOT_PWD
read -p "Enter MariaDB new user's username: " MARIADB_USR
read -p "Enter MariaDB new user's password: " MARIADB_PWD

### Install mariadb-server
echo "installing mariadb ..."
sudo apt install mariadb-server -y

### Config mariadb-server
echo "configuring mariadb ..."
echo "
y
y
${ROOT_PWD}
${ROOT_PWD}
y
y
y
y" | sudo /usr/bin/mariadb-secure-installation

# Add specific user.
sudo mariadb -u root -p'${ROOT_PWD}' -e "DROP USER IF EXISTS '${MARIADB_USR}'@'localhost'"
sudo mariadb -u root -p'${ROOT_PWD}' -e "FLUSH PRIVILEGES"
sudo mariadb -u root -p'${ROOT_PWD}' -e "CREATE USER '${MARIADB_USR}'@'localhost' IDENTIFIED BY '${MARIADB_PWD}'"
sudo mariadb -u root -p'${ROOT_PWD}' -e "GRANT ALL PRIVILEGES on *.* TO '${MARIADB_USR}'@'localhost'"

# Make our changes take effect
sudo mariadb -u root -p'${ROOT_PWD}' -e "FLUSH PRIVILEGES"

sudo systemctl restart mariadb

