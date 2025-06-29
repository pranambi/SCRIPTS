#!/bin/bash

###########################################################################################
# Author: Praneeth Nambiar                                                                #
# Description: This script installs Spark3 and Livy on Spark3 services in the CDP cluster #
# Date: 01/Aug/2024                                                                       #
###########################################################################################

# ==================================== VARIABLES START HERE ==================================== #

# Setting safety gurads
set -euo pipefail
IFS=$'\n\t'

# Source the configuration file
source ./inventory/shellscript_cm_host_var.conf

# All host details
# Eg: NODE1_HOSTID="501c03c4-fa87-48f6-b705-b38348ed748f", NODE1_HOSTNAME="node1.cdp1111-psnambiar.coelab.cloudera.com" etc
hosts=$(curl -u $CM_USERNAME:$CM_PASSWORD -k -X GET "$CM_URL/api/v54/hosts")
count=1
echo "$hosts" | jq -r '.items[] | "\(.hostId) \(.hostname)"' | while read -r hostId hostname; do
  echo "NODE${count}_HOSTID=\"$hostId\""
  echo "NODE${count}_HOSTNAME=\"$hostname\""
  count=$((count + 1))
done | tee host_variable.conf
source host_variable.conf

# Extracting cluster name from api itself
# NOTE: "sed 's/ /%20/g'" is used for percent encoding with space. Eg: Cluster 1 to Cluster%201
CM_CLUSTER_NAME=$(curl -u $CM_USERNAME:$CM_PASSWORD -k -X GET "$CM_URL/api/v54/clusters" | jq -r '.items[].displayName' | sed 's/ /%20/g')

# ==================================== UPDATING SPARK REPO STARTS HERE ==================================== #

# To get the current repo setting from CM UI
CM_CURRENT_REPO_URLS=$(curl -s -u $CM_USERNAME:$CM_PASSWORD -X GET "$CM_URL/api/v54/cm/config?view=summary" -k | jq -r '.items[] | select(.name == "REMOTE_PARCEL_REPO_URLS") | .value')

CM_UPDATED_REPO_URLS="$CM_CURRENT_REPO_URLS,$SPARK_REPO_URL"

# Updating Spark 3.3.7190 repo URL to the Parcel Repository & Network Settings
# NEED FIX: Below command will update the repo with same spark repo path everytime it re-runs.
curl -u $CM_USERNAME:$CM_PASSWORD -X PUT "$CM_URL/api/v54/cm/config" -H "Content-Type: application/json" -d "{ \"items\" :[{ \"name\" : \"REMOTE_PARCEL_REPO_URLS\", \"value\": \"$CM_UPDATED_REPO_URLS\"} ]}" -k
echo -e "\nSPARK REPO UPDATED!!!\n"
sleep 10

# ==================================== PARCEL SCRIPT STARTS HERE ==================================== #

# Function to get the current state of the parcel
get_parcel_state() {
    curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X GET "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/parcels?view=summary" | jq -r '.items[] | select(.product == "'$PARCEL_REPO_PRODUCT_NAME'" and .version == "'$PARCEL_REPO_VERSION_NUM'") | .stage';
}

# Loop for the script
counter=0
while true; do
    # Get the current state
    state=$(get_parcel_state)

    # Increment the counter
    counter=$((counter + 1))

    case "$state" in
        "")
            echo "Parcel repo is not setup, can't download"
            exit 1
            ;;
        "AVAILABLE_REMOTELY")
            echo -e "\nStarting download..."
            curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/parcels/products/$PARCEL_REPO_PRODUCT_NAME/versions/$PARCEL_REPO_VERSION_NUM/commands/startDownload"
            echo -e "\n"
            ;;
        "DOWNLOADED")
            echo -e "\nStarting distribution..."
            curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/parcels/products/$PARCEL_REPO_PRODUCT_NAME/versions/$PARCEL_REPO_VERSION_NUM/commands/startDistribution"
            echo -e "\n"
            ;;
        "DISTRIBUTED")
            echo -e "\nActivating..."
            curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/parcels/products/$PARCEL_REPO_PRODUCT_NAME/versions/$PARCEL_REPO_VERSION_NUM/commands/activate"
            echo -e "\n"
            ;;
        "ACTIVATED")
            echo -e "\nParcel is in Activated state"
            break
            ;;
        "DOWNLOADING")
            echo "Parcel is currently DOWNLOADING. Waiting..."
            ;;
        "DISTRIBUTING")
            echo "Parcel is currently DISTRIBUTING. Waiting..."
            ;;
        "ACTIVATING")
            echo "Parcel is currently ACTIVATING. Waiting..."
            ;;
        *)
            echo "Unexpected state: $state"
            break
            ;;
    esac

    # Check if the counter has reached 20
    if [[ $counter -ge 50 ]]; then
        echo -e "\nPolling exceeded 50 times. Exiting...\n"
        exit
    fi

    # Wait before polling again
    sleep 10
