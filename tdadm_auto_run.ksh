#!/bin/ksh
#
# Based on a config file, execute scripts and commands connecting to the required FID
# This script must be invoked with tdadm FID and SSH connectivity must exist to the FID with which actual script needs to be executed
#
# Config File Format
# CSTKorIncident~Task#~TargetFID~MailNotification~InvocationScript
# INC1234~1~tdadm~~ProjectCreation.ksh /tdadm/config/project_creation.cfg
# CSTK1234~1~tdadm~~tdadm_db_autotasks.ksh -TASK PASS_RESET -SYSTEM_NAME GIWS_TX -CFG /tdadm/bin/test.txt
# CSTK1234~2~tdgiwaml~~cp file1.dat file2.dat
#


. /tdadm/dotprofiles/td.dotprofile
. /tdadm/config/autotask.cfg
#tdmail_from=${LIFECYCLE}_tacadmin@$HOSTNAME
#tdmail_to=rizwan2.mohammed@citi.com



echo "================================================================================"
echo "${curr_dttm}"

if [ $# -gt 1 ]; then
        echo "illegal no of arguments.. Exit"
        exit 1
elif [ $# -eq 1 ]; then
        autorun_cfg=$1
else
        autorun_cfg="/tdadm/config/autorun.cfg"
fi

temp_cfg=${autorun_cfg}.running
if [ -f ${temp_cfg} ]; then
	echo "[WARN] ${temp_cfg} Exists. Autorun script is running from previous invocation."
	exit 1
else	
	echo "Copying the tasks from config ${autorun_cfg} to ${temp_cfg}"
	sed -i -e "/^/w ${temp_cfg}" -e "//d" ${autorun_cfg}
	head -1 ${temp_cfg} > ${autorun_cfg}
fi

i=0
while read -r line
do
        if [ $i -eq 0 ]; then
        ((i=i+1))
        else
                ref_ticket=`echo $line | cut -d'~' -f1`
		task_no=`echo $line | cut -d'~' -f2`
                fid=`echo $line | cut -d'~' -f3 | tr '[:upper:]' '[:lower:]'`
                to_mail=${tdmail_to};`echo $line | cut -d'~' -f4`
                execute_script=`echo $line | cut -d'~' -f5`
                log_file=${log_dir}/${ref_ticket}_${task_no}_${curr_dttm}.log

                echo "================================"
                echo "Reference Ticket: ${ref_ticket}"
		echo "Task ${task_no}"
                echo "FID: ${fid}"
                echo "Execution: ${execute_script}"

                echo "Reference Ticket: ${ref_ticket}" >> ${log_file} 2>&1
		echo "Task ${task_no}" >> ${log_file} 2>&1
                echo "FID: ${fid}" >> ${log_file} 2>&1
                echo "Execution: ${execute_script}" >> ${log_file} 2>&1


                if [[ .$fid = . || .${ref_ticket} = . ]]; then
                        echo "Either FID or reference ticket number is blank"
                        echo "Either FID or reference ticket number is blank" >> ${log_file} 2>&1
                        ret_code=-1
                elif [ $fid = $USER ]; then
                        echo "Executing the script as $fid"
                        ${execute_script} >> ${log_file} 2>&1
                        ret_code=$?
                else
                        echo "Connecting and Executing the script as $fid"
                        ssh -n $fid@$HOSTNAME ${execute_script} >> ${log_file} 2>&1
                        ret_code=$?
                fi

                if [ ${ret_code} -eq 0 ]; then
                        echo "[INFO] ${execute_script} Script Executed Successfully"
                        echo "[INFO] ${execute_script} Script Executed Successfully" >> ${log_file} 2>&1
                else
                        echo "[ERROR] ${execute_script} Script Execution Failed with exit code ${ret_code}"
                        echo "[ERROR] ${execute_script} Script Execution Failed with exit code ${ret_code}" >> ${log_file} 2>&1
                fi
                echo "${curr_dttm}||$line||${ret_code}" >> "/tdadm/config/autorun_history.cfg"
                sed -i '2d' ${temp_cfg}
                cat ${log_file} | mailx -s "$LIFECYCLE | $ref_ticket executed | return code ${ret_code}" -r ${tdmail_from} ${to_mail}
                echo "================================"
                ((i=i+1))
        fi
done < "${temp_cfg}"
rm -rf ${temp_cfg}
echo "================================================================================"

