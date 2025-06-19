import time
import requests
import urllib.parse
import warnings
from urllib3.exceptions import InsecureRequestWarning
from cluster_deployment.inventory import cm_and_host_details

# Define the necessary parameters
d_CM_USERNAME = cm_and_host_details.d_CM_USERNAME
d_CM_PASSWORD = cm_and_host_details.d_CM_PASSWORD
d_CM_URL = cm_and_host_details.d_CM_URL
cluster_template_location = cm_and_host_details.cluster_template_location

# Suppress only the InsecureRequestWarning as "verify=False" is set
warnings.simplefilter('ignore', InsecureRequestWarning)

def fetch_api_version(d_CM_URL, d_CM_USERNAME, d_CM_PASSWORD):
    # Fetching the API version
    d_cm_version = requests.get(f"{d_CM_URL}/api/version", auth=(d_CM_USERNAME, d_CM_PASSWORD), verify=False).text
    return d_cm_version

def extract_cluster_name(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD):
    # To display cluster details
    # ".text" is used to display the body of the http response
    d_cluster_brief = requests.get(f"{d_CM_URL}/api/{d_cm_version}/clusters", auth=(d_CM_USERNAME, d_CM_PASSWORD), verify=False)
    # print(f"Destination cluster details:\n{d_cluster_brief.text}")

    # Extract the list of clusters from the response
    clusters = d_cluster_brief.json().get("items", [])

    if clusters:
        # Make the API request to get cluster information
        # "urllib.parse.quote" is used for percent encoding with space. Eg: Cluster 1 to Cluster%201
        # "json()["items"][0]["name"]" gets the http respond body in json format and finds the name from the items.
        encoded_d_cluster_name = urllib.parse.quote(clusters[0]["name"])
        print(f"\nDestination Cluster Name: {encoded_d_cluster_name}")
        return encoded_d_cluster_name
    else:
        print("No clusters found.")
        return None

# Cluster stop and delete function
def stop_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD, encoded_d_cluster_name):

    # Stop all services
    d_cluster_stop = requests.post(f"{d_CM_URL}/api/{d_cm_version}/clusters/{encoded_d_cluster_name}/commands/stop", auth=(d_CM_USERNAME, d_CM_PASSWORD), verify=False)

    # Check if stop command was successful
    if d_cluster_stop.status_code == 200:
        print("Stop command sent successfully. Waiting for services to stop...")

        # Check the status of the cluster until it is stopped
        while True:
            # Get the status of the cluster
            d_cluster_status = requests.get(f"{d_CM_URL}/api/{d_cm_version}/clusters/{encoded_d_cluster_name}", auth=(d_CM_USERNAME, d_CM_PASSWORD), verify=False)
            entity_status = d_cluster_status.json()["entityStatus"]

            # If the entityStatus is STOPPED, break out of the loop
            if entity_status in ["STOPPED", "NONE"]:
                print("Cluster is stopped successfully.")
                break

            # Wait for a few seconds before checking again
            time.sleep(5)
    else:
        print(f"Failed to send stop command to the cluster. Status code: {d_cluster_stop.status_code}")

    print(f"Destination Cluster Stopped.")

def delete_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD, encoded_d_cluster_name):
    # Deleting the existing cluster
    # FIX THE BUG:  of printing the "cluster is deleted" even when it is not deleted
    d_cluster_delete = requests.delete(f"{d_CM_URL}/api/{d_cm_version}/clusters/{encoded_d_cluster_name}", auth=(d_CM_USERNAME, d_CM_PASSWORD), verify=False)
    time.sleep(5)
    print(f"Existing cluster deleted {d_cluster_delete}")

def import_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD):
    # Import the template from Destination cluster
    d_cluster_import = requests.post(f"{d_CM_URL}/api/{d_cm_version}/cm/importClusterTemplate", headers={"Content-Type": "application/json"}, data=open(
        cluster_template_location, "rb").read(), auth=(d_CM_USERNAME, d_CM_PASSWORD), verify=False)
    print(f"Cluster import initiated...")

### MAIN SCRIPT STARTS HERE ###

# Main script block
if __name__ == "__main__":

    # Calling the API version function
    d_cm_version = fetch_api_version(d_CM_URL, d_CM_USERNAME, d_CM_PASSWORD)

    # Calling Cluster name function
    encoded_d_cluster_name = extract_cluster_name(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD)

    # Proceed with stop and delete cluster if available
    if encoded_d_cluster_name:
        stop_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD, encoded_d_cluster_name)
        delete_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD, encoded_d_cluster_name)
        time.sleep(10)

    # Calling import cluster function
    import_cluster(d_CM_URL, d_cm_version, d_CM_USERNAME, d_CM_PASSWORD)
