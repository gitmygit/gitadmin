#!/bin/ksh
##
## tdadm_purgeutil_job.ksh
## Reads from an input params file which has details in the pattern SeqNo|FilePath|FilePattern|ArchiveAge|PurgeAge
##
##


purge_cfg=$1
purge_scriptpath="/tdadm/bin/PurgeUtil/PurgeUtility/"
i=0
while read -r line
do
        if [ $i -eq 0 ]; then
        i=$i+1
        else
                export seqno=`echo $line | cut -d'|' -f1`
				export filepath=`echo $line | cut -d'|' -f2`
                export filepattern=`echo $line | cut -d'|' -f3`
                export purge_age=`echo $line | cut -d'|' -f5`
                export archive_age=`echo $line | cut -d'|' -f4`
                echo "[INFO] Starting PurgeUtil for files with pattern '${filepattern}' under Folder '${filepath}' Purge Age: '${purge_age}' Archive Age: '${archive_age}' "

  ${purge_scriptpath}/PurgeUtility_run.sh --context_param FolderPath="$filepath" --context_param FilePattern="$filepattern" --context_param PurgeDayOld="$purge_age" --context_param ArchiveDayOld="$archive_age" --context_param SeqNo="$seqno"
                                i=$i+1
        fi
done < "$purge_cfg"



