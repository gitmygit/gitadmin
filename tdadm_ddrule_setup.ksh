#!/bin/ksh
#
# Created by rm44349
#
# DD Rule Setup 


. /tdadm/dotprofiles/td.dotprofile
. /tdadm/config/autotask.cfg

function usage
{
 echo $2
 >&2 cat <<EOF
Usage: tdadm_ddrule_setup.ksh -TASK [ADD/REMOVE] -PARAMS INC PATTERN USER Server
 where
  -TASK 
	Possible Value ADD or REMOVE
	ADD --> To add a DD Rule
	Remove --> To Remove an existing rule
  -PARAMS
	should be followed by below params
	INC --> Relevant Incident #
	PATTERN 
	USER --> giw or giwout
	Server --> AI or App
EOF
}

if [ X"$1" = X ]; then
    echo "No Parameters.."
   usage
        exit 1
fi

while [[ $1 = -* ]]; do
   case $1 in
        "-TASK")
               export task=$2
                           if [[ X"$task" = X ]]; then
                                echo "*** ERROR : TASK is blank"
                                usage
                                exit 2
                           fi
               shift 2;;
        "-PARAMS")
                export inc=`echo $2 | tr [:lower] [:upper]`
		export pattern=$3
		export user=`echo $4 | tr [:upper] [:lower]`
		export node=`echo $5 | tr [:lower] [:upper]` 
		if [[ .${inc} = . || .${pattern} = . || .$user = . || .${node} = . ]]; then
			echo "*** ERROR : Missing Params"
			usage
			exit 3
		fi
		node_cfg=`echo "${ddrule_server}" | grep ${LIFECYCLE} | grep ${node} | awk -F"," '{print $3}'`
		[ .$node_cfg = . ] && node=$node || node=$node_cfg
		echo $node		
                shift 5;;
        *)
                echo "*** Invalid parameter passed ***"
                usage
                exit 4
   esac
done

transfer=":NDM to ${user}@${node}:(FILENAME)"
comment="###${inc} ${pattern} ${transfer} "

case $task in
	"ADD")

		sed -i "1i${comment}added\n${pattern}\n${transfer}\n\n" ${ddsetup_file}
		ret_code=$?
		if [ ${ret_code} -eq 0 ]; then
			echo "New DD Rule Added-- ${comment}"
		else
			echo "Error While adding DD Rule-- ${comment}"
			exit ${ret_code}
		fi
		;;
	"REMOVE")
		sed -i "/${pattern} ${transfer} added/ {$!N;$!N;s/\n.*/\n${comment}removed\n/;}" ${ddsetup_file}
 		ret_code=$?
                if [ ${ret_code} -eq 0 ]; then
                        echo "DD Rule Removed-- ${comment}"
                else
                        echo "Error While removing DD Rule-- ${comment}"
                        exit ${ret_code}
                fi
		;;
	*)
		echo "*** Invalid Task $task"
		usage
		exit 5
esac

	
