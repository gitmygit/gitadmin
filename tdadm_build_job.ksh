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
    echo "$4"
    >&2 cat <<EOF
Usage: tdadm_build_job.ksh <FID> <PRODUCT_ID> <PROJECT> <TAG_NAME> <PATH FILTER> 
        where
          FID      - Valid Functional / Sub Functional ID
	  PRODUCT_ID - Valid SVN PRODUCT ID
          PROJECT  - Taled Project Name as created in TAC
          TAG_NAME - TAG Name as created on TAC
	  PATH_FILTER - OPTIONAL. Path of folder
EOF
}

. /tdadm/dotprofiles/td.dotprofile
export HOSTNAME=`hostname`
export curr_dt=`date '+%Y%m%d'`
export curr_dttm=`date '+%Y%m%d%H%M'`
export tac_url='http://sd-ef3e-ee28:8080/org.talend.administrator-6.0.1'
export cmdlin_loc=/tdgiw/talend-commandline
###### Validations on Params Received ##########
export fid=$1
[ X"$fid" = X ] && usage "*** ERROR : FID is blank existing...." && exit 1

export lower_fid=`echo $fid | tr "[:upper:]" "[:lower:]"`
export res=`id $lower_fid`
    [ X"$res" = X ] && usage "*** ERROR : id $fid is not valid " && exit 6

export prd_id=$2

export project_name=$3
[ X"$project_name" = X ] && usage "*** ERROR : PROJECT NAME is blank existing...." && exit 2

export tag_nm=$4
[ X"$tag_nm" = X ] && usage "*** ERROR : TAG NAME is blank existing...." && exit 3

export path_filter=$5
if [ X"$path_filter" = X ]; then
	echo "*** INFO : PATH is blank.Building jobs from main folder...."
else 
	export filter="-if '(path=$path_filter)'"
fi
 
#############Build Job Script ############
export udeploy_stage=/GIW_SVN_repo/deployments/talend/${prd_id}/branches
export deploy_log_loc=/GIW_SVN_repo/deployments/talend/log
export build_jobscript=/tmp/${fid}_${project_name}_$$_${curr_dt}.txt
export tmp_build_dir=/tmp/${fid}_${project_name}_${tag_nm}_${curr_dttm}
export passwd=`/tdadm/bin/password_decryption/Password_Decryption/Password_Decryption_run.sh --context_param Password=0018f1fec50dae6c` 

if [ ! -d "$udeploy_stage" ]; then 
	echo "Creating Product ID folders..."
	mkdir -p /GIW_SVN_repo/deployments/talend/${prd_id}/branches
	chmod -R 777 /GIW_SVN_repo/deployments/talend/${prd_id}/branches
	mkdir -p /GIW_SVN_repo/deployments/talend/${prd_id}/archive
	chmod -R 777 /GIW_SVN_repo/deployments/talend/${prd_id}/archive
	mkdir -p /GIW_SVN_repo/deployments/talend/${prd_id}/tags
	chmod -R 777 /GIW_SVN_repo/deployments/talend/${prd_id}/tags
fi

mkdir -p ${tmp_build_dir}
[ $? -ne 0 ] && "Unable to create temp deploy directory ${udeploy_stage}/${tag_nm}" && exit 10

echo "initRemote $tac_url -ul tdgiw@citi.com -up $passwd" > $build_jobscript
echo "logonProject -pn '$project_name' -br 'tags/$tag_nm'" >> $build_jobscript
echo "exportAllJob -dd $tmp_build_dir $filter" >>  $build_jobscript

############# Build all jobs ############

echo "Building Jobs with following options" >> ${deploy_log_loc}/${project_name}_${tag_nm}_${curr_dttm}.log
echo "HOST : $HOSTNAME FID : $fid" >> ${deploy_log_loc}/${project_name}_${tag_nm}_${curr_dttm}.log
echo "PROJECT : $project_name TAG : $tag_nm PATH : $path_filter DEPLOY TO : $tmp_build_dir" >> ${deploy_log_loc}/${project_name}_${tag_nm}_${curr_dttm}.log

echo "Building Jobs with following options" 
echo "HOST : $HOSTNAME FID : $fid" 
echo "PROJECT : $project_name TAG : $tag_nm PATH : $path_filter DEPLOY TO : $tmp_build_dir" 


export tmp_wrkspc=${fid}_${project_name}_$$_${curr_dt}

cd $cmdlin_loc

./Talend-Studio-linux-gtk-x86_64 -nosplash -application org.talend.commandline.CommandLine -consoleLog -data $tmp_wrkspc scriptFile $build_jobscript >> ${deploy_log_loc}/${project_name}_${tag_nm}_${curr_dttm}.log 2>&1

############ Post processing ############
rm -f $build_jobscript
rm -rf $tmp_wrkspc

cd ${tmp_build_dir}

export zipfile=`find . -name '*.zip' | head -n1`

if [ -z "$zipfile" ]; then
	echo "No jobs are built..."
else 
echo "Following jobs are built.."
find . -name '*.zip'
tar -cf /${udeploy_stage}/${fid}-${project_name}-${tag_nm}-${curr_dttm}.tar *.zip
[ $? -ne 0 ] && "Unable to tar temp deploy directory ${udeploy_stage}/${fid}_${project_name}_${tag_nm}_${curr_dttm}" && exit 11
echo "Tar file is create as /${udeploy_stage}/${fid}-${project_name}-${tag_nm}-${curr_dttm}.tar .."
fi

cd ..

rm -rf ${fid}_${project_name}_${tag_nm}_${curr_dttm}

echo "Please verify log to confirm build ${deploy_log_loc}/${project_name}_${tag_nm}_${curr_dttm}.log"
