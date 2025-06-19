import re
import sys
import time
from datetime import datetime

#########################################################################################################################
# This script will sort the Spark application stages in desc order on the basis of stage's time duration                #
# Author: Praneeth S Nambiar                                                                                            #
# Date: 22/Sept/2024                                                                                                    #
#########################################################################################################################

# Constants
# LOG_FILE = "/Users/psnambiar/Downloads/MY_CASE_FILES/20241107145739_CaseFile__c_Files/application_1730604890151_0416"

# Check if file is passed as an argument
if len(sys.argv) < 2:
    print("Usage: python script.py <log_file>")
    sys.exit(1)

# Get the log file from command-line arguments
LOG_FILE = sys.argv[1]

# Start the timer
start_time = time.time()

print("Parsing the application log file...")

# Getting date format for the log file
with open(LOG_FILE, 'r') as file:
    lines = file.readlines()

    # Find the first line containing "Running task"
    first_numeric_line = next((line for line in lines if "Running task" in line), None)

    if first_numeric_line:
        # Remove milliseconds and what after ,
        first_line_date_format = re.split(r'[.,]', ' '.join(first_numeric_line.split()[:2]))[0]

        # print(first_numeric_line)
        # print(first_line_date_format)

        # Determine the delimiter and convert to epoch time accordingly
        if '-' in first_line_date_format:
            date_format = "%Y-%m-%d %H:%M:%S"
        elif '/' in first_line_date_format:
            date_format = "%d/%m/%y %H:%M:%S"
        else:
            print("Invalid date format")
    else:
        print("No line containing 'Running task' found.")
        sys.exit()

# print(date_format)

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
    # print(f"Analysing Stage ID - {stage_id}")
    print(f"\rAnalysing Stage ID - {stage_id}", end='', flush=True)

    # Filter lines for the current stage_id
    stage_running_tasks = [line for line in running_tasks if re.search(rf'\bstage {stage_id}\b', line)]
    stage_finished_tasks = [line for line in finished_tasks if re.search(rf'\bstage {stage_id}\b', line)]

    # Check if there's a running task and finished task for the current stage
    if not stage_running_tasks or not stage_finished_tasks:
        continue

    # Get the first running task and last finished task
    start_datetime = stage_running_tasks[0]
    end_datetime = stage_finished_tasks[-1]

    # Extract the timestamp strings
    start_time_str = re.split(r'[.,]', ' '.join(start_datetime.split()[:2]))[0]  # Remove milliseconds and what after ,
    end_time_str = re.split(r'[.,]', ' '.join(end_datetime.split()[:2]))[0]  # Remove milliseconds and what after ,

    # Determine the delimiter and convert to epoch time accordingly
    if '-' in start_time_str:
        date_format = "%Y-%m-%d %H:%M:%S"
    elif '/' in start_time_str:
        date_format = "%d/%m/%y %H:%M:%S"
    else:
        print("Invalid date format")
        continue

    # Convert to epoch time
    start_epoch = int(time.mktime(datetime.strptime(start_time_str, date_format).timetuple()))
    end_epoch = int(time.mktime(datetime.strptime(end_time_str, date_format).timetuple()))

    # Calculate the duration
    difference = end_epoch - start_epoch
    days, remainder = divmod(difference, 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, seconds = divmod(remainder, 60)

    # Append the result to the results list
    results.append((stage_id, difference, days, hours, minutes, seconds))

# Sort results in descending order based on difference
results.sort(key=lambda x: x[1], reverse=True)

print("\nRESULT - STAGE ID with most time taken:!!")
print("=========================================\n")

# Print the first 10 sorted results
for stage_id, difference, days, hours, minutes, seconds in results[:10]:
    print(f"Stage ID:- {stage_id} ===> (Epoch_Diff: {difference}) Days: {days}, Hours: {hours}, Minutes: {minutes}, Seconds: {seconds}\n")

print(f"Elapsed time: {time.time() - start_time:.2f} seconds")