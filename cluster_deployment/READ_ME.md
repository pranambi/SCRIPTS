# How to run this script:

1. Export the cluster temple which need to be imported to new cluster from any reference cluster. Place that export template in `./templates/myscriptCluster1-template.json`
2. Update the config file "`cm_and_host_details.py`" before running this script

   - The global configuration file used in shell scripts and python code is "cm_and_host_details.py".
   - Update this file with the right hostname, IP, ssh/cm username, ssh/cm password and CM URL details.

2. Update the hostnames inside "`myscriptCluster1-template.json`".
   
   - There many configuration where hostname is hardcoded in myscriptCluster1-template.json. So find and replace all hostnames. 

3. The one click script here is "`Main_cluster_deployment_code.py`"

   - Once the config file is update as previous point run the script as you please. 


# What does this script do:

- It uses the hostname, IP, ssh/cm username, ssh/cm password and CM URL details from the config file "cm_and_host_details.py"
- First initiates stop services in cluster via API and monitor and wait till the stop is completed
- Then it delete the cluster and clean up the data directories of various services in OS.
- And cleanup already existing MariDB settings in the node1 and install and a fresh DB setup
- Atlast it uses the  "myscriptCluster1-template.json" and create a brand new Cloudera cluster


# File Definition:

- `./inventory/cm_and_host_details.py` => All the configuration details such as nodename ip, CM details, credentials etc..
- `./Library/cluster_stop.py` => It stops the cluster according to the cluster details given in './inventory/cm_and_host_details.py'
- `./Library/cluster_delete.py` => It deletes the cluster according to the cluster details given in './inventory/cm_and_host_details.py'
- `./Library/restart_all_cm_agents.py` => It restarts all the CM agents according to the host details given in './inventory/cm_and_host_details.py'
- `./Library/database_setup_call.py` => It copies the shell script './shell_scripts/database_setup.sh' to CM server node and runs the script which does the DB setup.
- `./Library/cluster_import.py` => It stops, delete and import the cluster according to the cluster details given in './inventory/cm_and_host_details.py'
- `./shell_scripts/data_dir_cleanup.sh` => It deletes the backend directories of the services
- `./shell_scripts/database_setup.sh` => This code is called in './Library/database_setup_call.py'
- `./templates/myscriptCluster1-template.json` => This location is referred as  'cluster_template_location' in './inventory/cm_and_host_details.py' which will be called in './Library/cluster_import.py'

Scripts which are not used in the main code:

- `./Library/cluster_export.py` => This is not used in the main script. It exports the cluster template and uses CM configuraiton hardcorded inside this code itself.
- `./Library/cluster_host_ip_list.py` => This is not used in the main script. It gets the hostname and ip from the cluster details given in './inventory/cm_and_host_details.py'
- 