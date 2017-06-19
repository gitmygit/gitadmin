#!/bin/ksh
# Created by rm44349
# Updated by br39337 - 22 dec 2016
# Code Scan Wrapper
#
#####################################################################

# Environment Variables
. /tdadm/dotprofiles/td.dotprofile

export curr_dt=`date '+%Y%m%d'`
export curr_dttm=`date '+%Y%m%d%H%M'`

function usage
{
 echo $2
 >&2 cat <<EOF
Usage: tdadm_codescan_job.ksh <Project> <Branch> <Job Name> <Job Version> <Email_List>
 where
  Project - Name of the project
  Branch - Name of the Brnach
  Job Name - Name of the job
  Job Version - Job Version Number
  Email_List - List the Recipient Emails separated by comma
EOF
}



# Retrieve Job Parameters
if [ $# -eq 0 ]; then 
	echo -n "Enter the Project Name : "
	read project_name
	echo -n "Enter the Branch Name : "
	read branch_nm
	echo -n "Enter the Job Name : "
	read job_name
	echo -n "Enter the Job Version : "
	read job_version
	echo -n "List the Recipient Emails separated by comma : "
	read receiver_email

else 
	export project_name=$1
	export branch_nm=$2
	export job_name=$3
	export job_version=$4
	export receiver_email=$5
fi

# Validate Input Job Parameters
if [ .$project_name = . ] || [ .$branch_nm = . ] || [ .$job_name = . ] || [ .$job_version = . ] || [ .$receiver_email = . ]; then
	echo "[Error] One or more of the Input parameter is blank. Rerun the script with correct Input" && usage && exit 1
fi


export job_ref_var=${job_name}_${job_version}_$$

# Set FID
export user_name=`whoami`
echo "user name:"$user_name
export user_lastname=`grep ${user_name} /tdadm/config/talend_users.list | awk -F"|" '{print $5}'`
echo "lastname:"$user_lastname
export fid=$user_lastname
echo "fid :$fid"

case "$fid" in
        "tdgiw")
		export tac_url='http://sd-ef3e-ee28:8080/org.talend.administrator-6.0.1'
		export cmdlin_loc=/tdgiw/talend-commandline
		#export passwd=`/tdadm/bin/password_decryption/Password_Decryption/Password_Decryption_run.sh --context_param Password=0018f1fec50dae6c` 
		export passwd=tdgiw
		;;
        "tdefwcfg")
		export tac_url='http://sd-ef3e-ee28:8080/org.talend.administrator-6.0.1'
		export cmdlin_loc=/tdefwcfg/talend-commandline
		export passwd=tdefwcfg
		#export passwd=`/tdadm/bin/password_decryption/Password_Decryption/Password_Decryption_run.sh --context_param Password=d13b5f0fc88d5d85799aa62f09070e51` 
		;;
        "tdcpb")
		export tac_url='http://sd-088b-7605:8080/org.talend.administrator-6.0.1'
		export cmdlin_loc=/tdadm/talend-commandline
		export passwd=`/tdadm/bin/tacadmin/password_decryption/Password_Decryption/Password_Decryption_run.sh --context_param Password=07d612d672cddff1`
		;;
	"tdgdr")
                export tac_url='http://sd-e863-db86:8080/org.talend.administrator-6.0.1/'
		export cmdlin_loc=/tdgdr/Talend-Studio-20150908_1633-V6.0.1_1
		export passwd=`/tdadm/bin/password_decryption/Password_Decryption/Password_Decryption_run.sh --context_param Password=400737fda12da240799aa62f09070e51`
		;;
	"tdalto")
                export tac_url='http://sd-ef3e-ee28:8080/org.talend.administrator-6.0.1/'
		export cmdlin_loc=/tdalto/talend-commandline
		export passwd=`/tdadm/bin/password_decryption/Password_Decryption/Password_Decryption_run.sh --context_param Password=b6394a89d5842565d19a78db42db09c4`
		;;	
	*)
                "\n*** Code Scanner is not performing for $fid. Contact Talend STE***" 
		exit 1
   esac

