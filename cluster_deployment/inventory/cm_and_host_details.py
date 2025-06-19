#######################################################################################################
# This is the configuration file used in multiple python and shell scripts across this application    #
# Author: Praneeth Nambiar                                                                            #
# Date: 01/May/2024                                                                                   #
#######################################################################################################

# Define the hostname
host1="node1.domain.com"
host2="node2.domain.com"
host3="node3.domain.com"
host4="node4.domain.com"

# Node short names only used in etc_host_update.sh script
short_name_host1="cdp21"
short_name_host2="cdp22"
short_name_host3="cdp23"
short_name_host4="cdp24"

# Node IP names only used in etc_host_update.sh script
ip_host1="10.xxx.xxx.1"
ip_host2="10.xxx.xxx.2"
ip_host3="10.xxx.xxx.3"
ip_host4="10.xxx.xxx.4"

# Cloudera Manager Details
d_CM_URL="http://10.xxx.xx.1:<PORT>"
d_CM_USERNAME="admin"
d_CM_PASSWORD="<password>"

# s_ = source cluster
# d_ = destination cluster

# SSH configuration
ssh_username="root"
ssh_password="<password>"

#### BELOW ARE RELATIVELY PERMANENT SETTINGS ####

local_script_path="/Downloads/SCRIPTS/cluster_deployment/shell_scripts/database_setup.sh"
local_config_path="/Downloads/SCRIPTS/cluster_deployment/inventory/cm_and_host_details.py"

cluster_template_location="/Downloads/SCRIPTS/cluster_deployment/templates/myscriptCluster1-template.json"
