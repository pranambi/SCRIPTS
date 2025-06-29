#!/bin/bash

################################################################################################################################################
# Author: Praneeth Nambiar                                                                                                                     #
# Date: 01/Aug/2024                                                                                                                            #
# Description: This script enables AD kerberos on Cloudera Manager cluster according to setting in  './inventory/shellscript_cm_host_var.conf' #
# NOTE: KEEP THE /etc/hosts FILE UPDATE BEFORE RUNNING THIS SCRIPT                                                                             #
################################################################################################################################################

# Display all the commands in the console
set -euo pipefail
IFS=$'\n\t'
#set -x;

# Source the configuration file
source ./inventory/shellscript_cm_host_var.conf

# Extracting api version number from api itself
CM_API_V=$(curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X GET "$CM_URL/api/version")

# Extracting cluster name from api itself
CM_CLUSTER_NAME=$(curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X GET "$CM_URL/api/$CM_API_V/clusters" | jq -r '.items[].displayName' | sed 's/ /%20/g')

curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X PUT -H "Content-Type: application/json" \
-d '{
  "items" : [
    {
      "name": "kdc_type",
      "value": "Active Directory"
    },
    {
      "name": "ad_kdc_domain",
      "value": "'$AD_PRINC_DIR'"
    },
    {
      "name": "ad_delete_on_regenerate",
      "value": "true"
    },
    {
      "name": "ad_set_encryption_types",
      "value": "true"
    },
    {
      "name": "security_realm",
      "value": "'$AD_REALM'"
    },
    {
      "name": "kdc_host",
      "value": "'$AD_KDC_SERVER_HOST'"
    },
    {
      "name": "kdc_admin_host",
      "value": "'$AD_KDC_SERVER_HOST'"
    },
    {
      "name": "krb_manage_krb5_conf",
      "value": "true"
    }
  ]
}' "$CM_URL/api/$CM_API_V/cm/config"

# To enable Kerberos button in CM UI
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/$CM_API_V/clusters/$CM_CLUSTER_NAME/commands/configureForKerberos" -H 'Content-Type: application/json' -d '{}'

# Import kerberos Admin credentials
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/$CM_API_V/cm/commands/importAdminCredentials?password=$AD_IMPORT_PASS&username=$AD_IMPORT_USER" -H "accept: application/json"
sleep 5

############################## Cluster stop starts here ##############################

# Stop the CMS service
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/$CM_API_V/cm/service/commands/stop" && \
# Check status until CMS service is "STOPPED" or timeout after 10 minutes
{
  START_TIME=$(date +%s)  # Get the current time in seconds
  TIMEOUT=600              # 10 minutes in seconds

  while true; do
    STATUS=$(curl -s -u $CM_USERNAME:$CM_PASSWORD -k "$CM_URL/api/$CM_API_V/cm/service")
    entity_status=$(echo "$STATUS" | jq -r '.entityStatus')

    # If the entityStatus is STOPPED, break out of the loop
    if [[ "$entity_status" == "STOPPED" ]]; then
      echo "CMS Service has stopped successfully."
      break
    fi

    # Check for timeout
    if (( $(date +%s) - START_TIME >= TIMEOUT )); then
      echo "Timeout reached: CMS Service did not stop in 10 minutes. Exiting the job."
      exit 1  # Exit the script with a non-zero status
    fi

    echo "Checking if the CMS services are stopped... (10mins timeout)"
    sleep 5  # Wait for 5 seconds before checking again
  done
}

# Stop the cluster
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/$CM_API_V/clusters/$CM_CLUSTER_NAME/commands/stop" && \

# Check status until the cluster is "STOPPED" or timeout after 10 minutes
{
  START_TIME=$(date +%s)  # Get the current time in seconds
  TIMEOUT=600              # 10 minutes in seconds

  while true; do
    STATUS=$(curl -s -u $CM_USERNAME:$CM_PASSWORD -k "$CM_URL/api/$CM_API_V/clusters/$CM_CLUSTER_NAME")
    entity_status=$(echo "$STATUS" | jq -r '.entityStatus')

    # If the entityStatus is STOPPED, break out of the loop
    if [[ "$entity_status" == "STOPPED" ]]; then
      echo "Cluster has stopped successfully."
      break
    fi

    # Check for timeout
    if (( $(date +%s) - START_TIME >= TIMEOUT )); then
      echo "Timeout reached: Cluster did not stop in 10 minutes. Exiting the job."
      exit 1  # Exit the script with a non-zero status
    fi

    echo "Checking if the Cluster services are stopped... (10mins timeout)"
    sleep 5  # Wait for 5 seconds before checking again
  done
}

# Redeploy kerberos configuration for all hosts
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/$CM_API_V/clusters/$CM_CLUSTER_NAME/commands/deployClusterClientConfig" -H "Content-Type: application/json" -d '{ }'
sleep 10

# Generate kerberos credentials
curl -s -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/$CM_API_V/cm/commands/generateCredentials"
sleep 10

# Start the CMS service
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/$CM_API_V/cm/service/commands/restart" && \
# Check status until CMS service is "STARTED" or timeout after 10 minutes
{
  START_TIME=$(date +%s)  # Get the current time in seconds
  TIMEOUT=600              # 10 minutes in seconds

  while true; do
    STATUS=$(curl -s -u $CM_USERNAME:$CM_PASSWORD -k "$CM_URL/api/$CM_API_V/cm/service")
    entity_status=$(echo "$STATUS" | jq -r '.serviceState')

    # If the serviceState is STARTED, break out of the loop
    if [[ "$entity_status" == "STARTED" ]]; then
      echo "CMS Service has started successfully."
      break
    fi

    # Check for timeout
    if (( $(date +%s) - START_TIME >= TIMEOUT )); then
      echo "Timeout reached: CMS Service did not start in 10 minutes. Exiting the job."
      exit 1  # Exit the script with a non-zero status
    fi

    echo "Checking if the CMS services are started... (10mins timeout)"
    sleep 5  # Wait for 5 seconds before checking again
  done
}

# Start cluster services
curl -u $CM_USERNAME:$CM_PASSWORD -k -X POST "$CM_URL/api/$CM_API_V/clusters/$CM_CLUSTER_NAME/commands/restart" -H "Content-Type: application/json" -d '{"redeployClientConfiguration": true}' && \
# Check status until the cluster is "STARTED" or timeout after 10 minutes
{
  START_TIME=$(date +%s)  # Get the current time in seconds
  TIMEOUT=600              # 10 minutes in seconds

  while true; do
    STATUS=$(curl -s -u $CM_USERNAME:$CM_PASSWORD -k "$CM_URL/api/$CM_API_V/clusters/$CM_CLUSTER_NAME")
    entity_status=$(echo "$STATUS" | jq -r '.entityStatus')

    # If the entityStatus is STOPPED, break out of the loop
    if [[ "$entity_status" == "GOOD_HEALTH" ]]; then
      echo "Cluster has start initiated successfully."
      exit 1
    fi

    # Check for timeout
    if (( $(date +%s) - START_TIME >= TIMEOUT )); then
      echo "Timeout reached: Cluster did not stop in 10 minutes. Exiting the job."
      exit 1  # Exit the script with a non-zero status
    fi

    echo "Checking if the Cluster services are started... (10mins timeout)"
    sleep 5  # Wait for 5 seconds before checking again
  done
}
