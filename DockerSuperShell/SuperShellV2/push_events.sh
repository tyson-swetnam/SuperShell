while true
do
    array=($(ls -d $HOME/SuperShell/SuperShellHistory/*))
    total='{ "commands" : [] }'
    for i in "${array[@]}"
    do
        command_list_one=$(echo $total | jq '."commands"')
        to_add=$(<$i)
        command_list_two=$(echo $to_add | jq '."commands"')
        combined=$(echo $(jq --argjson arr1 "$command_list_one" --argjson arr2 "$command_list_two" -n '$arr1 + $arr2'))
        total=$(echo $(jq --argjson combined "$combined" -n '{ "commands" : $combined }'))
    done

    logid=$1
    courseid=$(<$HOME/SuperShell/courseid.txt)
    logtype="Bash"
    machineid=$(hostname -s)
    machineid=${machineid::-4}
    sessionid="Unknown Cyverse ID"
    homeLocation='/home/jovyan/data-store/user'
    if [[ -d "$homeLocation" ]];
    then
        toCheck="${homeLocation}/*"
        for FILEPATHS in $toCheck; 
        do 
            ITEM=$(basename "$FILEPATHS")
            if [[ "$ITEM" != "shared" ]];
            then
                sessionid="$ITEM" 
            fi
        done
    fi
    log=$total
    final_log=$(echo $(jq --arg logid "$logid" --arg courseid "$courseid" \
                        --arg sessionid "$sessionid" --arg machineid "$machineid" --arg logtype "$logtype" \
                        --argjson log "$log" -n '{ "body" :  
                        { log_id : $logid,
                        machine_id : $machineid,
                        session_id : $sessionid,
                        course_id : $courseid,
                        log_type : $logtype,
                        log : $log
                        } 
                        }'))
    curl --header "Content-Type: application/json" \
        --request POST \
        --data "$(echo $final_log)" \
        https://us-south.functions.appdomain.cloud/api/v1/web/ORG-UNC-dist-seed-james_dev/cyverse/add-cyverse-log >/dev/null 2>&1
    sleep 1m
done