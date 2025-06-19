#!/bin/bash

#################################################################################################################
# This is a script which will update the /etc/host file in Laptop and cluster nodes                             #
# Desc: Version 2 which collects the host anme using CM UI. No need to manually provide the host and ip details #
# Author: Praneeth Nambiar                                                                                      #
# Date: 01/May/2024                                                                                             #
# NOTE: Run "brew install sshpass" before running this code                                                     #
#################################################################################################################

# Cloudera Manager Details
CM_URL1="http://10.xxx.xxx.64:7180"
CM_URL2="http://10.xxx.xxx.142:7180"
CM_USERNAME="admin"
CM_PASSWORD="admin"

# Laptop credentials
MAC_PASS="xxxx"
SSH_PASS="xxxx"

# Host short name variables
short_name_host1="cdp11"
short_name_host2="cdp12"
short_name_host3="cdp13"
short_name_host4="cdp14"

short_name_host5="cdp21"
short_name_host6="cdp22"
short_name_host7="cdp23"
short_name_host8="cdp24"

# All host details
# Eg: NODE1_HOSTID="501c03c4-fa87-48f6-b705-b38348ed748f", NODE1_HOSTNAME="node1.cdp1111-psnambiar.coelab.cloudera.com" etc
# Fetch hosts from CM_URL1
hosts=$(curl -k -u "$CM_USERNAME:$CM_PASSWORD" -X GET "$CM_URL1/api/v54/hosts")
count=1
while read -r ipAddress hostname; do
  eval "ip_host${count}=\"$ipAddress\""
  eval "host${count}=\"$hostname\""
  count=$((count + 1))
done < <(echo "$hosts" | jq -r '.items[] | "\(.ipAddress) \(.hostname)"')

# Fetch hosts from CM_URL2
hosts=$(curl -k -u "$CM_USERNAME:$CM_PASSWORD" -X GET "$CM_URL2/api/v54/hosts")
count=5
while read -r ipAddress hostname; do
  eval "ip_host${count}=\"$ipAddress\""
  eval "host${count}=\"$hostname\""
  count=$((count + 1))
done < <(echo "$hosts" | jq -r '.items[] | "\(.ipAddress) \(.hostname)"')

# ====================================== SCRIPT STARTS HERE ==================================== #

# List of hosts (If both the cluster nodes need update use the later hosts variable)
#hosts=("$host1" "$host2" "$host3" "$host4")
hosts=("$host1" "$host2" "$host3" "$host4" "$host5" "$host6" "$host7" "$host8")
echo "${hosts[@]}"

# /etc/hosts update in MacoS
echo "Updating /etc/hosts on Mac..."
echo "$MAC_PASS" | sudo -S sed -i '' -e "/$host1/d" -e "/$host2/d" -e "/$host3/d" -e "/$host4/d" -e "/$host5/d" -e "/$host6/d" -e "/$host7/d" -e "/$host8/d" /etc/hosts && echo "your_password" | sudo -S sed -i '' 'N;/^\n$/d;P;D' /etc/hosts && echo -e "\n$ip_host1 $host1 $short_name_host1
$ip_host2 $host2 $short_name_host2
$ip_host3 $host3 $short_name_host3
$ip_host4 $host4 $short_name_host4
$ip_host5 $host5 $short_name_host5
$ip_host6 $host6 $short_name_host6
$ip_host7 $host7 $short_name_host7
$ip_host8 $host8 $short_name_host8
" | sudo -S tee -a /etc/hosts > /dev/null

# /etc/hosts update in Cluster hosts
echo -e "\nUpdating /etc/hosts on Cluster hosts..."
for i in "${hosts[@]}"; do
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no root@"$i" "
        sudo sed -e "/$host1/d" -e "/$host2/d" -e "/$host3/d" -e "/$host4/d" -e "/$host5/d" -e "/$host6/d" -e "/$host7/d" -e "/$host8/d" /etc/hosts > /tmp/hosts.new &&
        sudo sed -i '/^$/d' /tmp/hosts.new &&
        echo -e \"\\n$ip_host1 $host1 $short_name_host1\\n$ip_host2 $host2 $short_name_host2\\n$ip_host3 $host3 $short_name_host3\\n$ip_host4 $host4 $short_name_host4\\n$ip_host5 $host5 $short_name_host5\\n$ip_host6 $host6 $short_name_host6\\n$ip_host7 $host7 $short_name_host7\\n$ip_host8 $host8 $short_name_host8\" | sudo tee -a /tmp/hosts.new > /dev/null &&
        sudo cp /tmp/hosts.new /etc/hosts &&
        sudo rm /tmp/hosts.new
    "
done

echo -e "\nUpdated /etc/hosts on the following hosts:"
for host in "${hosts[@]}"; do
    echo "$host"
done
