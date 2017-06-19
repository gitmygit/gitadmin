#!/bin/ksh
# Created by BR39337
#
# DB  Talend DB Parameter update tasks 
# This script perform 
#	- Password Reset 
#	- Adding new SChea to parameter file 
#	- Addition of TNS entries in case of new DB
#	
# Params -
#	-TASK.Possible Values 
#		PASS_RESET
#		ADD_SCHEMA
#		ADD_TNS
#	-DB_PARAM.POSSIBLE VALUES
#		Parameter name from /tdgiw/globalparams/tnsnames.properties
#	-SYSTEM_NAME. TPAM System name
#	-SCHEMA_NAME
#	-ID_PARAM. In case parameter is created in context paramter with name different than Schema Name		
#
#####################################################################
function usage
{
    echo $3
>&2 cat <<EOF
Usage:tdadm_db_autotasks.ksh -TASK <TASK> -DB_PARAM <DB_NAME> -SYSTEM_NAME <sys_name> -USER <acc_name> -ID_PARAM <ID> -CFG <config file>
where 
       -TASK.Possible Values 
               PASS_RESET
               ADD_SCHEMA
               ADD_TNS
       -DB_PARAM.POSSIBLE VALUES
               Parameter name from /tdgiw/globalparams/tnsnames.properties
       -SYSTEM_NAME. TPAM System name
       -USER
       -ID_PARAM. In case parameter is created in context paramter with name different than Schema Name 
       -CFG.For PASS_RESET, file containing USER NAME
	     For ADD_TNS, File containing tns entry
EOF
}

function f_fetch_password {
export service_data=`${a2a_root}/a2a_webservice/ste_a2a_service/ste_a2a_service/ste_a2a_service_run.sh --context_param a2a_config=${a2a_root}/a2a_webservice/config/a2a_${sys_name}.cfg --context_param a2a_acc_name=$acc_name`

export rc=`echo $service_data | awk -F"|" '{print $1}'`                                                                  

if [[ $rc -eq 0 ]]                                                                                                       
then
	set +x 
		export service_pwd=`echo $service_data | awk -F"|" '{print $2}'`
		export encry_pwd=`sh ${pass_encry}/Password_Encryption/Password_Encryption_run.sh --context_param Password=$service_pwd`
	else
	echo $service_data | awk -F"|" '{print $2}'                                                                              
	echo "Something went wrong. Please check system name and account name."                                          
	exit 1
fi
	set -x

}

function f_db_param_backup {
cp ${db_param_file} ${db_param_file}_${curr_dttm}

}

function f_tns_file_backup {
cp ${tns_param_file} ${tns_param_file}_${curr_dttm}

}

function f_merge_context_prop {

echo "Following parameters will be added"

cat ${temp_ctx_file}

awk 'FNR==NR{a[$0]++;next}!($0 in a){print $0}' ${db_param_file} ${temp_ctx_file}>>${db_param_file}
        if [[ $?==0 ]]                                                                                                   
                then                                                                                                     
                echo "new parameters are added to context.properties"                                         
        fi                    
}

function f_sys_acc_validate {

if [ X"$sys_name" = X ]; then 
	usage "ERROR:SYSTEM Name can not be blank"
	exit 11
fi

if [ X"$acc_name" = X ]; then
	usage "ERROR:Schema name can not be blank"
	exit 12
fi
}

. /tdadm/dotprofiles/td.dotprofile
. /tdadm/config/autotask.cfg


if [[ "${DEBUG_MODE}" && "${LOGNAME}" = "tdadm" ]];then
        set -x
else
        set +x
fi

if [ X"$1" = X ]; then
    echo "No Parameters.."
   usage 
	exit 12
fi

while [[ $1 = -* ]]; do
   case $1 in
        "-TASK")
               export task=$2
			   if [[ X"$task" = X ]]; then
				echo "*** ERROR : TASK is blank"
				usage
				exit 1 
			   fi
               shift 2;;
        "-DB_PARAM")
				export db_param=$2
                shift 2;;
        "-SYSTEM_NAME")
                export sys_name=`echo $2 | tr [:lower:] [:upper:]`
                shift 2;;
	"-USER")
                export acc_name=`echo $2 | tr [:lower:] [:upper:]`
                shift 2;;
	"-ID_PARAM")
                export id_param=$2
                shift 2;;	
	"-CFG")
                export cfg=$2
                shift 2;;				
		*)
                echo "*** Invalid parameter passed ***" 
		usage
		exit 6
   esac
