#!/usr/bin/env bash

addgroup guest
adduser --home /home/guest --shell /bin/bash --ingroup guest guest << 'EOF'
password
password
Y
EOF

ssh-keygen -b 2048 -t rsa -f rsa2048 << 'EOF'
EOF

cat > ~/.gitconfig <<EOF
[user]
	name = username
	email = user@email.com
[color]
	ui = true
[core]
	editor = vim
	quotepath = false
	autocrlf = false
	excludesfile = ~/.gitignore
[merge]
	tool = vimdiff
[i18n]
	commitencoding = utf-8
	logoutputencoding = utf-8
[credential]
	helper = wincred
[push]
	default = simple
EOF

cat > ~/.gitignore <<EOF
*.o
*.obj
*.a
*.so
*.bin
*.elf
*.bat
*.log
*.txt
*.gz
*.tar
*.zip
*.gz2
*.gzip
.pyc
__pycache__
.*
EOF

cat > ~/.bashrc <<EOF
#!/bin/bash
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
# PS1 hint
COLOR_GRAY='\[\e[1;30m\]'
COLOR_RED='\[\e[1;31m\]'
COLOR_GREEN='\[\e[1;32m\]'
COLOR_YELLOW='\[\e[1;33m\]'
COLOR_BLUE='\[\e[1;34m\]'
COLOR_PURPLE='\[\e[1;35m\]'
COLOR_CYAN='\[\e[1;36m\]'
COLOR_WHITE='\[\e[1;37m\]'
COLOR_NULL='\[\e[0m\]'
PS1="\$COLOR_RED[\u@\h \t] \w\$ \$COLOR_NULL"
 
# Interactive operation
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ls='ls --color=auto'
alias ll='ls --color=auto -laF'
alias vi='vim'
 
# Default to human readable figures
alias df='df -h'
alias du='du -h'
# timezone settings
export TZ='Asia/Hong_Kong'
EOF

update-ca-certificates

echo "===== host config ====="
old_hostname=`hostname | tr ' ' ','`
read -p "set new hostname: " hostname
echo "$hostname" > /etc/hostname
hostname $hostname
sed -i "s/${old_hostname}/${hostname}/g" /etc/hosts

host_ip=`ip -f inet addr | grep global | awk '{print $2}' | awk -F/ '{print $1}' | tr '\n' ','`
host_escape_password=`echo -ne $password| xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g'`

MASTERHOST=master_hostname
HDFSHOME=/hdfs

source ~/.bashrc

set -e
set -x

echo "===== apt packages installation ====="
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update
apt-get install apt-transport-https
apt-get update
apt-get install vim vim-scripts vim-doc vim-addon-manager
apt-get install ctags cscope tree

echo "===== vim addons installation ====="
vim-addons install omnicppcomplete
vim-addons install minibufexplorer
vim-addons install winmanager
vim-addons install project
vim-addons install taglist

echo "===== python packages installation ====="
apt-get install build-essential libssl-dev libffi-dev python3-dev
apt-get install python3-pip
pip3 install numpy pandas matplotlib
pip3 install sqlalchemy pymysql sshtunnel lxml openpyxl xlrd beautifulsoup4
apt-get install graphviz libgraphviz-dev pkg-config
pip3 install pydot pygraphviz anytree networkx pyfpgrowth
pip3 install tensorflow tensorboard captcha
ln -s /usr/bin/python3.5 /usr/bin/python

