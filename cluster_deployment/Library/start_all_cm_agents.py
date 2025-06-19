########################################################################################
# This is a script will check status/start cm agent in all the cluster nodes         #
# Author: Praneeth Nambiar                                                             #
# Date: 01/May/2024                                                                    #
########################################################################################

import paramiko
from cluster_deployment.inventory import cm_and_host_details

# Define the hostname
host1 = cm_and_host_details.host1
host2 = cm_and_host_details.host2
host3 = cm_and_host_details.host3
host4 = cm_and_host_details.host4

# SSH configuration
ssh_username = cm_and_host_details.ssh_username
ssh_password = cm_and_host_details.ssh_password

# Define hostnames or IPs of the hosts
hosts = [host1, host2, host3, host4]

def start_all_cm_agents():
    for host in hosts:
            # Create SSH client
            ssh_client = paramiko.SSHClient()
            ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh_client.connect(hostname=host, username=ssh_username, password=ssh_password)
            stdin, stdout, stderr = ssh_client.exec_command("systemctl start cloudera-scm-agent")

            # Print the output of the command
            print(f"Output from {host}:")
            for line in stdout:
                print(line.strip())

            # Close the SSH connection
            ssh_client.close()
            print(f"started cloudera-scm-agent on {host}")

def status_all_cm_agents():
    for host in hosts:
        # Create SSH client
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh_client.connect(hostname=host, username=ssh_username, password=ssh_password)
        stdin, stdout, stderr = ssh_client.exec_command("systemctl status cloudera-scm-agent")

        # Print the output of the command
        print(f"\n\nOutput from {host}:")
        for line in stdout:
            print(line.strip())

        # Close the SSH connection
        ssh_client.close()

start_all_cm_agents()
# status_all_cm_agents()