done

echo -e "\nSPARK PARCEL ACTIVATED!!!\n"

# ==================================== SPARK3 SERVICE INSTALL STARTS HERE ==================================== #

# To add spark service with dependant services enabled like yarn along with HS service
# NEED FIX: The below curl command could fail at re-run when the SPARK3_ON_YARN service already exists
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -H "Content-Type: application/json" -X POST \
  -d '{
        "items": [
          {
            "name": "Spark3",
            "type": "SPARK3_ON_YARN",
            "config": {
              "items": [
                {
                  "name": "hbase_service",
                  "value": "hbase",
                  "sensitive": false
                },
                {
                  "name": "spark_authenticate",
                  "value": "true",
                  "sensitive": false
                },
                {
                  "name": "atlas_service",
                  "value": "atlas",
                  "sensitive": false
                },
                {
                  "name": "yarn_service",
                  "value": "yarn",
                  "sensitive": false
                }
              ]
            },
            "roles": [
              {
                "type": "SPARK3_YARN_HISTORY_SERVER",
                "hostRef": {
                    "hostId": "'$NODE3_HOSTID'",
                    "hostname": "'$NODE3_HOSTID'"
                }
              },
              {
                "type": "GATEWAY",
                "hostRef": {
                    "hostId": "'$NODE2_HOSTID'",
                    "hostname": "'$NODE2_HOSTNAME'"
                }
              },
              {
                "type": "GATEWAY",
                "hostRef": {
                    "hostId": "'$NODE3_HOSTID'",
                    "hostname": "'$NODE3_HOSTNAME'"
                }
              },
              {
                "type": "GATEWAY",
                "hostRef": {
                    "hostId": "'$NODE4_HOSTID'",
                    "hostname": "'$NODE4_HOSTNAME'"
                }
              }
            ]
          }
        ]
      }' \
  "$CM_URL/api/v40/clusters/$CM_CLUSTER_NAME/services"
sleep 10

# To deploy client configuration only for Spark3 Service
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -H "Content-Type: application/json" -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK3_SERVICE_NAME/commands/deployClientConfig" -d "{ \"items\": [ ]}"
sleep 10

# To run directory creation actions for Spark3
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK3_SERVICE_NAME/commands/CreateSparkUserDirCommand"
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK3_SERVICE_NAME/commands/CreateSparkDriverLogDirCommand"
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK3_SERVICE_NAME/commands/CreateSparkHistoryDirCommand"
sleep 40

## To start Spark3 services
#curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$SPARK3_SERVICE_NAME/commands/start"
echo -e "\nSPARK3 SERVICE INSTALLED! \n"
#sleep 20

# ==================================== LIVY ON SPARK3 SERVICE INSTALL HERE ==================================== #

curl -s -u $CM_USERNAME:$CM_PASSWORD -k -H "Content-Type: application/json" -X POST \
  -d '{
        "items": [
          {
            "name": "Livy_for_spark3",
            "type": "LIVY_FOR_SPARK3",
            "config": {
              "items": [
                {
                  "name" : "hms_service",
                  "value" : "hive",
                  "sensitive" : false
                }, {
                  "name" : "spark3_on_yarn_service",
                  "value" : "Spark3",
                  "sensitive" : false
                }, {
                  "name" : "yarn_service",
                  "value" : "yarn",
                  "sensitive" : false
                }, {
                  "name" : "zookeeper_service",
                  "value" : "zookeeper",
                  "sensitive" : false
                }
              ]
            },
            "roles": [
              {
                "type": "LIVY_SERVER_FOR_SPARK3",
                "hostRef": {
                    "hostId": "'$NODE4_HOSTID'",
                    "hostname": "'$NODE4_HOSTNAME'"
                }
              }
            ]
          }
        ]
      }' \
"$CM_URL/api/v40/clusters/$CM_CLUSTER_NAME/services"
sleep 10

# To deploy client configuration only for Livy3 Service
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -H "Content-Type: application/json" -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$LIVY_SPARK3_SERVICE_NAME/commands/deployClientConfig" -d "{ \"items\": [ ]}"
sleep 10

# To run directory creation actions for Livy3
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$LIVY_SPARK3_SERVICE_NAME/commands/CreateLivyUserDir"
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$LIVY_SPARK3_SERVICE_NAME/commands/CreateRecoveryDirCommand"
sleep 20

## To start livy3 services
#curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/services/$LIVY_SPARK3_SERVICE_NAME/commands/start"
#sleep 20

# To restart stale configuration services
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/v54/clusters/$CM_CLUSTER_NAME/commands/restart" -d "{ \"restartOnlyStaleServices\": true, \"redeployClientConfiguration\": true}"
echo -e "\nLIVY ON SPARK3 SERVICE INSTALLED! \n"

# Cleanup of host varibale file
rm -rf host_variable.conf
