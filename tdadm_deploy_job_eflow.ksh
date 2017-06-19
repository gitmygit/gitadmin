#!/bin/ksh
# Created by sg26462
#
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

export HOSTNAME=`hostname`
export curr_dt=`date '+%Y%m%d'`
export curr_dttm=`date '+%Y%m%d%H%M'`
export deploy_root="tdgiw,/tdgiw/projects
tdgiwaml,/tdgiw/aml/projects
tdgiwrcv,/tdgiw/receivables/projects
tdgiwliq,/tdgiw/liquidity/projects
tdgiwgbs,/tdgiw/gbs/projects
tdgiwgsd,/tdgiw/gsd/projects
tdgiwfwk,/tdgiw/framework/projects
tdgiwsec,/tdgiw/securities/projects
tdgiwpip,/tdgiw/pip/projects
tdgiwioa,/tdgiw/ioa/projects
tdgiwtrd,/tdgiw/trade/projects
tdefwcfg,/tdefwcfg/eflow/projects
" 
export build_job_loc=/tdefwcfg/udeploy
export tar_file=$1
export fid=`echo $tar_file | awk -F"-" '{print $1}'`
export project_name=`echo $tar_file | awk -F"-" '{print $2}'`
export data=`echo "$deploy_root" | grep $fid`
export deploy_root_loc=`echo $data | awk -F"," '{print $2}'`
export deploy_log_loc=/tdefwcfg/udeploy/log

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
	cd ${deploy_root_loc}/${project_name}/run
done

cd ${deploy_root_loc}/${project_name}/run

echo "removing temp tar file"

rm -f $tar_file	
