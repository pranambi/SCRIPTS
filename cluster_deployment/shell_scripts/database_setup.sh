#!/bin/bash

# Source the configuration file
# Update the hostname/ip and ssh password in the below file before running this job
# The below location is the "cm_and_host_details.py" available in the server host
source /tmp/cm_and_host_details.py

# List of hosts
hosts=("$host1" "$host2" "$host3" "$host4")

# Stop MySQL service
systemctl stop mysqld

# Uninstall old MySQLMariaDB packages
yum remove mysql mysql-* -y

# Mysql old data cleanup
rm -rf /var/lib/mysql/*

# Run yum install command
yum install mariadb-server -y

# Check the exit status of the yum command
if [ $? -eq 0 ]; then
    echo "MariaDB is installed."
else
    echo "MariaDB installation failed."
    exit 1  # Exit with failure status
fi

# Updating the my.cnf file
cat <<EOF > /etc/my.cnf
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
symbolic-links = 0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd

key_buffer = 16M
key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550
#expire_logs_days = 10
#max_binlog_size = 100M

#log_bin should be on a disk with enough free space.
#Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your
#system and chown the specified folder to the mysql user.
log_bin=/var/lib/mysql/mysql_binary_log

#In later versions of MariaDB, if you enable the binary log and do not set
#a server_id, MariaDB will not start. The server_id must be unique within
#the replicating group.
server_id=1

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d
EOF

# Printing the conf update
echo "my.cnf file is updated"

# Enable and start the MySQL service
systemctl enable mariadb
systemctl start mariadb

# Check the exit status of the systemctl commands
if [ $? -eq 0 ]; then
    echo "MariaDB service is enabled and started."
else
    echo "Failed to enable and start MariaDB service."
    exit 1  # Exit with failure status
fi

# Updating the MariaDB dirver jar
commands='
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.48.tar.gz && \
tar -zxvf mysql-connector-java-5.1.48.tar.gz && \
mkdir -p /usr/share/java/ && \
cd mysql-connector-java-5.1.48 && \
cp -f mysql-connector-java-5.1.48-bin.jar /usr/share/java/mysql-connector-java.jar && \
yum install mysql-devel xmlsec1 xmlsec1-openssl -y && \
yum groupinstall "Development Tools" -y && \
export PATH=/usr/local/bin:$PATH && \
pip3.8 install mysqlclient && \
echo "Mysql driver updated on $(hostname)"
'

# Loop through each host and execute the commands
for host in "${hosts[@]}"; do
    echo "Running commands on ${host}..."
    ssh -o BatchMode=yes "${host}" "${commands}" || { echo "Error: Command failed on ${host}"; exit 1; }
    echo "=============="
done

# Function to execute MySQL command and check exit status
execute_mysql_command() {
    mysql -u root -e "$1"
    if [ $? -ne 0 ]; then
        echo "MySQL command failed: $1"
        exit 1
    fi
}

# Run MySQL commands
execute_mysql_command "DROP DATABASE IF EXISTS scm;"
execute_mysql_command "CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
execute_mysql_command "DROP USER IF EXISTS 'scm'@'%';"
execute_mysql_command "DROP USER IF EXISTS 'scm'@'localhost';"
execute_mysql_command "DROP USER IF EXISTS 'scm'@'$host1';"
execute_mysql_command "CREATE USER 'scm'@'%' IDENTIFIED BY 'scm';"
execute_mysql_command "CREATE USER 'scm'@'localhost' IDENTIFIED BY 'scm';"
execute_mysql_command "CREATE USER 'scm'@'$host1' IDENTIFIED BY 'scm';"
execute_mysql_command "GRANT ALL PRIVILEGES ON scm.* TO 'scm'@'%';"
execute_mysql_command "GRANT ALL PRIVILEGES ON scm.* TO 'scm'@'localhost';"
execute_mysql_command "GRANT ALL PRIVILEGES ON scm.* TO 'scm'@'$host1';"

execute_mysql_command "DROP DATABASE IF EXISTS rman;"
execute_mysql_command "CREATE DATABASE rman;"
execute_mysql_command "DROP USER IF EXISTS 'rman'@'%';"
execute_mysql_command "DROP USER IF EXISTS 'rman'@'localhost';"
execute_mysql_command "DROP USER IF EXISTS 'rman'@'$host1';"
execute_mysql_command "CREATE USER 'rman'@'%' IDENTIFIED BY 'rman';"
execute_mysql_command "CREATE USER 'rman'@'localhost' IDENTIFIED BY 'rman';"
execute_mysql_command "CREATE USER 'rman'@'$host1' IDENTIFIED BY 'rman';"
execute_mysql_command "GRANT ALL PRIVILEGES ON rman.* TO 'rman'@'%';"
execute_mysql_command "GRANT ALL PRIVILEGES ON rman.* TO 'rman'@'localhost';"
execute_mysql_command "GRANT ALL PRIVILEGES ON rman.* TO 'rman'@'$host1';"

execute_mysql_command "DROP DATABASE IF EXISTS ranger;"
execute_mysql_command "CREATE DATABASE ranger;"
execute_mysql_command "DROP USER IF EXISTS 'ranger'@'%';"
execute_mysql_command "DROP USER IF EXISTS 'ranger'@'localhost';"
execute_mysql_command "DROP USER IF EXISTS 'ranger'@'$host2';"
execute_mysql_command "DROP USER IF EXISTS 'ranger'@'$host3';"
execute_mysql_command "DROP USER IF EXISTS 'ranger'@'$host4';"
execute_mysql_command "CREATE USER 'ranger'@'%' IDENTIFIED BY 'ranger';"
execute_mysql_command "CREATE USER 'ranger'@'localhost' IDENTIFIED BY 'ranger';"
execute_mysql_command "CREATE USER 'ranger'@'$host2' IDENTIFIED BY 'ranger';"
execute_mysql_command "CREATE USER 'ranger'@'$host3' IDENTIFIED BY 'ranger';"
execute_mysql_command "CREATE USER 'ranger'@'$host4' IDENTIFIED BY 'ranger';"
execute_mysql_command "GRANT ALL PRIVILEGES ON ranger.* TO 'ranger'@'%' with grant option;"
execute_mysql_command "GRANT ALL PRIVILEGES ON ranger.* TO 'ranger'@'localhost';"
execute_mysql_command "GRANT ALL PRIVILEGES ON ranger.* TO 'ranger'@'$host2';"
execute_mysql_command "GRANT ALL PRIVILEGES ON ranger.* TO 'ranger'@'$host3';"
execute_mysql_command "GRANT ALL PRIVILEGES ON ranger.* TO 'ranger'@'$host4';"

execute_mysql_command "DROP DATABASE IF EXISTS hive;"
execute_mysql_command "CREATE DATABASE hive;"
execute_mysql_command "DROP USER IF EXISTS 'hive'@'%';"
execute_mysql_command "DROP USER IF EXISTS 'hive'@'localhost';"
execute_mysql_command "DROP USER IF EXISTS 'hive'@'$host2';"
execute_mysql_command "DROP USER IF EXISTS 'hive'@'$host3';"
execute_mysql_command "DROP USER IF EXISTS 'hive'@'$host4';"
execute_mysql_command "CREATE USER 'hive'@'%' IDENTIFIED BY 'hive';"
execute_mysql_command "CREATE USER 'hive'@'localhost' IDENTIFIED BY 'hive';"
execute_mysql_command "CREATE USER 'hive'@'$host2' IDENTIFIED BY 'hive';"
execute_mysql_command "CREATE USER 'hive'@'$host3' IDENTIFIED BY 'hive';"
execute_mysql_command "CREATE USER 'hive'@'$host4' IDENTIFIED BY 'hive';"
execute_mysql_command "GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'%' with grant option;"
execute_mysql_command "GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'localhost';"
execute_mysql_command "GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'$host2';"
execute_mysql_command "GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'$host3';"
execute_mysql_command "GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'$host4';"

execute_mysql_command "DROP DATABASE IF EXISTS oozie;"
execute_mysql_command "CREATE DATABASE oozie default character set utf8;"
execute_mysql_command "DROP USER IF EXISTS 'oozie'@'%';"
execute_mysql_command "DROP USER IF EXISTS 'oozie'@'localhost';"
execute_mysql_command "DROP USER IF EXISTS 'oozie'@'$host2';"
execute_mysql_command "DROP USER IF EXISTS 'oozie'@'$host3';"
execute_mysql_command "DROP USER IF EXISTS 'oozie'@'$host4';"
execute_mysql_command "CREATE USER 'oozie'@'%' IDENTIFIED BY 'oozie';"
execute_mysql_command "CREATE USER 'oozie'@'localhost' IDENTIFIED BY 'oozie';"
execute_mysql_command "CREATE USER 'oozie'@'$host2' IDENTIFIED BY 'oozie';"
execute_mysql_command "CREATE USER 'oozie'@'$host3' IDENTIFIED BY 'oozie';"
execute_mysql_command "CREATE USER 'oozie'@'$host4' IDENTIFIED BY 'oozie';"
execute_mysql_command "GRANT ALL PRIVILEGES ON oozie.* TO 'oozie'@'%' with grant option;"
execute_mysql_command "GRANT ALL PRIVILEGES ON oozie.* TO 'oozie'@'localhost';"
execute_mysql_command "GRANT ALL PRIVILEGES ON oozie.* TO 'oozie'@'$host2';"
execute_mysql_command "GRANT ALL PRIVILEGES ON oozie.* TO 'oozie'@'$host3';"
execute_mysql_command "GRANT ALL PRIVILEGES ON oozie.* TO 'oozie'@'$host4';"

execute_mysql_command "DROP DATABASE IF EXISTS hue;"
execute_mysql_command "CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
execute_mysql_command "DROP USER IF EXISTS 'hue'@'%';"
execute_mysql_command "DROP USER IF EXISTS 'hue'@'localhost';"
execute_mysql_command "DROP USER IF EXISTS 'hue'@'$host2';"
execute_mysql_command "DROP USER IF EXISTS 'hue'@'$host3';"
execute_mysql_command "DROP USER IF EXISTS 'hue'@'$host4';"
execute_mysql_command "CREATE USER 'hue'@'%' IDENTIFIED BY 'hue';"
execute_mysql_command "CREATE USER 'hue'@'localhost' IDENTIFIED BY 'hue';"
execute_mysql_command "CREATE USER 'hue'@'$host2' IDENTIFIED BY 'hue';"
execute_mysql_command "CREATE USER 'hue'@'$host3' IDENTIFIED BY 'hue';"
execute_mysql_command "CREATE USER 'hue'@'$host4' IDENTIFIED BY 'hue';"
execute_mysql_command "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'%' with grant option;"
execute_mysql_command "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'localhost';"
execute_mysql_command "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'$host2';"
execute_mysql_command "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'$host3';"
execute_mysql_command "GRANT ALL PRIVILEGES ON hue.* TO 'hue'@'$host4';"

execute_mysql_command "DROP DATABASE IF EXISTS smm;"
execute_mysql_command "CREATE DATABASE smm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
execute_mysql_command "DROP USER IF EXISTS 'smm'@'%';"
execute_mysql_command "DROP USER IF EXISTS 'smm'@'localhost';"
execute_mysql_command "DROP USER IF EXISTS 'smm'@'$host2';"
execute_mysql_command "DROP USER IF EXISTS 'smm'@'$host3';"
execute_mysql_command "DROP USER IF EXISTS 'smm'@'$host4';"
execute_mysql_command "CREATE USER 'smm'@'%' IDENTIFIED BY 'smm';"
execute_mysql_command "CREATE USER 'smm'@'localhost' IDENTIFIED BY 'smm';"
execute_mysql_command "CREATE USER 'smm'@'$host2' IDENTIFIED BY 'smm';"
execute_mysql_command "CREATE USER 'smm'@'$host3' IDENTIFIED BY 'smm';"
execute_mysql_command "CREATE USER 'smm'@'$host4' IDENTIFIED BY 'smm';"
execute_mysql_command "GRANT ALL PRIVILEGES ON smm.* TO 'smm'@'%' with grant option;"
execute_mysql_command "GRANT ALL PRIVILEGES ON smm.* TO 'smm'@'localhost';"
execute_mysql_command "GRANT ALL PRIVILEGES ON smm.* TO 'smm'@'$host2';"
execute_mysql_command "GRANT ALL PRIVILEGES ON smm.* TO 'smm'@'$host3';"
execute_mysql_command "GRANT ALL PRIVILEGES ON smm.* TO 'smm'@'$host4';"

execute_mysql_command "SET GLOBAL log_bin_trust_function_creators = 1;"
execute_mysql_command "FLUSH PRIVILEGES;"

echo "DBs created and setup completed!!"