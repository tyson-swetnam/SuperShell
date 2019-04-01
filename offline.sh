#!/usr/bin/bash
#hi
init_shell() {
  echo $$ > ~/shell/shell_pid
  history -r ~/shell/script_history
  trap "goodbye" SIGINT SIGTERM
  trap "remoteExecution" SIGALRM
  # trap "displayRemoteOutput" 16
  # trap "allowRemoteConnection" 19
  # trap "endRemoteConnection" 18
  trap "handleInteractiveFile" 21
  # trap "handleTabCompletion" 23
  trap "serverTabComplete" 24
  home=${PWD##*/}
  host=$(hostname -s)
  user=$(whoami)
  connected=false 
  controlled=false 
  training=true
  clicked=false
  curr=""
  finished=true
  online=false
  # online_setup
}

# online_setup() {
#   if [ "$online" = true ]
#   then
#     set -m
#     set -o emacs;
#     bind -x '"\tc":"tab"';
#     j_pipe=/tmp/java_pipe
#     mkfifo $j_pipe
#     cat > $j_pipe &
#     echo $! > ~/shell/java_pipe_pid
#     java -jar ~/shell/TestSender.jar $user < $j_pipe > ~/shell/java_output  &
#   fi
# }

# tab() {
#   echo "Press enter to get custom tab completion results"
#   clicked=true
# }

# handleInteractiveFile() {
#   filename=$(cat filename.txt)
#   if [ "$controlled" = true ]
#   then
#     mv tmp2/"$filename" "$filename" 
#   fi
# }

# handleTabCompletion() {
#   # echo
#   # echo "---"
#   comm=$(cat command.txt)
#   cat completions.txt > ".$comm"
#   # echo "---"
#   # echo
#   return
#   # echo "source complete.sh completions2.txt command2.txt"
#   # ./complete.sh completions2.txt command2.txt 
#   # source complete.sh completions2.txt command2.txt 
# }

# serverTabComplete() {
#   comm=$(cat commandComplete.txt)
#   server_compl=$(cat completionsComplete.txt)
#   # echo "command: $comm"
#   echo "Possible completions:"
#   echo "$server_compl"
#   finished=true
# }

print_output() {
  cat ~/shell/output.txt
}

# displayRemoteOutput() {
#   echo ''
#   print_output 
#   print_prompt
#   echo -n "$prompt "
# }

# allowRemoteConnection() {
#   echo "connection started"
#   controlled=true
# }

# endRemoteConnection() {
#   echo "connection finished"
#   controlled=false
# }

goodbye (){
   history -w ~/shell/script_history
   # kill $(cat ~/shell/java_pipe_pid)
   # pkill -f TestSender
   # rm ~/shell/java_output
   # rm $j_pipe
   # rm ~/shell/java_pipe_pid
   rm ~/shell/shell_pid
   # rm ~/shell/testCommands.txt
   # rm ~/shell/output.txt
   rm -rf ~/shell/tmp
   echo
   exit 0
}

# evalCommand () {
#    remote=$(cat ~/shell/testCommands.txt)
#    echo "Executing remote command: $remote"
#    eval "$remote" > ~/shell/test_output
#    cat ~/shell/test_output
#    echo "output_start" > $j_pipe
#    cat ~/shell/test_output > $j_pipe
#    echo "output_end" > $j_pipe
# }

print_prompt() {
  dir=${PWD##*/}
  if [ $dir = $home ]
  then
    dir="~"
  fi
  prompt="$host:$dir $user$"
}

# remoteExecution() {
#   echo ''
#   evalCommand 
#   print_prompt
#   echo -n "$prompt "
# }

getdiff() {
  echo $old > tmp_old
  echo $new > tmp_new
  dif=$(diff tmp_old tmp_new)
  rm tmp_old
  rm tmp_new
}

getdiffNew() {
  # dif=$(diff tmp_${params[1]} ${params[1]})
  echo tmp_${params[1]} > tmp_old
  echo ${params[1]} > tmp_new
  dif=$(diff tmp_old tmp_new)
  rm tmp_old
  rm tmp_new
  rm tmp_${params[1]}
}

# sendOverFile() {
#   filename=$1
#   loc=$2
#   echo "file_start $filename" > $j_pipe
#   cat $loc > $j_pipe
#   echo "file_end" > $j_pipe
# }

# sendOverFileAndDiff() {
#   sendOverFile ${params[1]} ${params[1]} 
#   echo "output_start" > $j_pipe
#   echo "Local host executed command: $COMMANDS" > $j_pipe
#   echo "Diff after change:" > $j_pipe
#   echo $dif > $j_pipe
#   echo "output_end" > $j_pipe
# }

testForInteractive() {
  if [ ${params[0]} = "vim" ] || 
    [ ${params[0]} = "vi" ] || 
    [ ${params[0]} = "pico" ] ||
    [ ${params[0]} = "nano" ] || 
    [ ${params[0]} = "emacs" ]
  then
    interactive=1
  else 
    interactive=0
  fi
}

testForFileAndLog() {
  if [[ ${params[1]} == *"."* ]] 
  then
    cp ${params[1]} logged.txt
    echo ${params[1]} > filename.txt
  fi
}

# localInteractive() {
#   old=$(cat ${params[1]})
#   eval "$COMMANDS"
#   new=$(cat ${params[1]})
#   getdiff
#   sendOverFileAndDiff
# }

function abspath() {
    # generate absolute path from relative path
    # $1     : relative filename
    # return : absolute path
    if [ -d "$1" ]; then
         # dir
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        # file
        if [[ $1 = /* ]]; then
            absfilepath="$1"
        elif [[ $1 == */* ]]; then
            absfilepath="$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            absfilepath="$(pwd)/$1"
        fi
    fi
}

ExecuteAndUpdateStats() {
  cp ${params[1]} tmp_${params[1]}
  start=`date +%s`
  old_wc_res=$(wc -lw < ${params[1]})
  old_words=$(echo $old_wc_res | awk '{print $2}')
  old_lines=$(echo $old_wc_res | awk '{print $1}')
  eval "$COMMANDS"
  new_wc_res=$(wc -lw < ${params[1]})
  new_words=$(echo $new_wc_res | awk '{print $2}')
  new_lines=$(echo $new_wc_res | awk '{print $1}')
  end=`date +%s`
  runtime=$((end-start))
  # echo "you took $runtime seconds to edit the file"
  # echo "the word count changed from $old_words words to $new_words words"
  # echo "the number of lines changed from $old_lines lines to $new_lines lines"
  abspath ${params[1]}
  getdiffNew
}

update_stats() {
  # DIRECTORY="/tmp$(dirname $absfilepath)"
  # FILE="$(basename $absfilepath)"
  # # get directory
  # # get filename
  # echo $DIRECTORY
  # echo $FILE
  # if [ ! -d "$DIRECTORY" ]; then
  #   mkdir -p $DIRECTORY && touch $DIRECTORY/$FILE
  # fi

  # if [ ! -d "$FILE" ]; then
  #   touch $DIRECTORY/$FILE
  # fi
  if [ ! -f "/tmp/rhistory.json" ]; then
    printf '{"commands":[]}' >> "/tmp/rhistory.json"
  fi

  if [ -f "logged.txt" ]; then
   logged=$(cat logged.txt | head -1000 | sed "s/\"/\\\\\"/g")
   rm logged.txt
  else
    logged=""
  fi

  if [ -f "filename.txt" ]; then
    filename=$(cat filename.txt)
    rm filename.txt
  else
    filename=""
  fi

  if [ -f "stdout.txt" ]; then
    stdout=$(cat stdout.txt | head -1000 | sed "s/\"/\\\\\"/g")
    stderr=$(cat stderr.txt | head -1000 | sed "s/\"/\\\\\"/g")
    rm stdout.txt
    rm stderr.txt
  else
    stdout=""
    stderr=""
  fi

  DATE=$(date +%s)
  ti=$(date -j -f '%s' ${DATE} '+%Y-%m-%d:%H:%M')
  if [ "$interactive" == 0 ]
  then
      COMMANDS=$(echo $COMMANDS | sed "s/\"/\\\\\"/g")
      json='{"time": "'"$ti"'", "command":"'"${params[0]}"'","full_command":"'"$COMMANDS"'","stdout":"'"$stdout"'","stderr":"'"$stderr"'","filename":"'"$filename"'","file":"'"$logged"'"}'
  else
      diff_words=$((new_words-old_words))
      diff_lines=$((new_lines-old_lines))
      json='{"time": "'"$ti"'", "command":"'"${params[0]}"'","filename":"'"${params[1]}"'","old_wc":'"$old_words"',"new_wc":'"$new_words"',"old_l":'"$old_lines"',"new_l":'"$new_lines"',"diff_wc":'"$diff_words"',"diff_l":'"$diff_lines"',"total_time(s)":'"$runtime"',"stdout":"'"$stdout"'","stderr":"'"$stderr"'","file":"'"$logged"'"}'
  fi
  new_json=$(cat /tmp/rhistory.json | jq '.commands  += ['"$json"']' 2> /dev/null)
  if [[ ${#new_json} == 0 ]] 
  then
    return
  else 
    echo $new_json > /tmp/rhistory.json
  fi
  
  # fi
}

# remoteInteractive() {
#   old=$(cat ./tmp/${params[1]})
#   if [[ -z "${old// }" ]] 
#   then
#     echo "local host must edit or send over file to enable remote editting"
#     return 0
#   fi
#   eval "${params[0]} ./tmp/${params[1]}"
#   sendOverFile ${params[1]} ./tmp/${params[1]}
# }

# executeAndSend() {
#   testForInteractive
#   if [ "$interactive" == 0 ]
#   then
#     eval "$COMMANDS" > ~/shell/test_output
#     cat ~/shell/test_output
#     echo "output_start" > $j_pipe
#     echo "Local host executed command: $COMMANDS" > $j_pipe
#     cat ~/shell/test_output > $j_pipe
#     echo "output_end" > $j_pipe
#   else
#     localInteractive
#   fi
# }

# sendRemoteCommand() {
#   testForInteractive
#   if [ "$interactive" == 0 ]
#   then
#     echo "$COMMANDS" > $j_pipe
#   else
#     remoteInteractive
#   fi
# }

# sendCommandForTabTraining() {
#   echo "command_send" > $j_pipe
#   echo "$COMMANDS" > $j_pipe
# }

executeCommand() {
  option=$1
  # if [ "$training" = true ]
  # then
  #   sendCommandForTabTraining
  # fi

  if [ "$option" == 0 ]
  then
    interactiveExecute
  elif [ "$option" == 1 ]
  then
    executeAndSend
  elif [ "$option" == 2 ]
  then
    sendRemoteCommand
  else
    echo "executeCommand option unknown"
  fi
}

interactiveExecute() {
  testForInteractive
  if [ "$interactive" == 0 ]
  then
    eval "$COMMANDS" > stdout.txt 2>stderr.txt
    cat stdout.txt
    cat stderr.txt
  else
    ExecuteAndUpdateStats
  fi
  testForFileAndLog
  update_stats
}

# tomatch() {
#   match=$(printf " %s" "${params[@]}")
#   le=${#params[0]}
#   match=${match:2+le}
# }

# sendTabComplete() {
#   echo "tab_command_send" > $j_pipe
#   echo "$COMMANDS" > $j_pipe
# }

# completeFunction() {
#   # echo "tab complete $COMMANDS"
#   sendTabComplete
#   finished=false
#   curr=$COMMANDS
#   # params=($COMMANDS)
#   # echo "command: ${params[0]}"
#   # tomatch
#   # # echo "to match: $match"
#   # # echo "completions = $compl"
#   # IFS=$'\n' 
#   # compl_arr=( $(xargs -n1 <<< "$(cat .${params[0]})") )
#   # IFS=' '
#   # # echo ${compl_arr[0]}
#   # tabComplete
#   # IFS=' '
# }

# tabComplete() {
#   echo "Possible completions:"
#   found=false
#   compl_index=()
#   count=0
#   for option in "${compl_arr[@]}"; do
#     if [[ $option == $match* ]]
#     then
#       found=true
#       echo "($count) $option"
#       compl_index+=($option)
#       ((count+=1))
#     fi
#   done

#   if [ "$found" = false ]
#   then
#     echo "No completions found"
#     curr=$COMMANDS
#   else
#     chooseResult
#   fi
# }

# chooseResult() {
#   read -p "Pick a number corresponding with a completion " -e choice
#   # echo "you picked ${compl_index[$choice]}"
#   curr="${params[0]} ${compl_index[$choice]}"
# }

function rstats {
  yearFlag=""
  monthFlag=""
  weekFlag=""
  fileFlag=""
  directoryFlag=""
  while test $# -gt 0; do
           case "$1" in
                -y)
                    yearFlag=true
                    shift
                    ;;
                -w)
                    weekFlag=true
                    shift
                    ;;
                -m)
                    monthFlag=true
                    shift
                    ;;
                -f)
                    shift
                    fileFlag=$1
                    shift
                    ;;
                -d)
                    shift
                    directoryFlag=$1
                    shift
                    ;;
                *)
                   echo "$1 is not a recognized flag!"
                   echo "Useage: rstats [-w | -m | -y] [-f filename | -d directory_name]"
                   return 1;
                   ;;
          esac
  done

  if [ ! -f "/tmp/rhistory.json" ]; then
    printf '{"commands":[]}' >> "/tmp/rhistory.json"
  fi

  query='.commands[]'
  if [[ ${#fileFlag} != 0 ]] 
  then
    query+=' | select(.filename == "'"$fileFlag"'")'
    echo $query
  elif [[ ${#directoryFlag} != 0 ]] 
    then
    pushd "$directoryFlag" > /dev/null
    query+=' | select(.filename == "default" '
    for f in *
    do
        query+='or .filename == "'"$f"'" '
    done
    popd > /dev/null
    query+=')'
  else
    :
  fi

  DATE=$(date +%s)
  ti=$(date -j -f '%s' ${DATE} '+%Y-%m-%d:%H:%M')

  if [[ ${#yearFlag} != 0 ]] 
  then
    DATE=$(date -v -1y +%s)
    ti=$(date -j -f '%s' ${DATE} '+%Y-%m-%d:%H:%M')
    query+=' | select(.time >= "'"$ti"'")'
  elif [[ ${#monthFlag} != 0 ]] 
    then
    DATE=$(date -v -1m +%s)
    ti=$(date -j -f '%s' ${DATE} '+%Y-%m-%d:%H:%M')
    query+=' | select(.time >= "'"$ti"'")'
  else
    DATE=$(date -v -1w +%s)
    ti=$(date -j -f '%s' ${DATE} '+%Y-%m-%d:%H:%M')
    query+=' | select(.time >= "'"$ti"'")'
  fi

  tot=$((${#fileFlag}+${#directoryFlag}+${#yearFlag}+${#monthFlag}+${#weekFlag}))
  if [[ $tot != 0 ]] 
    then
    # echo $query
    echo -n "Your "
    
    if [[ ${#yearFlag} != 0 ]]; then
      echo -n "yearly stats"
    elif [[ ${#monthFlag} != 0 ]]; then
      echo -n "monthly stats"
    else
      echo -n "weekly stats"
    fi

    if [[ ${#fileFlag} != 0 ]]; then
      echo " for file $fileFlag:"
    elif [[ ${#directoryFlag} != 0 ]]; then
      echo " for directory $directoryFlag:"
    else
      echo ":"
    fi
    echo -n "Total time: "
    seconds=$(cat /tmp/rhistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
    minutes=$(($seconds/60))
    hours=$(($minutes/60))
    
    seconds=$(($seconds%60))
    minutes=$(($minutes%60))

    if [[ $hours != 0 ]]; then
      echo -n "$hours hours "
    fi

    if [[ $minutes != 0 ]]; then
      echo -n "$minutes minutes "
    fi

    echo "$seconds seconds"

    echo -n "Lines of code: "
    cat /tmp/rhistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat /tmp/rhistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    if [[ ${#fileFlag} != 0 ]]; then
      :
    else
    echo
    files_editted=$(cat /tmp/rhistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_editted files editted:"
    cat /tmp/rhistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | .[]'
  fi
  else
   echo "Your stats:"
    echo -n "Total time: "
    seconds=$(cat /tmp/rhistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
    minutes=$(($seconds/60))
    hours=$(($minutes/60))
    
    seconds=$(($seconds%60))
    minutes=$(($minutes%60))

    if [[ $hours != 0 ]]; then
      echo -n "$hours hours "
    fi

    if [[ $minutes != 0 ]]; then
      echo -n "$minutes minutes "
    fi

    echo "$seconds seconds"

    echo -n "Lines of code: "
    cat /tmp/rhistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat /tmp/rhistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    echo
    files_editted=$(cat /tmp/rhistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_editted files editted:"
    cat /tmp/rhistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")]  | unique | .[]'
  fi
}

function rhistory {
  commandFlag=""
  fileNameFlag=""
  dateFlag=""
  while test $# -gt 0; do
           case "$1" in
                -c)
                    shift
                    commandFlag=$1
                    shift
                    ;;
                -f)
                    shift
                    fileNameFlag=$1
                    shift
                    ;;
                -d)
                    shift
                    dateFlag=$1
                    shift
                    ;;
                *)
                   echo "$1 is not a recognized flag!"
                   echo "Useage: rhistory [-f filename] [-c command] [-d start_date]"
                   echo "start_date format: YYYY[-MM[-DD]]"
                   return 1;
                   ;;
          esac
  done

  if [ ! -f "/tmp/rhistory.json" ]; then
    printf '{"commands":[]}' >> "/tmp/rhistory.json"
  fi

  query='.commands[]'
  if [[ ${#fileNameFlag} != 0 ]] 
  then
    query+=' | select(.filename == "'"$fileNameFlag"'")'
  fi

  if [[ ${#commandFlag} != 0 ]] 
    then
    query+=' | select(.command == "'"$commandFlag"'")'
  fi

  if [[ ${#dateFlag} != 0 ]] 
    then
    query+=' | select(.time >= "'"$dateFlag"'")'
  fi
  tot=$((${#dateFlag}+${#fileNameFlag}+${#commandFlag}))
  if [[ $tot != 0 ]] 
    then
    cat /tmp/rhistory.json | jq ' '"$query"' '
  else
    cat /tmp/rhistory.json | jq
  fi
  
  echo
}

init_shell
while :
  do
  # if [ "$finished" = false ]
  # then
  #   sleep .1
  #   continue
  # fi
  clicked=false
  print_prompt
  start=`date +%s`
  read -p "$prompt $curr" -e COMMANDS
  end=`date +%s`
  think_time=$((end-start))
  # echo "think time is $think_time seconds"
  COMMANDS="$curr$COMMANDS"
  curr=""
  # echo "COMMANDS: $COMMANDS"
  # if [ "$clicked" = true ]
  # then
  #   completeFunction
  #   continue
  # fi
  history -s "$COMMANDS"

  if [[ -z "${COMMANDS// }" ]] 
  then
    continue
  fi
  params=($COMMANDS)
  # if [ "$connected" = true ]
  # then
  #   if [ ${params[0]} = "rexit" ]
  #   then 
  #     echo "ending connection"
  #     echo "$COMMANDS" > $j_pipe
  #     connected=false
  #   else
  #     executeCommand 2
  #   fi
  # else 
    # if [ ${params[0]} = "rjoin" ]
    # then
    #   echo "connecting to ${params[1]}"
    #   echo "$COMMANDS" > $j_pipe
    #   connected=true
    # else
      # if [ "$controlled" = true ]
      # then
      #   if [ ${params[0]} = "rsend" ]
      #   then
      #     sendOverFile ${params[1]} ${params[1]}  
      #   else
      #     executeCommand 1
      #   fi
      # else
        if [ ${params[0]} = "rhistory" ]
        then
          $COMMANDS
        elif [ ${params[0]} = "rstats" ]
          then
          $COMMANDS
        else
          executeCommand 0
        fi
      # fi
    # fi
  # fi
  done