echo "===== sftp server installation ====="
sudo apt-get update
sudo apt-get install vsftpd
cp /etc/vsftpd.conf /etc/vsftpd.conf.origin
USERLIST_FILE=/etc/vsftpd.userlist
sudo useradd -m -c "SFTP user" -s /bin/bash sftpuser
sudo passwd sftpuser
echo "sftpuser" | sudo tee -a ${USERLIST_FILE}
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 990/tcp
sudo ufw allow 40000:50000/tcp
sudo ufw status
sudo systemctl stop vsftpd.service
sudo systemctl enable vsftpd.service
sudo systemctl start vsftpd.service
SFTPROOT=/sftpdir
SFTPUPLOAD=${SFTPROOT}/uploads
mkdir ${SFTPROOT}
chown sftpuser:sftpuser ${SFTPUPLOAD}
chmod 777 ${SFTPUPLOAD}
sudo openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/private/vsftpdprivate.key -out /etc/ssl/certs/vsftpdcertificate.pem -days 365
echo "# ftp configuration" > /etc/vsftpd.conf
echo "ftpd_banner=Welcome to SFTP server." >> /etc/vsftpd.conf
echo "listen=NO" >> /etc/vsftpd.conf
echo "listen_ipv6=YES" >> /etc/vsftpd.conf
echo "anonymous_enable=NO" >> /etc/vsftpd.conf
echo "local_enable=YES" >> /etc/vsftpd.conf
echo "write_enable=YES" >> /etc/vsftpd.conf
echo "local_umask=022" >> /etc/vsftpd.conf
echo "connect_from_port_20=YES" >> /etc/vsftpd.conf
echo "utf8_filesystem=YES" >> /etc/vsftpd.conf
echo "local_root=${SFTPROOT}" >> /etc/vsftpd.conf
echo "chroot_local_user=YES">> /etc/vsftpd.conf
echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf
echo "pam_service_name=vsftpd" >> /etc/vsftpd.conf
echo "userlist_deny=NO" >> /etc/vsftpd.conf
echo "userlist_enable=YES" >> /etc/vsftpd.conf
echo "userlist_file=${USERLIST_FILE}" >> /etc/vsftpd.conf
echo "hide_ids=YES" >> /etc/vsftpd.conf
echo "max_clients=20" >> /etc/vsftpd.conf
echo "max_per_ip=2" >> /etc/vsftpd.conf
echo "secure_chroot_dir=/var/run/vsftpd/empty" >> /etc/vsftpd.conf
echo "rsa_cert_file=/etc/ssl/certs/vsftpdcertificate.pem" >> /etc/vsftpd.conf
echo "rsa_private_key_file=/etc/ssl/private/vsftpdprivate.key" >> /etc/vsftpd.conf
echo "ssl_enable=YES" >> /etc/vsftpd.conf
echo "allow_anon_ssl=NO" >> /etc/vsftpd.conf
echo "force_local_data_ssl=YES" >> /etc/vsftpd.conf
echo "force_local_logins_ssl=YES" >> /etc/vsftpd.conf
echo "require_ssl_reuse=NO" >> /etc/vsftpd.conf
echo "ssl_ciphers=HIGH" >> /etc/vsftpd.conf
echo "ssl_tlsv1=YES" >> /etc/vsftpd.conf
echo "ssl_sslv2=NO" >> /etc/vsftpd.conf
echo "ssl_sslv3=NO" >> /etc/vsftpd.conf
echo "dirmessage_enable=YES" >> /etc/vsftpd.conf
echo "xferlog_file=/var/log/vsftpd.log" >> /etc/vsftpd.conf
echo "xferlog_std_format=YES" >> /etc/vsftpd.conf
sudo systemctl restart vsftpd

echo "===== docker installation ====="
apt-get install docker-engine
systemctl enable docker
service docker start
docker version

echo "===== kubernetes installation ====="
apt-get install -y kubelet kubeadm kubectl
## kubernetes config
#swapoff –a
#comment swap in /etc/fstab
## master
#kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=x.x.x.x
#cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#chown $(id -u):$(id -g) $HOME/.kube/config
#echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile
#kubectl apply -f dockerk8s/kube-flannel.yml
#kubectl get nodes
## slave
#kubeadm join x
## dashboard
#curpath=$PWD
#mkdir -p /etc/kubernetes/addons/certs && cd /etc/kubernetes/addons
#openssl genrsa -des3 -passout pass:x -out certs/dashboard.pass.key 2048
#openssl rsa -passin pass:x -in certs/dashboard.pass.key -out certs/dashboard.key
#openssl req -new -key certs/dashboard.key -out certs/dashboard.csr -subj '/CN=kube-dashboard'
#openssl x509 -req -sha256 -days 365 -in certs/dashboard.csr -signkey certs/dashboard.key -out certs/dashboard.crt
#rm -rf certs/dashboard.pass.key
#cd $curpath
#kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system	
#kubectl -n kube-system get secret
#kubectl apply -f dockerk8s/kubernetes-dashboard.yaml
#kubectl describe svc kubernetes-dashboard -n kube-system
#kubectl edit svc kubernetes-dashboard -n kube-system (type to NodePort, add nodePort: 30443)
#kubectl apply -f rbac.yaml
#kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
## status
#kubectl get pods --all-namespaces -o wide
#kubectl get nodes
#kubectl get pods -n kube-system | grep -v Running
#kubectl describe pod kubernetes-dashboard -n kube-system
#kubectl logs kubernetes-dashboard -n kube-system

