#!/usr/bin/env bash
set -x
set -e

HOME_PATH=$(eval echo ~${SUDO_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))

### Check script parameters
if [[ ${#} -ne 1 && ${#} -ne 3 ]]; then
    echo "Error parameters !!!"
    echo "Usage ${SCRIPT_NAME}: ROOT_PWD MARIADB_USR MARIADB_PWD"
    exit -1
elif type mysql > /dev/null 2>&1 ; then
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


### Install mariadb-server
sudo apt install mariadb-server -y

### Config mariadb-server
# Make sure that NOBODY can access the server without a password
sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('${1}') WHERE User = 'root'"
# Delete the anonymous users
sudo mysql -u root -p'${1}' -e "DELETE FROM mysql.user WHERE User=''"
# Because our hostname varies we'll use some Bash magic here
sudo mysql -u root -p'${1}' -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
# Delete the demo database
sudo mysql -u root -p'${1}' -e "DROP DATABASE IF EXISTS test"
sudo mysql -u root -p'${1}' -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"

if [ ${#} == 3 ]; then
    # Add specific user.
    sudo mysql -u root -p'${1}' -e "CREATE USER '${2}'@'localhost' IDENTIFIED BY '${3}'"
    sudo mysql -u root -p'${1}' -e "GRANT ALL PRIVILEGES on *.* TO '${2}'@'localhost'"
fi

# Make our changes take effect
sudo mysql -u root -p'${1}' -e "FLUSH PRIVILEGES"

sudo systemctl restart mariadb

