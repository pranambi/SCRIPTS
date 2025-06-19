#!/bin/bash

################################################################################################################################
# Author: Praneeth Nambiar                                                                                                     #
# Date: 01/Aug/2024                                                                                                            #
# Description: This script enabled Auto-TLS usecase1 in the Cloudera cluster                                                   #
# Ref Doc: https://community.cloudera.com/t5/Internal/How-to-modify-Auto-TLS-host-and-root-CA-certificate-validity/ta-p/342359 #
# NOTE: KEEP THE /etc/hosts FILE UPDATE BEFORE RUNNING THIS SCRIPT                                                             #
################################################################################################################################

# Display all the commands in the console
#set -x;

# Source the configuration file
source ./inventory/shellscript_cm_host_var.conf

# Extracting server name from CM URL
ssh_cm_server_node=$(echo "$CM_URL" | sed -e 's~^[^/]*//\([^:/]*\).*~\1~')

# Extracting cluster name from api itself
CM_CLUSTER_NAME=$(curl -u $CM_USERNAME:$CM_PASSWORD -k -X GET "$CM_URL/api/v54/clusters" | jq -r '.items[].displayName' | sed 's/ /%20/g')

## Curl command to enable auto-tls usecase-1
curl -ivk -u $CM_USERNAME:$CM_PASSWORD -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
"customCA" : false,
"configureAllServices" : "true",
"sshPort" : 22,
"userName" : "'$ssh_username'",
"password" : "'$ssh_password'"
}' "http://$ssh_cm_server_node:7180/api/v41/cm/commands/generateCmca"
sleep 5

## Restart CM Server
## The -m option in grep specifies the maximum number of matches to print.
sshpass -p "$ssh_password" ssh root@$ssh_cm_server_node "systemctl restart cloudera-scm-server; systemctl status cloudera-scm-server; tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log | grep -m 1 'Started Jetty'"
sleep 5

# Restart CMS
curl -u "$CM_USERNAME:$CM_PASSWORD" -k -X POST "https://$ssh_cm_server_node:7183/api/v54/cm/service/commands/restart"

# Restart cluster stale configurations
curl -u "$CM_USERNAME:$CM_PASSWORD" -k -X POST "https://$ssh_cm_server_node:7183/api/v54/clusters/$CM_CLUSTER_NAME/commands/restart" -H "Content-Type: application/json" -d '{"redeployClientConfiguration": true}'
