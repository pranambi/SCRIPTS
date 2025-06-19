# Import the module containing the delete_cluster function
from cluster_import import fetch_api_version
from cluster_import import extract_cluster_name
from cluster_import import restart_cluster
from cluster_deployment.inventory import cm_and_host_details

# Define the necessary parameters
d_CM_USERNAME = cm_and_host_details.d_CM_USERNAME
d_CM_PASSWORD = cm_and_host_details.d_CM_PASSWORD
d_CM_URL = cm_and_host_details.d_CM_URL

# Calling the API version function
d_cm_version = fetch_api_version(d_CM_URL, d_CM_USERNAME, d_CM_PASSWORD)

# Calling Cluster name function
encoded_d_cluster_name = extract_cluster_name(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD)

# Call the restart cluster function
restart_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD, encoded_d_cluster_name)
