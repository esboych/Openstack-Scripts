#!/bin/bash -xe

SSH_OPTIONS="StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
SSH_PASSWORD="r00tme"
SSH_USER="root"
FUEL_IP=${FUEL_IP:-172.16.44.10}

SSH_CMD="sshpass -p ${SSH_PASSWORD} ssh -o ${SSH_OPTIONS} ${SSH_USER}@${FUEL_IP}"
SCP_CMD="sshpass -p r00tme scp -o ${SSH_OPTIONS} "

#Command tpo connect to Rally DB with runs results
SQL_CMD="psql postgres://rally:Ra11y@172.18.160.54/rally -c"

#The query itself with all the target jobs_ids listed
SQL_QUERY=" \"SELECT DISTINCT main.task_name, one.avg as RUN_90_Rl_RHEL, two.avg as RUN_91_Rl_Ubuntu, three.avg as RUN_104_RF_RHEL, four.avg as RUN_105_RF_RHEL,  five.avg as RUN_108_RF_Ubuntu, six.avg as RUN_109_RF_RHEL
FROM (select task_name from test_timings_summary
    WHERE (jenkins_job like '11_env_run_rally_light/90/%'
	OR jenkins_job like '11_env_run_rally_light/91/%'
	OR jenkins_job like '11_env_run_rally/108/%'
	OR jenkins_job like '11_env_run_rally/104/%'
	OR jenkins_job like '11_env_run_rally/105/%'
    )) as main
LEFT OUTER JOIN
    (select avg, jenkins_job, task_name from test_timings_summary where  jenkins_job like '11_env_run_rally_light/90/%') as one on one.task_name = main.task_name
LEFT OUTER JOIN
    (select avg, jenkins_job, task_name from test_timings_summary where  jenkins_job like '11_env_run_rally_light/91/%') as two on two.task_name = main.task_name
LEFT OUTER JOIN
    (select avg, jenkins_job, task_name from test_timings_summary where  jenkins_job like '11_env_run_rally/104/%') as three on three.task_name = main.task_name
LEFT OUTER JOIN
    (select avg, jenkins_job, task_name from test_timings_summary where  jenkins_job = '11_env_run_rally/105/33fcbe0b') as four on four.task_name = main.task_name
LEFT OUTER JOIN
    (select avg, jenkins_job, task_name from test_timings_summary where  jenkins_job like '11_env_run_rally/108/%') as five on five.task_name = main.task_name
LEFT OUTER JOIN
    (select avg, jenkins_job, task_name from test_timings_summary where  jenkins_job like '11_env_run_rally/105/%') as six on six.task_name = main.task_name
ORDER BY main.task_name;\" "

#SQL_QUERY_SMALL=" \"select task_name from test_timings_summary limit 10;\" "

#$SSH_CMD "cd .. && ls -la"
$SSH_CMD "$SQL_CMD $SQL_QUERY"