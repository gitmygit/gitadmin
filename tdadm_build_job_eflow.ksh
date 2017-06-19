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
    echo "$3"
    >&2 cat <<EOF
		Usage: tdadm_build_job.ksh -FID <FID> -PROJECT <PROJECT> -TAG_NAME <TAG_NAME> -FOLDER <PROJECT FOLDER> -JOBLIST <PATH TO JOBLIST>
        where
        FID      - Valid Functional / Sub Functional ID
        PROJECT  - Taled Project Name as created in TAC
        TAG_NAME - TAG Name as created on TAC
	PATH_FILTER - OPTIONAL. Path of folder
	JOBLIST - OPTIONAL. Path of File containing list of jobs to be built  
EOF
}

. /tdadm/dotprofiles/td.dotprofile
export HOSTNAME=`hostname`
export curr_dt=`date '+%Y%m%d'`
export curr_dttm=`date '+%Y%m%d%H%M'`
###### Validations on Params Received ##########

while [[ $1 = -* ]]; do
   case $1 in
        "-FID")
               export fid=$2
			   if [ X"$fid" = X ]; then
				usage ""*** ERROR : FID is blank"
				exit 1 
			   fi
			   export lower_fid=`echo $fid | tr "[:upper:]" "[:lower:]"`
			   export res=`id $lower_fid`
			   if [ X"$fid" = X ]; then
				usage ""*** ERROR : id $fid is not valid "
				exit 2
			   fi
               shift 2;;
        "-PROJECT")
				export project_name=$2
				if [ X"$project_name" = X ]; then
				usage "*** ERROR : PROJECT NAME is blank existing"
				exit 3 
				fi
                shift 2;;
        "-TAG_NAME")
                export tag_nm=$2
				if [ X"$tag_nm" = X ]; then 
				usage "*** ERROR : TAG NAME is blank existing"
				exit 4 
				fi
                shift 2;;
		"-FOLDER")
                export path_filter=$2
				if [ X"$path_filter" = X ]; then
						echo "*** INFO : PATH is blank.Building jobs from main folder...."
				else 
						export path_filter="(path=$path_filter)"
				fi
                shift 2;;
		"-JOB_LIST")
                export job_list=$2
				if [ X"$job_list" = X ]; then
				echo "*** INFO : Job list is blank.Building all jobs...."
				else
					if [ ! -s "$job_list" ];then 
					usage "*** ERROR : JOB LIST File is empty or not present existing...."  
					exit 5
					fi
				for x in `cat $job_list`; do
					if [ -z "$jobname" ]; then
						export jobname="(label=$x)"
					else 
						export jobname="${jobname}or(label=$x)"
					fi
				done
#				if [ -z "$path_filter" ]; then
#					export filter="-if '$jobname'"
#				else	 
#					export filter="-if '${path_filter}and($jobname)'"
#				fi
				fi
                shift 2;;	
		"-PRODUCT_ID")
                export product_id=$2
                shift 2;;				
		
        *)
                usage "\n*** Invalid parameter passed ***" 
				exit 6
   esac
done

####### Build filer criteria####################

#*** if both folder and joblist is provided 

if [[ ! -z "$path_filter" && ! -z "$jobname" ]]; then 
	export filter="-if '${path_filter}and($jobname)'"
fi

#**** if only folder path is provided

if [[ ! -z "$path_filter" && -z "$jobname" ]]; then
        export filter="-if '${path_filter}'"
fi

#***** if only job list is provided 

if [[ -z "$path_filter" && ! -z "$jobname" ]]; then
   	export filter="-if '$jobname'"
fi


#############Build Job Script ############
export tac_url='http://sd-ef3e-ee28:8080/org.talend.administrator-6.0.1'
export cmdlin_loc=/tdefwcfg/talend-commandline
export udeploy_stage=/tdefwcfg/udeploy
export deploy_log_loc="$udeploy_stage"/log 
export build_jobscript=/tmp/${fid}_${project_name}_$$_${curr_dt}.txt
export tmp_build_dir=/tmp/${fid}_${project_name}_${tag_nm}_${curr_dttm}
export passwd=`/tdadm/bin/password_decryption/Password_Decryption/Password_Decryption_run.sh --context_param Password=d13b5f0fc88d5d85799aa62f09070e51` 

mkdir -p ${tmp_build_dir}
[ $? -ne 0 ] && "Unable to create temp deploy directory ${udeploy_stage}/${tag_nm}" && exit 10

echo "initRemote $tac_url -ul tdefwcfg@citi.com -up $passwd" > $build_jobscript
echo "logonProject -pn '$project_name' -br 'tags/$tag_nm'" >> $build_jobscript
echo "exportAllJob -dd $tmp_build_dir $filter" >>  $build_jobscript

############# Build all jobs ############

echo "Building Jobs with following options" >> ${deploy_log_loc}/${project_name}_${tag_nm}_${curr_dttm}.log
echo "HOST : $HOSTNAME FID : $fid" >> ${deploy_log_loc}/${project_name}_${tag_nm}_${curr_dttm}.log
echo "PROJECT : $project_name TAG : $tag_nm PATH : $path_filter DEPLOY TO : $tmp_build_dir" >> ${deploy_log_loc}/${project_name}_${tag_nm}_${curr_dttm}.log

echo "Building Jobs with following options" 
echo "HOST : $HOSTNAME FID : $fid" 
echo "PROJECT : $project_name TAG : $tag_nm PATH : $filter DEPLOY TO : $tmp_build_dir" 

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