done

export temp_ctx_file=${globalpara_loc}/.temp_${task}_${curr_dttm}.properties
touch $temp_ctx_file
echo "TASK:" $task

case ${task} in 
	"PASS_RESET")
        	if [ ! -s "$cfg" ];then	
		   echo "ERROR: Schema Name list is empty..exiting"
	       	   usage 
		   exit 5
  		fi
  		f_db_param_backup	
  		for x in `cat $cfg`; do
		   export acc_name=$x  
		   f_sys_acc_validate
		   echo "SYSTEM_NAME:" $sys_name
		   echo "ACCOUNT_NAME:" $acc_name
		   f_fetch_password
		   echo "${acc_name}_password=${encry_pwd}" >> ${temp_ctx_file}
  		done
  		f_merge_context_prop
                for x in `cat $cfg`; do
                  export acc_name=$x
                  echo "Validating DB connection for:" $acc_name
		  ${db_util}/DBUtility/DBUtility_run.sh --context_param Schema=$acc_name --context_param cmd="select" --context_param Query="select user from dual"
                done
			
	;;
        "ADD_SCHEMA")
		if [ X"$db_param" = X ];then 
               	   echo "ERROR: DB_PARAM is empty..exiting"                                                
		   usage
                   exit 5                                                                                           
               fi                                                                                               
	       f_sys_acc_validate

               f_db_param_backup                                                                                

               echo "SYSTEM_NAME:" $sys_name                                                            
               echo "ACCOUNT_NAME:" $acc_name                                                           

               f_fetch_password                                                                         
			
	       if [ X"$id_param" = X ];then
		  echo "${acc_name}_schema=${acc_name}" >> ${temp_ctx_file}
		  echo "${acc_name}_username=${acc_name}" >> ${temp_ctx_file}
                  echo "${acc_name}_password=${encry_pwd}" >> ${temp_ctx_file}                             
		  echo "${acc_name}_alias=${db_param}" >> ${temp_ctx_file}
	       else
		  echo "${id_param}_schema=${acc_name}" >> ${temp_ctx_file}
                  echo "${id_param}_username=${acc_name}" >> ${temp_ctx_file}                              
                  echo "${id_param}_password=${encry_pwd}" >> ${temp_ctx_file}                             
                  echo "${id_param}_alias=${db_param}" >> ${temp_ctx_file}                                 
			
	       fi

               f_merge_context_prop                                                                             
			
               echo "Validating connection for Schema:" $acc_name

	       if [ X"$id_param" = X ];then
                  ${db_util}/DBUtility/DBUtility_run.sh --context_param Schema=$acc_name --context_param cmd="select" --context_param Query="select user from dual"
				
               else
                  ${db_util}/DBUtility/DBUtility_run.sh --context_param Schema=$id_param --context_param cmd="select" --context_param Query="select user from dual"

               fi
        ;;
        "ADD_TNS")
                if [ X"$db_param" = X ||  X"$cfg" = X ];then
                   echo "ERROR: DB_PARAM is empty..exiting"
                   usage
                   exit 5
               fi

                if [ ! -s "$cfg" ];then
                   echo "ERROR: TNS ENTRY FILE is empty..exiting"
                   usage
                   exit 5
                fi
	
               f_tns_param_backup

               tnsentry=`cat $cfg | tr -d '\040\011\012\015'`
	       tnsentry=${db_param}"~~jdbc:oracle:thin:@"${tnsentry}
		echo "Following TNS Entry will be added"
		echo ${tnsentry}
		echo ${tnsentry} >> ${tns_param_file}
	;;
	*) echo "TASK: ${task} is not valid...exiting"
	   usage
	   exit 20
	;;
esac

rm -f $temp_ctx_file