echo "===== java installation ====="
apt-get install openjdk-8-jre openjdk-8-jdk
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
JRE_HOME=${JAVA_HOME}/jre
CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
PATH=${PATH}:${JAVA_HOME}/bin

echo "===== hadoop installation ====="
cd dockerk8s
curl -O http://apache.communilink.net/hadoop/common/hadoop-2.8.5/hadoop-2.8.5.tar.gz
addgroup hadoop
adduser --home /home/hadoop --shell /bin/bash --ingroup hadoop hadoop
tar -zxvf hadoop-2.8.5.tar.gz -C /usr/local
cd ..
HADOOP_HOME=/usr/local/hadoop-2.8.5
chown -R hadoop:hadoop ${HADOOP_HOME}
HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
YARN_CONF_DIR=${HADOOP_HOME}/etc/hadoop
PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
## hadoop config
apt-get install ufw
ufw disable
chown hadoop:hadoop -R ${HDFSHOME}
mkdir -p ${HDFSHOME}/hadoop/tmp
mkdir -p ${HDFSHOME}/hadoop/name
mkdir -p ${HDFSHOME}/hadoop/data
sed -i "s|.*JAVA_HOME=\${JAVA_HOME}.*|export JAVA_HOME=${JAVA_HOME}|g" $HADOOP_HOME/etc/hadoop/hadoop-env.sh
## datanode
hostname > $HADOOP_HOME/etc/hadoop/slaves
#add all datanodes to /etc/hosts and $HADOOP_HOME/etc/hadoop/slaves
## core-site.xml
#<configuration>
#       <property>
#               <name>fs.defaultFS</name>
#               <value>hdfs://${MASTERHOST}:9000</value>
#       </property>
#       <property>
#               <name>hadoop.tmp.dir</name>
#               <value>file:${HDFSHOME}/hadoop/tmp</value>
#       </property>
#</configuration>
## hdfs-site.xml
#<configuration>
#       <property>
#               <name>dfs.namenode.secondary.http-address</name>
#               <value>Ubuntu1604Hadoop2:50090</value>
#       </property>
#       <property>
#               <name>dfs.replication</name>
#               <value>2</value>
#       </property>
#       <property>
#               <name>dfs.namenode.name.dir</name>
#               <value>file:${HDFSHOME}/hadoop/name</value>
#       </property>
#       <property>
#               <name>dfs.datanode.data.dir</name>
#               <value>file:${HDFSHOME}/hadoop/data</value>
#       </property>
#</configuration>
cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml
chown hadoop:hadoop $HADOOP_HOME/etc/hadoop/mapred-site.xml
## mapred-site.xml
#<configuration>
#       <property>
#               <name>mapreduce.framework.name</name>
#               <value>yarn</value>
#       </property>
#       <property>
#               <name>mapreduce.jobhistory.address</name>
#               <value>${MASTERHOST}:10020</value>
#       </property>
#       <property>
#               <name>mapreduce.jobhistory.webapp.address</name>
#               <value>${MASTERHOST}:19888</value>
#       </property>
#</configuration>
## yarn-site.xml
#<configuration>
#       <property>
#               <name>yarn.resourcemanager.hostname</name>
#               <value>${MASTERHOST}</value>
#       </property>
#       <property>
#               <name>yarn.nodemanager.aux-services</name>
#               <value>mapreduce_shuffle</value>
#       </property>
#</configuration>
## master namenode format
hdfs namenode -format
## hadoop start
start-dfs.sh
start-yarn.sh
mr-jobhistory-daemon.sh start historyserver
## hadoop stop
stop-yarn.sh
stop-dfs.sh
mr-jobhistory-daemon.sh stop historyserver
## hadoop status
hdfs dfsadmin -report

echo "===== scala installation ====="
cd dockerk8s
curl -O https://downloads.lightbend.com/scala/2.12.7/scala-2.12.7.tgz
tar -zxvf scala-2.12.7.tgz -C /usr/local
cd ..
SCALA_HOME=/usr/local/scala-2.12.7
chown -R hadoop:hadoop ${SCALA_HOME}
PATH=${PATH}:${SCALA_HOME}/bin

