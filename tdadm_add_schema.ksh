#!/bin/ksh
#
# tdadm_add_schema.ksh
# Script to generate a temp context properties files with schema details which should be appended to the existing context properties file to add new schema

function usage
{
	echo $2
	>&2 cat <<EOF
Usage: tdadm_add_schema.ksh <Schema> <Environment> <Encrypted Password>
	where 
		Schema - Schema Name to added
		Environemnt - DEV or SIT or UAT or PTE or PROD
		Encrypted Password - Encrypted Password Value
EOF
}

export schema_input=$1
export env_input=$2
export encrypt_pwd=$3
export curr_dt=`date '+%Y%m%d'`
export target_file=/tdgiw/globalparams/_tempcontext.properties.${env_input}.${curr_dt}

[ X"$1" = X ] && usage "*** ERROR : Schema is blank" && exit 1
[ X"$2" = X ] && usage "*** ERROR : Environment is blank" && exit 1
[ X"$3" = X ] && usage "*** ERROR : Password is blank" && exit 1

schema_input=`echo $schema_input | tr [a-z] [A-Z]`

username=${schema_input}_username
password=${schema_input}_password
schema=${schema_input}_schema
port=${schema_input}_port
database=${schema_input}_database
host=${schema_input}_host



case "$2" in
	"DEV") export env="$1"~"$1"~GIWD~giwdbtxd1.nam.nsroot.net~"$3"~1712
	;;
	"SIT") export env="$1"~"$1"~GIWS~giwdbtxs1.nam.nsroot.net~"$3"~1712
	;;
	"UAT") export env="$1"~"$1"~giwu1~giwvorau1u.nam.nsroot.net~"$3"~1611
	;;
	"PTE") export env="$1"~"$1"~giwpte1~giwdbtxpte1-vip.nam.nsroot.net~"$3"~1611
	;;
	"PROD") export env="$1"~"$1"~giwp1~giwvorau1p.nam.nsroot.net~"$3"~1611
	;;
	*) usage "*** Error : Invalid Environment. Accepted Environment - DEV, SIT, UAT, PTE, PROD" && exit 2
	;;
esac


echo "${username}=`echo $env | cut -d'~' -f1`">>${target_file}
echo "${schema}=`echo $env | cut -d'~' -f2`">>${target_file}
echo "${database}=`echo $env | cut -d'~' -f3`">>${target_file}
echo "${host}=`echo $env | cut -d'~' -f4`">>${target_file}
echo "${password}=`echo $env | cut -d'~' -f5`">>${target_file}
echo "${port}=`echo $env | cut -d'~' -f6`">>${target_file}

echo "${schema_input} added to the file ${target_file}. Please Verify"

