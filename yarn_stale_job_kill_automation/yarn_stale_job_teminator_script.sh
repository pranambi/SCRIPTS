#!/bin/bash

########################################################################################################
# Author        : Praneeth Nambiar
# Purpose       : Automatically identify and terminate long-running YARN applications in a cluster.
# Description   : Fetches running jobs from YARN ResourceManager, filters based on threshold,
#                 kills matching jobs (excluding exempted queues), logs job metadata,
#                 stores job details in MySQL, and sends notification email.
# Prerequieties : Install python
########################################################################################################

set -euo pipefail
IFS=$'\n\t'

# ========= CONFIGURATION ========= #
CONFIG_FILE="./yarn_job_cleanup.conf"
source "$CONFIG_FILE"

mkdir -p "$TMP_WORKDIR"
cp .yarn_db.cnf $TMP_WORKDIR
cd "$TMP_WORKDIR"

# ========= FUNCTIONS ========= #

pull_yarn_jobs() {
    echo "Querying YARN ResourceManager for running applications..."
    curl -s -H "Accept: application/json" "$YARN_API_ENDPOINT" \
      | python -mjson.tool \
      | egrep '"id":|"elapsedTime":|"applicationType":|"queue":|"user":|"progress":|"startedTime":|"state":|"clusterId":|"clusterUsagePercentage":|"diagnostics":|"finalStatus":|"logAggregationStatus":|"memorySeconds"' \
      > raw_yarn_data.json
}

extract_exceeding_jobs() {
    echo "" > matched_jobs.json
    for time in $(grep '"elapsedTime"' raw_yarn_data.json | grep -o '[0-9]\+'); do
        block=$(grep -B10 -A3 "$time" raw_yarn_data.json)
        queue=$(echo "$block" | grep '"queue"' | head -1 | cut -d '"' -f4)

        if [[ $time -gt $max_allowed_elapsed_ms && "$queue" != "$exclude_queue_name" ]]; then
            echo "$block" >> matched_jobs.json
        fi
    sed -i '' -e 's/^[ \t]*//' -e '/^$/d' matched_jobs.json
    done
}

# Convertion of time which can be used in the MySql DB and Mail
#sanitize_and_convert_times() {
#    sed 's/[",:]//g' matched_jobs.json | awk '{print $16 " " $6}' > start_time_raw.txt
#
#    while read epoch job_id; do
#        local_time=$(perl -e "print scalar localtime ($epoch / 1000)")
#        echo "$local_time $job_id"
#    done < start_time_raw.txt > job_times_human.txt
#}

terminate_jobs() {
    grep '"id"' matched_jobs.json | cut -d '"' -f4 > jobs_to_terminate.txt

    if [[ ! -s jobs_to_terminate.txt ]]; then
        echo "No jobs exceeded threshold. Exiting."
        exit 0
    fi

    echo "Jobs to be killed:"
    cat jobs_to_terminate.txt

    while read -r jobid; do
        echo "yarn application -kill "$jobid""
    done < jobs_to_terminate.txt
}

log_jobs_and_report() {
    echo "Logging to MySQL and generating report..."

    report_time=$(date +"%FT%T")
    report_file="./job_kill_report_$report_time.txt"

    i=0
    while IFS= read -r line; do
        key=$(echo "$line" | cut -d: -f1 | tr -d ' ",')
        value=$(echo "$line" | cut -d: -f2- | sed 's/[",]//g' | xargs)

        [[ "$key" == "diagnostics" ]] && continue

        fields[i]="$value"
        ((i++))

        if (( i == 13 )); then
            appid="${fields[0]}"
            user="${fields[1]}"
            queue="${fields[2]}"
            state="${fields[3]}"
            status="${fields[4]}"
            progress="${fields[5]}"
            cid="${fields[6]}"
            type="${fields[7]}"
            start="${fields[8]}"
            et="${fields[9]}"
            mem="${fields[10]}"
            cluster_usage="${fields[11]}"
            logs="${fields[12]}"

            # 1. Insert into MySQL
            echo "INSERT INTO yarn_job_details (app_id, user, queue, job_state, final_status, progress, cluster_id, app_type, start_time, elapsed_time, memory_seconds, cluster_usage, logs_status)
                  VALUES ('$appid', '$user', '$queue', '$state', '$status', '$progress', '$cid', '$type', '$start', '$et', '$mem', '$cluster_usage', '$logs');"

            # 2. Write to report file
            {
              echo "App ID       : $appid"
              echo "User         : $user"
              echo "Queue        : $queue"
              echo "App Type     : $type"
              echo "Job State    : $state"
              echo "Final Status : $status"
              echo "Progress     : $progress"
              echo "Cluster ID   : $cid"
              echo "Start Time   : $start"
              echo "Elapsed Time : $et"
              echo "Memory Secs  : $mem"
              echo "Usage %      : $cluster_usage"
              echo "Log Status   : $logs"
              echo "-------------------------------------"
            } >> "$report_file"

            i=0
            unset fields
        fi
    done < matched_jobs.json | mysql --defaults-extra-file="$MYSQL_CREDENTIAL_FILE"

    # Send report
#    mail -s "YARN Job Cleanup - $report_time" admin.monitoring@example.com < "$report_file"

    # Keep only latest 5 reports
#    ls -t job_kill_report_*.txt | tail -n +6 | xargs -r rm -f
}


clean_temp_files() {
    echo "Cleaning temp directory..."
    rm -rf "$TMP_WORKDIR"/*
}

# ========= MAIN FLOW ========= #

pull_yarn_jobs
extract_exceeding_jobs
#sanitize_and_convert_times
terminate_jobs
log_jobs_and_report
clean_temp_files

echo "YARN job cleanup completed successfully."
