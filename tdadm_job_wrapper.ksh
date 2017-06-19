#!/bin/ksh
# Created by rm44349
# 
# Talend job Wrapper script
#   Set Value of TD_JVM_MIN & TD_JVM_MAX

#Monitor CPU & MEM usage of the child process
function monitor
{
ppid=$1
delay=1
ntimes=1
#while [ ${PID_RUN} -eq $ppid ]
while kill -0 $ppid 2> /dev/null
do
        {
        cpid=`pgrep -P $1`
        for x in $cpid
        do
                pdetails=`top -d $delay -b -n $ntimes -p $x | grep $x | sed -r -e "s;\s\s*; ;g" -e "s;^ *;;" | cut -d' ' -f9,10,12`
                echo "`date` $x $pdetails" >> /tmp/${ppid}_${x}_${DTDAY}.stat
        done
        }
done
}


function pre_job
{
	export PID_RUN=$$
	current_path=`pwd`
	jobname=`basename ${current_path}`
	jvm_min_count=`grep $jobname $TDJOB_JVM | cut -d"|" -f3 | wc -l`
	jvm_max_count=`grep $jobname $TDJOB_JVM | cut -d"|" -f4 | wc -l`
#JVM Setup	
	if [ $jvm_min_count == "1" ]
	then
        	export TD_JVM_MIN=`grep $jobname $TDJOB_JVM | cut -d"|" -f3`
	fi
	if [ $jvm_max_count == "1" ]
	then
        	export TD_JVM_MAX=`grep $jobname $TDJOB_JVM | cut -d"|" -f4`
	fi


#Wily Setup
	if grep -q $jobname $TDJOB_WILY
	then
		echo  "`date` [INFO] Job Monitor Active. JobName:${jobname} MIN_MEM:$TD_JVM_MIN MAX_MEM:$TD_JVM_MAX PPID=$$" >> $TDJOB_LOG
		echo  "`date` [INFO] Job Monitor Active. JobName:${jobname} MIN_MEM:$TD_JVM_MIN MAX_MEM:$TD_JVM_MAX PPID=$$"
	#WILY PARAMETERS 
	export WILY_AGENT_PATH="-javaagent:/opt/wily/introscopeagent/9.7.1.0/Agent.jar"
#	export WILY_PROFILE="-Dcom.wily.introscope.agentProfile=/opt/wily/introscopeagent/9.7.1.0/core/config/IntroscopeAgent.standalone.profile"
	export WILY_PROFILE="-Dcom.wily.introscope.agentProfile=/opt/wily/introscopeagent/9.7.1.0/core/config/ICGTBSTE.IntroscopeAgent.standalone.profile"
	export WILY_AGENT_NAME="-Dcom.wily.introscope.agent.agentName=${USER}_wily_test_trace"

	else
		export WILY_AGENT_PATH=""
		export WILY_PROFILE=""
		export WILY_AGENT_NAME=""
	fi

        echo "`date` [INFO] Job Start. JobName:${jobname} MIN_MEM:$TD_JVM_MIN MAX_MEM:$TD_JVM_MAX PPID=$$" >> $TDJOB_LOG
	echo "`date` [INFO] Job Start. JobName:${jobname} MIN_MEM:$TD_JVM_MIN MAX_MEM:$TD_JVM_MAX PPID=$$"

#Start Monitoring
#	. /tdadm/bin/tacadmin/tdadm_process_monitor.ksh ${PID_RUN} &
monitor ${PID_RUN} &
}

function post_job
{
        export PID_RUN="complete"
	echo "`date` [INFO] Job End. JobName:${jobname} MIN_MEM:$TD_JVM_MIN MAX_MEM:$TD_JVM_MAX PPID=$$" >> $TDJOB_LOG
	echo "`date` [INFO] Job End. JobName:${jobname} MIN_MEM:$TD_JVM_MIN MAX_MEM:$TD_JVM_MAX PPID=$$"
}





case $1 in
 "pre_job") pre_job 
 ;;
 "post_job") post_job
 ;;
 "monitor") monitor
 ;;
 "*") echo "Invalid Argument"
 ;;
esac

