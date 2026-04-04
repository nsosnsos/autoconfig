#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
source ${SCRIPT_PATH}/../logging.sh

### Check script parameters
if [[ ${#} == 1 && ${1} == "install" ]]; then
    if type mariadb > /dev/null 2>&1 ; then
        log_info "mariadb is already installed"
        exit 0
    fi
elif [[ ${#} == 1 && ${1} == "uninstall" ]]; then
    if type mariadb > /dev/null 2>&1 ; then
        log_info "uninstalling mariadb..."
        echo "mariadb-server/postrm_remove_databases boolean true" | sudo debconf-set-selections
        log_exec "sudo DEBIAN_FRONTEND=noninteractive apt purge mysql-* -y"
        log_exec "sudo DEBIAN_FRONTEND=noninteractive apt purge mariadb-* -y"
        log_exec "sudo apt autoremove -y"
        exit 0
    else
        log_info "mariadb is not installed yet"
        exit 0
    fi
else
    log_error "Usage: ${SCRIPT_NAME} install/uninstall"
    exit 1
fi

read -s -p "Enter MariaDB root password: " ROOT_PWD
echo
read -p "Enter MariaDB new user's username: " MARIADB_USR
read -s -p "Enter MariaDB new user's password: " MARIADB_PWD
echo

### Install mariadb-server
log_info "installing mariadb..."
log_exec "sudo apt install mariadb-server -y"

### Config mariadb-server
log_info "configuring mariadb..."
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
log_debug "Creating MariaDB user..."
sudo mariadb -u root -p'${ROOT_PWD}' -e "DROP USER IF EXISTS '${MARIADB_USR}'@'localhost'"
sudo mariadb -u root -p'${ROOT_PWD}' -e "FLUSH PRIVILEGES"
sudo mariadb -u root -p'${ROOT_PWD}' -e "CREATE USER '${MARIADB_USR}'@'localhost' IDENTIFIED BY '${MARIADB_PWD}'"
sudo mariadb -u root -p'${ROOT_PWD}' -e "GRANT ALL PRIVILEGES on *.* TO '${MARIADB_USR}'@'localhost'"

# Make our changes take effect
log_debug "Flushing privileges..."
sudo mariadb -u root -p'${ROOT_PWD}' -e "FLUSH PRIVILEGES"

log_info "Restarting mariadb service..."
log_exec "sudo systemctl restart mariadb"
log_info "MariaDB installation completed successfully"

