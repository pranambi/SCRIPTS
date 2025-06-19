#!/bin/bash

# Source the configuration file
# Update the hostname/ip and ssh password in the below file before running this job
source /Users/psnambiar/Downloads/SCRIPTS/cluster_deployment/inventory/cm_and_host_details.py

# List of hosts
hosts=("$host1" "$host2" "$host3" "$host4")

for i in "${hosts[@]}"; do
    sshpass -p "$ssh_password" ssh root@$i "hostname && \
    rm -rf /data/dfs/dn/* && \
    rm -rf /data/dfs/nn/* && \
    rm -rf /data/yarn/nm/* && \
    rm -rf /data/dfs/jn/* && \
    rm -rf /etc/solr-infra/* && \
    rm -rf /var/log/solr-infra/audit/* && \
    rm -rf /var/lib/zookeeper/* && \
    rm -rf /var/local/kafka/data/* && \
    rm -rf /var/lib/knox/gateway/data/* && \
    rm -rf /opt/cloudera/parcel-cache/* && \
    rm -rf /opt/cloudera/parcels/* && \
    rm -rf /opt/cloudera/parcels/.flood"
done

# Changing hostname to fullname(Not verified)
#for i in "${hosts[@]}"; do
#    sshpass -p "$ssh_password" ssh root@$i "hostname && \
#    echo "$i" > /etc/hostname"
#done