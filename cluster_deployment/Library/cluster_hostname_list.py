# Import the module containing the delete_cluster function
from cluster_import import fetch_api_version
from cluster_import import extract_cluster_name
from cluster_deployment.inventory import cm_and_host_details
import requests

# Define the necessary parameters
d_CM_USERNAME = cm_and_host_details.d_CM_USERNAME
d_CM_PASSWORD = cm_and_host_details.d_CM_PASSWORD
d_CM_URL = cm_and_host_details.d_CM_URL

# Calling the API version function
d_cm_version = fetch_api_version(d_CM_URL, d_CM_USERNAME, d_CM_PASSWORD)

# Calling Cluster name function
encoded_d_cluster_name = extract_cluster_name(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD)

# Call the host listing function
def host_listing_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD):
    # Import the template from Destination cluster
    d_host_list = requests.get(f"{d_CM_URL}/api/{d_cm_version}/clusters/{encoded_d_cluster_name}/hosts", auth=(d_CM_USERNAME, d_CM_PASSWORD))

    # Check if the request was successful
    if d_host_list.status_code == 200:
        hosts = d_host_list.json()['items']
        cluster_host_list = ""
        for i, host in enumerate(hosts, start=1):
            hostname = host['hostname']
            ip_address = host['ipAddress']
            # print(f'host{i}="{hostname}"')
            # print(f'ip_host{i}="{ip_address}"')
            cluster_host_list += f'host{i}="{hostname}"\n'
        print({cluster_host_list})
        return cluster_host_list
    else:
        print(f'Failed to retrieve hosts. Status code: {d_host_list.status_code}, Response: {d_host_list.text}')

cm_host_details = host_listing_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD)