echo "===== spark installation ====="
cd dockerk8s
curl -O http://archive.apache.org/dist/spark/spark-2.3.2/spark-2.3.2-bin-without-hadoop.tgz
tar -zxvf spark-2.3.2-bin-without-hadoop.tgz -C /usr/local
cd ..
SPARK_HOME=/usr/local/spark-2.3.2
mv /usr/local/spark-2.3.2-bin-without-hadoop ${SPARK_HOME}
chown -R hadoop:hadoop ${SPARK_HOME}
mkdir -p ${HDFSHOME}/spark
chown -R hadoop:hadoop ${HDFSHOME}/spark
SPARK_CONF_DIR=${SPARK_HOME}/conf
SPARK_DIST_CLASSPATH=$(hadoop classpath)
CLASSPATH=:${CLASSPATH}:${SPARK_HOME}/lib
PATH=${PATH}:${SPARK_HOME}/bin:${SPARK_HOME}/sbin
pip3 install pypandoc pyspark
## spark config
echo "#!/bin/bash" > ${SPARK_HOME}/conf/spark-env.sh
echo "export JAVA_HOME=${JAVA_HOME}" > ${SPARK_HOME}/conf/spark-env.sh
echo "export HADOOP_HOME=${HADOOP_HOME}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export YARN_CONF_DIR=${YARN_CONF_DIR}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SCALA_HOME=${SCALA_HOME}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SPARK_HOME=${SPARK_HOME}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SPARK_CONF_DIR=${SPARK_CONF_DIR}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SPARK_MASTER_IP=${MASTERHOST}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SPARK_LOCAL_DIRS=${HDFSHOME}/spark" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SPARK_EXECUTOR_CORES=4" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SPARK_EXECUTOR_MEMORY=2G" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SPARK_DRIVER_MEMORY=2G" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export SPARK_DIST_CLASSPATH=${SPARK_DIST_CLASSPATH}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${HADOOP_HOME}/lib/native" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export CLASSPATH=${CLASSPATH}" >> ${SPARK_HOME}/conf/spark-env.sh
echo "export PATH=${PATH}" >> ${SPARK_HOME}/conf/spark-env.sh
hostname > ${SPARK_HOME}/conf/slaves
chown hadoop:hadoop ${SPARK_HOME}/conf/*
cp ${SPARK_HOME}/sbin/start-all.sh ${SPARK_HOME}/sbin/start-spark.sh
cp ${SPARK_HOME}/sbin/stop-all.sh ${SPARK_HOME}/sbin/stop-spark.sh
chown hadoop:hadoop ${SPARK_HOME}/sbin/*
hadoop fs -mkdir /tmp/jarlibs
hadoop fs -put $SPARK_HOME/jars/* /tmp/jarlibs/

echo "===== env settings ====="
echo "" >> /etc/profile
echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/profile
echo "export JRE_HOME=${JRE_HOME}" >> /etc/profile
echo "export HADOOP_HOME=${HADOOP_HOME}" >> /etc/profile
echo "export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_COMMON_LIB_NATIVE_DIR}" >> /etc/profile
echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> /etc/profile
echo "export YARN_CONF_DIR=${YARN_CONF_DIR}" >> /etc/profile
echo "export SCALA_HOME=${SCALA_HOME}" >> /etc/profile
echo "export SPARK_HOME=${SPARK_HOME}" >> /etc/profile
echo "export CLASSPATH=${CLASSPATH}" >> /etc/profile
echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${HADOOP_HOME}/lib/native" >> /etc/profile
echo "export PATH=${PATH}" >> /etc/profile

echo "#!/bin/bash" > /root/startall.sh
echo "start-dfs.sh" >> /root/startall.sh
echo "start-yarn.sh" >> /root/startall.sh
echo "mr-jobhistory-daemon.sh start historyserver" >> /root/startall.sh
echo "start-spark.sh">> /root/startall.sh

echo "#!/bin/bash" > /root/startall.sh
echo "stop-spark.sh" >> /root/stopall.sh
echo "stop-yarn.sh" >> /root/stopall.sh
echo "stop-dfs.sh" >> /root/stopall.sh
echo "mr-jobhistory-daemon.sh stop historyserver" >> /root/stopall.sh
