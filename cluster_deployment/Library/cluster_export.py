import sys
import requests
import urllib.parse

# s_ = source cluster
# d_ = destination cluster

# Define Cloudera Manager credentials and URL for export cluster
s_CM_USERNAME = "admin"
s_CM_PASSWORD = "admin"
s_CM_URL = "http://<cm-server-node.com>:7180"

# Fetching the api version
s_cm_version = requests.get(f"{s_CM_URL}/api/version", auth=(s_CM_USERNAME, s_CM_PASSWORD)).text
print(f"Source Cluster CM Version: {s_cm_version}")

# To display cluster details
# ".text" is used to display the body of the http response
s_cluster_brief = requests.get(f"{s_CM_URL}/api/{s_cm_version}/clusters", auth=(s_CM_USERNAME, s_CM_PASSWORD))
print(s_cluster_brief.text)

# Make the API request to get cluster information
# "urllib.parse.quote" is used for percent encoding with space. Eg: Cluster 1 to Cluster%201
# "json()["items"][0]["name"]" gets the http respond body in json format and finds the name from the items.
encoded_s_cluster_name = urllib.parse.quote(requests.get(f"{s_CM_URL}/api/{s_cm_version}/clusters", auth=(s_CM_USERNAME, s_CM_PASSWORD)).json()["items"][0]["name"])
print(f"Source Cluster Name: {encoded_s_cluster_name}")

# Downloading the template from Source cluster
s_cluster_export = requests.get(f"{s_CM_URL}/api/v41/clusters/{encoded_s_cluster_name}/export", auth=(s_CM_USERNAME, s_CM_PASSWORD), verify=False)

with open("../templates/myscriptCluster1-template.json", "w") as f:
    f.write(s_cluster_export.text)
    print("Exported cluster information to ./templates/myscriptCluster1-template.json")

