# Yarn stale Job Terminator Automation

A simple shell script utility to identify and terminate long-running YARN applications on a Hadoop cluster.

## 📌 What it does ?

This tool automatically detect YARN applications that have been running longer than a configured threshold and safely terminates them (except jobs on queues explicitly excluded). It also logs details of terminated jobs, optionally stores them in a MySQL table for tracking and drop an email to revert recipients.

## ⚙️ Configuration:

Before running the script, update the configuration file:

### `yarn_job_monitor.conf`

```ini
# Threshold in seconds (e.g., 3600 = 1 hour, 86400 = 24 hours)
threshold_limit_yarn_long_run=43200

# Queue name to exclude from termination
queue_skip_kill=llap
```

### `CREATE TABLE STATEMENT`

```
CREATE DATABASE yarn_stale_job_auto;

USE yarn_stale_job_auto;

CREATE TABLE yarn_job_details (
  app_id VARCHAR(50),
  user VARCHAR(50),
  queue VARCHAR(50),
  job_state VARCHAR(20),
  final_status VARCHAR(20),
  progress FLOAT,
  cluster_id BIGINT,
  app_type VARCHAR(20),
  start_time BIGINT,
  elapsed_time BIGINT,
  memory_seconds BIGINT,
  cluster_usage FLOAT,
  logs_status VARCHAR(50)
);
```
## 💡 How to use ?

```
chmod +x yarn_stale_job_terminator.sh
./yarn_stale_job_terminator.sh
```
