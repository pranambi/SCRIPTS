#!/bin/bash

###########################################################################################################
# Author: Praneeth Nambiar                                                                                #
# Date: 01/Aug/2024                                                                                       #
# This script runs Ranger Setup Plugin, Upload Tez tar, Spark Dir Commands, Creates livy user dir in HDFS #
###########################################################################################################

# Display all the commands in the console
set -x;

# Source the configuration file
source ./inventory/shellscript_cm_host_var.conf

# Extracting cluster name from api itself
CM_CLUSTER_NAME=$(curl -u $CM_USERNAME:$CM_PASSWORD -k -X GET "$CM_URL/api/v54/clusters" | jq -r '.items[].displayName' | sed 's/ /%20/g')

# ==================================== SCRIPT STARTS HERE ==================================== #

echo -e "==== PRE-FIX STEPS GETTING STARTED ==== \n"

# ========= HIVE/HBASE RANGER PLUGIN NOT FOUND/PERMISSION ISSUE FIX ========= #

# To trigger Ranger Setup Plugin command
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$RANGER_SERVICE_NAME/commands/SetupPluginServices"
sleep 10

# To trigger upload tar file from Tez service
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$TEZ_SERVICE_NAME/commands/TezUploadTar"
sleep 10

# ========= LIVY USER DIR NOT FOUND FIX ========= #

# To trigger Spark hdfs dir creation commands
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK_SERVICE_NAME/commands/CreateSparkUserDirCommand"
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK_SERVICE_NAME/commands/CreateSparkDriverLogDirCommand"
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK_SERVICE_NAME/commands/CreateSparkHistoryDirCommand"
sleep 10

# ========= LIVY USER DIR NOT FOUND FIX ========= #

# To create '/user/livy' directory and change owner of the same to 'livy' user
curl -k -X PUT "$ACTIVE_NAMENODE_URL/webhdfs/v1/user/livy?op=MKDIRS&user.name=hdfs"
curl -k -X PUT "$ACTIVE_NAMENODE_URL/webhdfs/v1/user/livy?op=SETOWNER&owner=livy&user.name=hdfs"

# ========= RESTART SERVICES ========= #

# Restart HS2 Service
#curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$HIVEONTEZ_SERVICE_NAME/commands/restart"

# Restart Hbase Service
#curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$HBASE_SERVICE_NAME/commands/restart"

# Restart Spark Service
#curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK_SERVICE_NAME/commands/restart"

# Restart livy Service
#curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$LIVY_SERVICE_NAME/commands/restart"

echo -e "\n==== PRE-FIX STEPS COMPLETED ====\n"