# Set Folder Paths
export temp_path=/tmp
export job_item=/${fid}/CodeScan/job_item
export scan_report=/${fid}/CodeScan/report
export scan_log=/${fid}/CodeScan/log/${job_ref_var}
export scan_script_path=/tdadm/bin/CodeScan/CodeScanner


# Export Job Items
#export tac_url='http://sd-ef3e-ee28:8080/org.talend.administrator-6.0.1'
#export cmdlin_loc=/${fid}/Talend-Studio-20150908_1633-V6.0.1
export build_jobscript=/${temp_path}/${job_ref_var}.txt
#export passwd=`/tdadm/bin/password_decryption/Password_Decryption/Password_Decryption_run.sh --context_param Password=0018f1fec50dae6c`
#export passwd=tdgiw

#Log
echo "Code Scan Request on $curr_dt"> $scan_log.log
echo "PROJECT: $project_name BRANCH: $branch_nm Job: $job_name Version: $job_version" >> $scan_log.log
echo -e "\n*******************************Starting Code Scan Wrapper*************************************************"
echo "###############Job Details##############"
echo "PROJECT: $project_name "
echo "BRANCH: $branch_nm "
echo "Job: $job_name "
echo "Version: $job_version"
echo "Job Reference Name: ${job_ref_var}"
echo -e "########################################\n\n"
echo "[Info] Extracting Job Export..."

mkdir ${temp_path}/${job_ref_var}
	[ $? -ne 0 ] && echo "Temp Folder creation failed" >> $scan_log.log && exit 1
touch $build_jobscript
	[ $? -ne 0 ] && echo "Unable to create the build script" >> $scan_log.log && exit 2

#Build Job Script to export the job
echo "initRemote $tac_url -ul ${fid}@citi.com -up $passwd" > $build_jobscript
echo "logonProject -pn '$project_name' -br 'branches/$branch_nm'" >> $build_jobscript
echo "exportItems ${temp_path}/${job_ref_var} -if (label='$job_name')and(version='$job_version')and(type=process)" >>  $build_jobscript

tmp_wrkspc=${job_ref_var}

cd $cmdlin_loc
./Talend-Studio-linux-gtk-x86_64 -nosplash -application org.talend.commandline.CommandLine -consoleLog -data $tmp_wrkspc scriptFile $build_jobscript >> $scan_log.log  2>&1

#Copy the Item file required for Code Scan
cd ${temp_path}/${job_ref_var}
export item_path=`find -name ${job_name}_${job_version}.item`
if [ .$item_path = . ]; then
	echo "[Error] Job Export Failed. Possible reason: Incorrect Job Details. Refer Log ${scan_log}.log for further details"
	rm -f ${build_jobscript}
	rm -rf ${cmdlin_loc}/${tmp_wrkspc}
	rm -rf ${temp_path}/${job_ref_var}

	exit 4
fi
cp ${item_path} ${job_item}/${job_ref_var}.item

echo -e "${cmdlin_loc}/${tmp_wrkspc}\n${temp_path}/${job_ref_var}\n${build_jobscript}"
	
#Delete Temporary Workspace
rm -f ${build_jobscript}
rm -rf ${cmdlin_loc}/${tmp_wrkspc}
rm -rf ${temp_path}/${job_ref_var}
echo -e "[Info] Temporary Export Files Deleted\n[Info] Job Export Completed" >> $scan_log.log
echo "[Info] Job Export Completed"

#Invoke the Code Scan Job
echo -e "\n[Info] Starting Code Scan..."
cd ${scan_script_path}
./CodeScanner_run.sh --context_param ItemFile_Path=${job_item} --context_param ItemFile_Name=${job_ref_var} --context_param Email_Receiver=${receiver_email} --context_param Report_Path=${scan_report} >> $scan_log.log
	[ $? -ne 0 ] && echo "[Error] Code Scan Job Failed" && exit 5

rm -f ${job_item}/${job_ref_var}.item
echo "[Info] Code Scan Completed. An email will be sent to the recipient"

#Done
