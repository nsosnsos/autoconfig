#!/usr/bin/env bash
#set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

### Check script parameters
if [[ ${#} -ne 1 && ${#} -ne 0 ]]; then
    echo "Error parameters !!!"
    echo "Usage ${SCRIPT_NAME} [uninstall]"
    exit -1
elif type mariadb > /dev/null 2>&1 ; then
    if [[ ${#} -eq 1 && "${1}" == "uninstall" ]]; then
        sudo apt remove -y mariadb-server
        sudo apt autoremove -y
    else
        echo "MariaDB is already installed, and it would not be configured again."
    fi
    exit 0
elif [[ ${#} -eq 1 && "${1}" == "uninstall" ]]; then
    echo "MariaDB has not been installed yet."
    exit -1
fi

read -p "Enter MariaDB root password: " ROOT_PWD
read -p "Enter MariaDB new user's username: " MARIADB_USR
read -p "Enter MariaDB new user's password: " MARIADB_PWD

### Install mariadb-server
sudo apt install mariadb-server -y

### Config mariadb-server
# initialize mariadb
echo "
y
y
${ROOT_PWD}
${ROOT_PWD}
y
y
y
y" | sudo /usr/bin/mariadb-secure-installation

if [ ${#} == 3 ]; then
    # Add specific user.
    sudo mariadb -u root -p'${ROOT_PWD}' -e "DROP USER '${MARIADB_USR}'@'localhost'"
    sudo mariadb -u root -p'${ROOT_PWD}' -e "FLUSH PRIVILEGES"
    sudo mariadb -u root -p'${ROOT_PWD}' -e "CREATE USER '${MARIADB_USR}'@'localhost' IDENTIFIED BY '${MARIADB_PWD}'"
    sudo mariadb -u root -p'${ROOT_PWD}' -e "GRANT ALL PRIVILEGES on *.* TO '${MARIADB_USR}'@'localhost'"
fi

# Make our changes take effect
sudo mariadb -u root -p'${ROOT_PWD}' -e "FLUSH PRIVILEGES"

sudo systemctl restart mariadb

