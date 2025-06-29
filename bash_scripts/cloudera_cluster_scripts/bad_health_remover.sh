#!/bin/bash

##############################################################################################
# Author: Praneeth Nambiar
# Date: 01/Aug/2024
# Purpose: 
#   - Run Ranger Setup Plugin
#   - Upload Tez tar
#   - Create Spark directories
#   - Create Livy user HDFS directory
##############################################################################################

set -euo pipefail
IFS=$'\n\t'
set -x

# Source configuration
source ./inventory/shellscript_cm_host_var.conf

# Function to perform a CM API POST call
cm_post() {
  local endpoint="$1"
  curl -s -u "$CM_USERNAME:$CM_PASSWORD" -k -X POST "$CM_URL/api/v54/$endpoint"
}

# Function to create HDFS directory
hdfs_mkdir() {
  local path="$1"
  curl -s -k -X PUT "$ACTIVE_NAMENODE_URL/webhdfs/v1$path?op=MKDIRS&user.name=hdfs"
}

# Function to change HDFS directory owner
hdfs_chown() {
  local path="$1"
  local owner="$2"
  curl -s -k -X PUT "$ACTIVE_NAMENODE_URL/webhdfs/v1$path?op=SETOWNER&owner=$owner&user.name=hdfs"
}a

# Get cluster name
CM_CLUSTER_NAME=$(curl -s -u "$CM_USERNAME:$CM_PASSWORD" -k "$CM_URL/api/v54/clusters" \
  | jq -r '.items[].displayName' | sed 's/ /%20/g')

echo -e "\n==== STARTING PRE-FIX STEPS ====\n"

# Ranger Plugin Setup
cm_post "clusters/$CM_CLUSTER_NAME/services/$RANGER_SERVICE_NAME/commands/SetupPluginServices"
sleep 10

# Tez tar upload
cm_post "clusters/$CM_CLUSTER_NAME/services/$TEZ_SERVICE_NAME/commands/TezUploadTar"
sleep 10

# Spark directory creation
for cmd in CreateSparkUserDirCommand CreateSparkDriverLogDirCommand CreateSparkHistoryDirCommand; do
  cm_post "clusters/$CM_CLUSTER_NAME/services/$SPARK_SERVICE_NAME/commands/$cmd"
done
sleep 10

# Livy HDFS directory creation and ownership
hdfs_mkdir "/user/livy"
hdfs_chown "/user/livy" "livy"

# Uncomment these if restarts are needed
# cm_post "clusters/$CM_CLUSTER_NAME/services/$HIVEONTEZ_SERVICE_NAME/commands/restart"
# cm_post "clusters/$CM_CLUSTER_NAME/services/$HBASE_SERVICE_NAME/commands/restart"
# cm_post "clusters/$CM_CLUSTER_NAME/services/$SPARK_SERVICE_NAME/commands/restart"
# cm_post "clusters/$CM_CLUSTER_NAME/services/$LIVY_SERVICE_NAME/commands/restart"

echo -e "\n==== PRE-FIX STEPS COMPLETED ====\n"
