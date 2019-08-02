#!/usr/bin/bash

# Function to get initial variables set up
init_shell() {
  history -r ~/.script_history
  trap "goodbye" SIGINT SIGTERM
  home=${PWD##*/}
  host=$(hostname -s)
  user=$(whoami)
  curr=""
  testForDate
}

# test to see if on mac or linux system
# this date format fails on mac so if any errors then on mac.
testForDate() {
  date --date="${DATE} -1 week" +%Y-%m-%d:%H:%M >/dev/null 2>/var/tmp/stderr.txt 
  err=$(cat /var/tmp/stderr.txt)
  if [[ ${#err} != 0 ]]; then
    mac=true
  else
    mac=false
  fi
  rm /var/tmp/stderr.txt
}

# saves history file and exits program
goodbye (){
   history -w ~/.script_history
   rm -rf ~/shell/var/tmp
   echo
   exit 0
}

# print prompt
print_prompt() {
  dir=${PWD##*/}
  if [[ ${#dir} > 0 ]] && [ $dir = $home ]
  then
    dir="~"
  fi
  prompt="$host:$dir $user$"
}

# test to see if command is a screen based editor
# set interactivet to 1 if true, 0 if false
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

# if command involves a file then save a copy in the history
testForFileAndLog() {
  if [[ ${params[1]} == *"."* ]] 
  then
    cp ${params[1]} /var/tmp/logged.txt 2>/dev/null
    echo ${params[1]} > /var/tmp/filename.txt
  fi
}

# execute command and get stats on files worked on.
# this function is used to execute commands related to 
# screen based editors like vim/pico/nano
ExecuteAndUpdateStats() {
  cp ${params[1]} tmp_${params[1]} 2>/dev/null
  start=`date +%s`
  exists=$(cat ${params[1]} 2>/dev/null)
  if [[ ${#exists} != 0 ]]
  then
    old_wc_res=$(wc -lw < ${params[1]})
    old_words=$(echo $old_wc_res | awk '{print $2}')
    old_lines=$(echo $old_wc_res | awk '{print $1}')
  else
    old_words=0
    old_lines=0
  fi
  eval "$COMMANDS"
  new_wc_res=$(wc -lw < ${params[1]})
  new_words=$(echo $new_wc_res | awk '{print $2}')
  new_lines=$(echo $new_wc_res | awk '{print $1}')
  end=`date +%s`
  runtime=$((end-start))
}

# update rhistory with info on current command
update_stats() {
  if [ ! -f "/var/tmp/SuperShellHistory.json" ]; then
    printf '{"commands":[]}' >> "/var/tmp/SuperShellHistory.json"
  fi

  if [ -f "/var/tmp/logged.txt" ]; then
   logged=$(cat /var/tmp/logged.txt | head -1000 | sed "s/\"/\\\\\"/g")
   rm /var/tmp/logged.txt
  else
    logged=""
  fi

  if [ -f "/var/tmp/filename.txt" ]; then
    filename=$(cat /var/tmp/filename.txt)
    rm /var/tmp/filename.txt
  else
    filename=""
  fi

  if [ -f "/var/tmp/stdout.txt" ]; then
    stdout=$(cat /var/tmp/stdout.txt | head -1000 | sed "s/\"/\\\\\"/g")
    stderr=$(cat /var/tmp/stderr.txt | head -1000 | sed "s/\"/\\\\\"/g")
    rm /var/tmp/stdout.txt
    rm /var/tmp/stderr.txt
  else
    stdout=""
    stderr=""
  fi

  ti=$(date +%F:%H:%M)
  if [ "$interactive" == 0 ]
  then
      COMMANDS=$(echo $COMMANDS | sed "s/\"/\\\\\"/g")
      json='{"time": "'"$ti"'", "command":"'"${params[0]}"'","full_command":"'"$COMMANDS"'","stdout":"'"$stdout"'","stderr":"'"$stderr"'","filename":"'"$filename"'","file":"'"$logged"'"}'
  else
      diff_words=$((new_words-old_words))
      diff_lines=$((new_lines-old_lines))
      json='{"time": "'"$ti"'", "command":"'"${params[0]}"'","filename":"'"${params[1]}"'","old_wc":'"$old_words"',"new_wc":'"$new_words"',"old_l":'"$old_lines"',"new_l":'"$new_lines"',"diff_wc":'"$diff_words"',"diff_l":'"$diff_lines"',"total_time(s)":'"$runtime"',"stdout":"'"$stdout"'","stderr":"'"$stderr"'","file":"'"$logged"'"}'
  fi
  new_json=$(cat /var/tmp/SuperShellHistory.json | jq '.commands  += ['"$json"']' 2> /dev/null)
  if [[ ${#new_json} == 0 ]] 
  then
    return
  else 
    echo $new_json > /var/tmp/SuperShellHistory.json
  fi
}

# multiplex execution based off $1 param 
# NOTE: (legacy from online version)
executeCommand() {
  option=$1
  if [ "$option" == 0 ]
  then
    interactiveExecute
  else
    echo "executeCommand option unknown"
  fi
}

# execute inputted command and update history.
# test to see if command is a screen based editor like vim or a
# normal command. In either case execute the command then update
# the supershell history
# NOTE: Check comment below relating to commented out script line
interactiveExecute() {
  testForInteractive
  if [ "$interactive" == 0 ]
  then
    if [ "${params[0]}" = "cd" ] || [ "${params[0]}" = "exit" ]; then
        eval "$COMMANDS" > /var/tmp/stdout.txt 2>/var/tmp/stderr.txt
    else
      # NOTE: This needs to be changed. This causes output of a program
      # to not get printed out until all input is received. This is due
      # to the stderr redirection. Can be solved on linux machines with
      # the commented out script command below. Should be relatively simple
      # to port to mac.
      eval "$COMMANDS" > /var/tmp/stdout.txt 2>/var/tmp/stderr.txt
   # script -q -c "$COMMANDS 2>/var/tmp/stderr.txt" -f /dev/null | tee       /var/tmp/stdout.txt
    fi 
    cat /var/tmp/stdout.txt 2>/dev/null
    cat /var/tmp/stderr.txt 2>/dev/null
  else
    ExecuteAndUpdateStats
  fi
  testForFileAndLog
  update_stats
}

# get current time and store in ti variable
getDate() {
  if [ "$mac" = true ]; then
    format=$1
    format=${format:0:1}
    ti=$(date -v -1$format +%F:%H:%M)
  else
    ti=$(date --date="${DATE} -1 $1" +%Y-%m-%d:%H:%M)
  fi
}

# show user stats about their shell usage
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

  if [ ! -f "/var/tmp/SuperShellHistory.json" ]; then
    printf '{"commands":[]}' >> "/var/tmp/SuperShellHistory.json"
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

  DATE=$(date +%F)

  if [[ ${#yearFlag} != 0 ]] 
  then
    getDate year
  elif [[ ${#monthFlag} != 0 ]] 
    then
    getDate month
  else
    getDate week
  fi
  query+=' | select(.time >= "'"$ti"'")'

  tot=$((${#fileFlag}+${#directoryFlag}+${#yearFlag}+${#monthFlag}+${#weekFlag}))
  if [[ $tot != 0 ]] 
    then
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
    seconds=$(cat /var/tmp/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
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
    cat /var/tmp/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat /var/tmp/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    if [[ ${#fileFlag} != 0 ]]; then
      :
    else
    echo
    files_editted=$(cat /var/tmp/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_editted files editted:"
    cat /var/tmp/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | .[]'
  fi
  else
   echo "Your stats:"
    echo -n "Total time: "
    seconds=$(cat /var/tmp/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
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
    cat /var/tmp/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat /var/tmp/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    echo
    files_editted=$(cat /var/tmp/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_editted files editted:"
    cat /var/tmp/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")]  | unique | .[]'
  fi
}

# Show users their super shell history
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

  if [ ! -f "/var/tmp/SuperShellHistory.json" ]; then
    printf '{"commands":[]}' >> "/var/tmp/SuperShellHistory.json"
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
    cat /var/tmp/SuperShellHistory.json | jq ' '"$query"' '
  else
    cat /var/tmp/SuperShellHistory.json | jq
  fi
  
  echo
}

# start shell
init_shell

# infinite loop that serves as the interpreter
while :
  do
  print_prompt
  start=`date +%s`

  # print prompt, get user input and store in COMMANDS
  read -p "$prompt $curr" -e COMMANDS
  end=`date +%s`
  think_time=$((end-start))
  COMMANDS="$curr$COMMANDS"
  curr=""
  history -s "$COMMANDS"

  # do nothing if empty input
  if [[ -z "${COMMANDS// }" ]] 
  then
    continue
  fi

  # split on whitespace
  params=($COMMANDS)
  if [ ${params[0]} = "rhistory" ]
  then
    $COMMANDS
  elif [ ${params[0]} = "rstats" ]
    then
    $COMMANDS
  else
    executeCommand 0
  fi
done
