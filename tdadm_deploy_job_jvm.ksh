#!/bin/ksh
# Created by sg26462
# Modified by rm44349 - JVM Settings, deploy_root_loc path
#	Updated the Logic to retrieve the deploy_root_loc
#	Added the function to invoke /tdadm/bin/tdadm_job_wrapper.ksh pre_job before the job execution
#	Added the logic to replace Xms & Xmx values with parameters
# uDeploy Script
#
#####################################################################
## Set environment variables ##

if [ "$DEBUG_MODE" ]; then
    set -x
fi

function usage
{
    echo "$2"
    >&2 cat <<EOF
Usage: tdadm_deploy_job.ksh <PRD_NAME> <TAR FILE>
EOF
}
#Function to Update JVM. Accepts the jobname as the argument
function update_jvm
{
	jobname=$@
	cd ${deploy_root_loc}/${project_name}/run/${jobname}/${jobname}
	min_value=`cat *.sh | tr ' ' '\n' | grep Xms`
	max_value=`cat *.sh | tr ' ' '\n' | grep Xmx`	

#Add the pre_job script	
	sed -i "/${jobname}/i\. \/tdadm\/bin\/tdadm_job_wrapper.ksh pre_job" *.sh
#Replace the Xms & Xmx with parameters	
	sed -i "s@$min_value@-Xms\$TD_JVM_MIN@" *.sh
	sed -i "s@$max_value@-Xmx\$TD_JVM_MAX@ \$WILY_AGENT_PATH \$WILY_PROFILE \$WILY_AGENT_NAME@" *.sh
#Add the post_job script
	sed -i "/${jobname}/a\. \/tdadm\/bin\/tdadm_job_wrapper.ksh post_job" *.sh
	
	echo "JVM Setup Update $jobname"
}

export HOSTNAME=`hostname`
export curr_dt=`date '+%Y%m%d'`
export curr_dttm=`date '+%Y%m%d%H%M'`
#export deploy_root="tdgiw,/tdgiw/projects"

export PRD_NAME=$1
export build_job_loc=/tdgiw/udeploy/talend/$PRD_NAME
export tar_file=$2
export fid=`echo $tar_file | awk -F"-" '{print $1}'`
export project_name=`echo $tar_file | awk -F"-" '{print $2}'`
export track_name=`ls -altr /tdgiw | grep $fid | awk '{print $9}'`
#export data=`echo "$deploy_root" | grep $fid`
#export deploy_root_loc=`echo $data | awk -F"," '{print $2}'`
export deploy_root_loc="/tdgiw/${track_name}/projects"
export deploy_log_loc=/tdgiw/udeploy/log


########## Extract Jobs ##########
echo "Deploying jobs from ${build_job_loc}/${tar_file}"
echo "Deploying to ${deploy_root_loc}/${project_name}/run"

echo "copying tar file to temp location...."

cp ${build_job_loc}/${tar_file} ${deploy_root_loc}/${project_name}/run

cd ${deploy_root_loc}/${project_name}/run
echo "untaring the file..."

tar -xf $tar_file

#export tmp_dir=`echo $tar_file | awk -F'.tar' '{print $1}'`

#cd $tmp_dir

for x in `ls *.zip`; do
        export jobdir=`echo $x | sed 's/.zip//'`
        if [ -d "$jobdir" ]; then
           rm -rf $jobdir
        fi
        mkdir $jobdir
        [ $? -ne 0 ] && "Unable to create jobdir $jobdir" && exit 7
        mv ${x} $jobdir
        [ $? -ne 0 ] && "Unable to move job zip to jobdir $jobdir" && exit 8
        cd $jobdir
        unzip -q $x
        [ $? -ne 0 ] && "Unable to unzip jobdir $jobdir" && exit 9
        rm -f $x
        [ $? -ne 0 ] && "Unable to remove zip jobdir $jobdir" && exit 10
        chmod -R 755 $jobdir
        echo "deployed job $jobdir"
        update_jvm $jobdir
		cd ${deploy_root_loc}/${project_name}/run
done

cd ${deploy_root_loc}/${project_name}/run

echo "removing temp tar file"

rm -f $tar_file
