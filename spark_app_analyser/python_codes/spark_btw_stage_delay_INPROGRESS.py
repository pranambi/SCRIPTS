import re
import sys
import time
from datetime import datetime

#########################################################################################################################
# This script will sort the Spark application by the delay between stages finished and triggered                        #
# Author: Praneeth S Nambiar                                                                                            #
# Date: 22/Sept/2024                                                                                                    #
#########################################################################################################################

# Constants
LOG_FILE = "/Users/psnambiar/Downloads/MY_CASE_FILES/application_1719137558603_16851.log"

# Start the timer
start_time = time.time()

print("Parsing the application log file...")

# Read log file and filter lines
with open(LOG_FILE, 'r') as file:
    lines = file.readlines()
    first_numeric_line = next((line for line in lines if line and line[0].isdigit()), None)
    first_line_date_format = ' '.join(first_numeric_line.split()[:2]).split('.')[0]  # Remove milliseconds

    # Determine the delimiter and convert to epoch time accordingly
    if '-' in first_line_date_format:
        date_format = "%Y-%m-%d %H:%M:%S"
    elif '/' in first_line_date_format:
        date_format = "%d/%m/%y %H:%M:%S"
    else:
        print("Invalid date format")
        exit

running_tasks = sorted(
    [line for line in lines if "Running task" in line],
    key=lambda x: (
        int(re.search(r'stage (\d+)', x).group(1)),  # Sort by stage ID
        datetime.strptime(' '.join(x.split()[:2]).split('.')[0], date_format)  # Sort by timestamp without milliseconds
    )
)

finished_tasks = sorted(
    [line for line in lines if "Finished task" in line],
    key=lambda x: (
        int(re.search(r'stage (\d+)', x).group(1)),  # Sort by stage ID
        datetime.strptime(' '.join(x.split()[:2]).split('.')[0], date_format)  # Sort by timestamp without milliseconds
    )
)

print("Application log file parsing completed!!")
print("------------------------------------------\n")

# Extract first and last stage IDs
first_stage = min(int(re.search(r'stage (\d+)', task).group(1)) for task in running_tasks)
last_stage = max(int(re.search(r'stage (\d+)', task).group(1)) for task in running_tasks)

# Print First and Last stage IDs
print(f"First Stage ID: {first_stage}")
print(f"Last Stage ID: {last_stage}")
print("------------------------------------------\n")

# Clear previous results
results = []

# with open("stage_results.txt", "w") as output_file:
for stage_id in range(first_stage, last_stage + 1):
    print(f"\rAnalysing Stage ID - {stage_id}", end='', flush=True)

    stage_finished_tasks = [line for line in finished_tasks if re.search(rf'\bstage {stage_id}\b', line)]

    # Check if there are finished tasks for the current stage
    if not stage_finished_tasks:
        continue

    # Get the last finished task for the current stage
    end_datetime = stage_finished_tasks[-1]

    # Extract the end timestamp string
    end_time_str = ' '.join(end_datetime.split()[:2]).split('.')[0]  # Remove milliseconds

    # Convert the end time of the current stage to epoch time
    end_time = datetime.strptime(end_time_str, date_format)

    # Find the next running task that occurs after the end of the current stage
    next_stage_running_tasks = [
        line for line in running_tasks
        if datetime.strptime(' '.join(line.split()[:2]).split('.')[0], date_format) > end_time
    ]

    if not next_stage_running_tasks:
        continue

    # Get the first running task that starts after the current stage finishes
    next_stage_task = next_stage_running_tasks[0]
    next_stage_id = int(re.search(r'stage (\d+)', next_stage_task).group(1))

    # Extract the start timestamp of the next stage task
    start_time_str = ' '.join(next_stage_task.split()[:2]).split('.')[0]
    start_time = datetime.strptime(start_time_str, date_format)

    # Calculate the time difference between the current stage end and the next stage start
    time_diff = start_time - end_time
    seconds = time_diff.total_seconds()
    days, remainder = divmod(seconds, 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, seconds = divmod(remainder, 60)

    # Append the result to the results list
    results.append((stage_id, next_stage_id, time_diff, int(days), int(hours), int(minutes), int(seconds)))

# Sort results in descending order based on time difference
results.sort(key=lambda x: x[2], reverse=True)

print("\nRESULT - STAGE TIME DIFFERENCES:")
print("=========================================\n")

# Print the time difference between stages
for stage_id, next_stage_id, time_diff, days, hours, minutes, seconds in results:
    print(
        f"Time delay between Stage ID:- {stage_id} and Stage ID:- {next_stage_id} ===> (Epoch_Diff: {time_diff}) Days: {days}, Hours: {hours}, Minutes: {minutes}, Seconds: {seconds}\n")

print(f"Elapsed time: {time.time() - start_time:.2f} seconds")

