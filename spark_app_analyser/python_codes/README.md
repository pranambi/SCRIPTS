# Spark App Analyser

This repository contains a collection of personal scripts that analyze Spark jobs, stages and tasks in different ways. Below shows what does these scripts do:

## Scripts
- [spark_stage_duration.py](https://github.com/pranambi/MY_SCRIPTS/tree/master/spark_app_analyser/python_codes#spark_stage_durationpy)
- [spark_btw_stage_delay_INPROGRESS.py](https://github.com/pranambi/MY_SCRIPTS/tree/master/spark_app_analyser/python_codes#spark_btw_stage_delay_inprogresspy)

---

## spark_stage_duration.py

### Note:
This script will sort the Spark application stages in descending order on the basis of the stage's time duration from the Spark-Yarn application log.

### Internal Mechanism of the script:
1. Checks if a log file is passed as an argument.
2. Reads the log file and determines the date format.
3. Gets only the "Running task" and "Finished task" lines from the log file and sort it by date.
4. Extracts the first and last line from the above step to determine the first and last stage id of the job.
5. Using this first and last stage id, runs a loop for stage ids one by one:
      a) Gets the first running task and last finished task
      b) From above gets the timestamp, converts it to epoch value and then finds the difference between the time
6. After finding this difference appends the result into a variable, sorts results in descending order based on the difference.
7. Gets the top 10 results. This variable will have the details:- *`Stage ID:- {stage_id} ===> (Epoch_Diff: {difference}) Days: {days}, Hours: {hours}, Minutes: {minutes}, Seconds: {seconds}`*

### To use the script:
1. Download the script to the local machine
   ```bash
   curl -so spark_stageduration.py https://$GIT_TOKEN@raw.githubusercontent.com/pranambi/MY_SCRIPTS/master/spark_app_analyser/python_codes/spark_stage_duration.py

2. Usage:
   ```bash
   python script.py <log_file>

---

## spark_btw_stage_delay_INPROGRESS.py

### Note:
This script will sort the Spark application stages by the delay between stages finished and the next stage triggered from the Spark-Yarn application log.
> "THIS SCRIPT IS NOT COMPLETED AND STILL WORK IN PROGESS"

### Internal Mechanism of the script:
> "YET TO FILL"

### To use the script:
> "YET TO FILL"

---
