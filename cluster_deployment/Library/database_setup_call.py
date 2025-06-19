import paramiko
from cluster_deployment.inventory import cm_and_host_details

# Define the necessary parameters
host = cm_and_host_details.host1
ssh_username = cm_and_host_details.ssh_username
ssh_password = cm_and_host_details.ssh_password

# Files to be SFTPed
local_script_path = cm_and_host_details.local_script_path
local_config_path = cm_and_host_details.local_config_path

# Path in the destination server where the scripts should be placed
destination_path = "/tmp/"

# Step 3: Copy the script to the remote host
def scp_script_to_remote():
        transport = paramiko.Transport((host, 22))
        transport.connect(username=ssh_username, password=ssh_password)
        sftp = paramiko.SFTPClient.from_transport(transport)
        sftp.put(local_script_path, destination_path + "database_setup.sh")
        sftp.put(local_config_path, destination_path + "cm_and_host_details.py")
        sftp.close()
        transport.close()
        print("Script and config copied successfully to remote host.")

# Step 4: SSH into the remote host and execute the script
def ssh_execute_script():
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh_client.connect(host, username=ssh_username, password=ssh_password)
        ssh_client.exec_command(f"chmod +x {destination_path}cm_and_host_details.py")
        ssh_client.exec_command(f"chmod +x {destination_path}database_setup.sh")
        stdin, stdout, stderr = ssh_client.exec_command(f"{destination_path}database_setup.sh")
        for line in stdout:
            print(line.strip())
        ssh_client.close()

scp_script_to_remote()
ssh_execute_script()