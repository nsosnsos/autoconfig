#!/usr/bin/env bash
#set -x
set -e

CUR_USER=$(whoami)
HOME_PATH=$(eval echo ~${CUR_USER})
SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename $(readlink -f "${0}"))
source ${SCRIPT_PATH}/../logging.sh
CERT_PATH=${HOME_PATH}/cert
SITE_CONF_FILE=${SCRIPT_PATH}/nginx_site.conf
WEB_NAME=hallelujah
CERT=cert.pem
FULLCHAIN=fullchain.pem
PRIVKEY=privkey.pem

### Check script parameters
if [[ ${#} -eq 2 && ${1} == "install" ]]; then
    if type nginx > /dev/null 2>&1 ; then
        log_info "nginx is already installed"
        exit 0
    else
        SITE_NAME=${2}
        if [[ "${SITE_NAME}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            DOMAIN_CONFIG=0
        else
            DOMAIN_CONFIG=1
        fi
        NGINX_PATH=/etc/nginx
        WORK_DIR=workspace
        if [ ! -f ${SITE_CONF_FILE} ]; then
            log_error "There is no nginx site config file"
            exit 1
        fi
    fi
elif [[ ${#} -eq 2 && ${1} == "uninstall" ]]; then
    if type nginx > /dev/null 2>&1 ; then
        SITE_NAME=${2}
        log_info "uninstalling nginx..."
        log_exec "sudo apt purge nginx-* -y"
        log_exec "sudo apt autoremove -y"
        bash ${SCRIPT_PATH}/cert_auto.sh uninstall ${SITE_NAME}
        log_exec "sudo rm -rf ${CERT_PATH}"
        exit 0
    else
        log_info "nginx is not installed yet"
        exit 0
    fi
else
    log_error "Usage: ${SCRIPT_NAME} install/uninstall [SITE_NAME]"
    exit 1
fi

### Automated certificate generation and update
if [[ ! -d ${CERT_PATH} || ! -f ${CERT_PATH}/${SITE_NAME}.${CERT} || ! -f ${CERT_PATH}/${SITE_NAME}.${FULLCHAIN} || ! -f ${CERT_PATH}/${SITE_NAME}.${PRIVKEY} ]]; then
    log_info "Generating certificate..."
    mkdir -p ${CERT_PATH}
    if [[ ${DOMAIN_CONFIG} -eq 1 ]]; then
        bash ${SCRIPT_PATH}/cert_auto.sh install ${CERT_PATH} ${SITE_NAME}
    else
        log_debug "Generating self-signed certificate..."
        openssl req -x509 -newkey rsa:4096 -nodes -out ${CERT_PATH}/${SITE_NAME}.${FULLCHAIN} -keyout ${CERT_PATH}/${SITE_NAME}.${PRIVKEY} -days 9999 -subj "/C=US/ST=California/L=SanJose/O=Global Security/OU=IT Department/CN=test@test.com"
        cp ${CERT_PATH}/${SITE_NAME}.${FULLCHAIN} ${CERT_PATH}/${SITE_NAME}.${CERT}
    fi
fi

### Install nginx
log_info "installing nginx..."
log_exec "sudo apt install nginx -y"

### Config nginx
log_info "configuring nginx with site name: [${SITE_NAME}]"
HOST_PATH=${HOME_PATH}/${SITE_NAME}
if [ -f ${NGINX_PATH}/sites-enabled/default ]; then
    log_debug "Removing default nginx site..."
    sudo rm ${NGINX_PATH}/sites-enabled/default
fi
if [ -f ${NGINX_PATH}/sites-enabled/${SITE_NAME} ]; then
    log_debug "Removing existing nginx site..."
    sudo rm ${NGINX_PATH}/sites-enabled/${SITE_NAME}
fi
log_debug "Copying nginx site configuration..."
sudo cp ${SITE_CONF_FILE} ${NGINX_PATH}/sites-available/${SITE_NAME}
if grep -Fq "ssl_protocols" ${NGINX_PATH}/nginx.conf; then
    log_debug "Updating SSL protocols..."
    sudo sed -i "s|ssl_protocols .*|ssl_protocols TLSv1.2 TLSv1.3;|" ${NGINX_PATH}/nginx.conf
fi
if ! grep -Fq "ssl_certificate" ${NGINX_PATH}/nginx.conf; then
    log_debug "Adding SSL certificate configuration..."
    sudo sed -i "s|ssl_prefer_server_ciphers on;|ssl_prefer_server_ciphers on;\n\tssl_trusted_certificate ${CERT_PATH}/${SITE_NAME}.${CERT};\n\tssl_certificate ${CERT_PATH}/${SITE_NAME}.${FULLCHAIN};\n\tssl_certificate_key ${CERT_PATH}/${SITE_NAME}.${PRIVKEY};|g" ${NGINX_PATH}/nginx.conf
fi
if ! grep -Fq "client_max_body_size" ${NGINX_PATH}/nginx.conf; then
    log_debug "Adding client max body size..."
    sudo sed -i "s|sendfile on;|sendfile on;\n\tclient_max_body_size 1024M;|g" ${NGINX_PATH}/nginx.conf
fi
log_debug "Configuring nginx site..."
sudo sed -i "s|SITE_NAME|${SITE_NAME}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|WEB_NAME|${WEB_NAME}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|SITE_PATH|${HOST_PATH}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|SITE_CERT|${CERT_PATH}/${SITE_NAME}.${CERT}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|SITE_FULLCHAIN|${CERT_PATH}/${SITE_NAME}.${FULLCHAIN}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
sudo sed -i "s|SITE_PRIVKEY|${CERT_PATH}/${SITE_NAME}.${PRIVKEY}|g" ${NGINX_PATH}/sites-available/${SITE_NAME}
log_debug "Enabling nginx site..."
sudo ln -s ${NGINX_PATH}/sites-available/${SITE_NAME} ${NGINX_PATH}/sites-enabled/${SITE_NAME}
log_info "Restarting nginx service..."
log_exec "sudo systemctl restart nginx"
log_info "nginx installation completed successfully"

