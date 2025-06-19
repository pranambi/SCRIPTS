########################################################################################
# This is a script which will deploy CDP cluster according to predefined template      #
# Author: Praneeth Nambiar                                                             #
# Date: 01/May/2024                                                                    #
########################################################################################

import subprocess

# To run this script in command prompt, add the library path to PYTHONPATH
# Syntax: export PYTHONPATH=<Path to library for importing interlinked own codes>
# Eg:     export PYTHONPATH=/Users/psnambiar/Downloads/SCRIPTS/

# Call another Python script
steps = [
    (["python", "/Users/psnambiar/Downloads/SCRIPTS/cluster_deployment/Library/cluster_stop.py"], "Step 1 - Cluster Stop"),
    (["python", "/Users/psnambiar/Downloads/SCRIPTS/cluster_deployment/Library/cluster_delete.py"], "Step 2 - Cluster Delete"),
    (["sh", "/Users/psnambiar/Downloads/SCRIPTS/cluster_deployment/shell_scripts/data_dir_cleanup.sh"], "Step 3 - Directory Cleanup"),
    (["python", "/Users/psnambiar/Downloads/SCRIPTS/cluster_deployment/Library/restart_all_cm_agents.py"], "Step 4 - CM Agent restart"),
    (["python", "/Users/psnambiar/Downloads/SCRIPTS/cluster_deployment/Library/database_setup_call.py"], "Step 5 - DB Setup"),
    (["python", "/Users/psnambiar/Downloads/SCRIPTS/cluster_deployment/Library/cluster_import.py"], "Step 6 - Cluster Import Initialization"),
]

for command, description in steps:
    try:
        print(f"{description} Starting...")
        subprocess.run(command, check=True)
        print(f"{description} Completed!\n\n")
    except subprocess.CalledProcessError as e:
        print(f"Error during {description}: {e}")
        break