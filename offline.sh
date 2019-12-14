#!/usr/bin/bash
# Function to get initial variables set up
init_shell() {
  history -r ~/.script_history
  trap "goodbye" SIGINT SIGTERM
  home=${PWD##*/}
  host=$(hostname -s)
  user=$(whoami)
  curr=""
  cat $HOME/SuperShell/title.txt
  d=$(date +%Y-%m-%d)
  testForDate
  # compress

}

# test to see if on mac or linux system
# this date format fails on mac so if any errors then on mac.
testForDate() {
  date --date="${DATE} -1 week" +%Y-%m-%d:%H:%M >/dev/null 2>$HOME/stderr.txt 
  err=$(cat $HOME/stderr.txt)
  if [[ ${#err} != 0 ]]; then
    mac=true
  else
    mac=false
  fi
  rm $HOME/stderr.txt
  if [ ! -f "$HOME/SuperShellHistory/SuperShellHistory-${d}.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShellHistory/SuperShellHistory-${d}.json"
  fi
}

# compress(){
#   for f in $HOME/SuperShellHistory/*.json ; 
#   do 
    
#     # [ -e "$f" ] || continue
#     if ["$f" == "SuperShellHistory-${d}"] 
#       then
#         echo "$f" ; 
#     else
#       gzip -f $f
#     fi
#   done
#   # gzip -d $HOME/SuperShellHistory/SuperShellHistory-${d}.json.gz
# }

# uncompresscurrent

# saves history file and exits program
goodbye (){
   history -w ~/.script_history
   rm -rf ~/shell/var/tmp
   echo
   echo "exiting"
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
  if grep -c ${params[0]} $HOME/.interactive.txt > 0
  then
    interactive=1
  else 
    interactive=0
  fi
}

# if command involves a file then save a copy in the history
testForFileAndLog() {
  # echo "file and log"
  if [[ ${params[1]} == *"."* ]] 
  then
    cp ${params[1]} $HOME/logged.txt 2>/dev/null
    echo ${params[1]} > $HOME/filename.txt
  fi
}

# execute command and get stats on files worked on.
# this function is used to execute commands related to 
# screen based editors like vim/pico/nano
ExecuteAndUpdateStats() {
  # echo "exec and update stats " + "$COMMANDS"
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
  # d=$(date +%Y-%m-%d)
  # gzip -d $HOME/SuperShellHistory/SuperShellHistory-${d}.json.gz
  if [ ! -f "$HOME/SuperShellHistory/SuperShellHistory-${d}.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShellHistory/SuperShellHistory-${d}.json"
  fi

  if [ -f "$HOME/logged.txt" ]; then
   logged=$(cat $HOME/logged.txt | head -1000 | sed "s/\"/\\\\\"/g")
   rm $HOME/logged.txt
  else
    logged=""
  fi

  if [ -f "$HOME/filename.txt" ]; then
    filename=$(cat $HOME/filename.txt)
    rm $HOME/filename.txt
  else
    filename=""
  fi

  if [ -f "$HOME/stdout.txt" ]; then
    stdout=$(cat $HOME/stdout.txt | head -1000 | sed "s/\"/\\\\\"/g")
    # echo "head -1000 std out"
    # echo $stdout
    stderr=$(cat $HOME/stderr.txt | head -1000 | sed "s/\"/\\\\\"/g")
    rm $HOME/stdout.txt
    rm $HOME/stderr.txt
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
  new_json=$(cat $HOME/SuperShellHistory/SuperShellHistory-${d}.json | jq '.commands  += ['"$json"']' 2> /dev/null)
  if [[ ${#new_json} == 0 ]] 
  then
    return
  else 
    echo $new_json > $HOME/SuperShellHistory/SuperShellHistory-${d}.json
  fi
  # gzip $HOME/SuperShellHistory/SuperShellHistory-${d}.json
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
        eval "$COMMANDS" > $HOME/stdout.txt 2>$HOME/stderr.txt
    else
      # NOTE: This needs to be changed. This causes output of a program
      # to not get printed out until all input is received. This is due
      # to the stderr redirection. Can be solved on linux machines with
      # the commented out script command below. Should be relatively simple
      # to port to mac.
      eval "$COMMANDS" > $HOME/stdout.txt 2>$HOME/stderr.txt
   # script -q -c "$COMMANDS 2>$HOME/stderr.txt" -f /dev/null | tee       $HOME/stdout.txt
    fi 
    cat $HOME/stdout.txt 2>/dev/null
    cat $HOME/stderr.txt 2>/dev/null
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
    tm=$(date -v -1$format +%F)
  else
    ti=$(date --date="${DATE} -1 $1" +%Y-%m-%d:%H:%M)
  fi
}

# show user stats about errors in their shell usage
function rhelp {
  echo "SuperShell Help"

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

  # for f in $HOME/SuperShellHistory/*.gz ; 
  # do 
  #   gzip -d $f
  #   # echo "$f" ; 
  # done
  # jq -s '.' $HOME/SuperShellHistory/*.json > $HOME/SuperShellHistory/output.json
  # jq -s '.' $HOME/SuperShellHistory/*.json > $HOME/SuperShellHistory/SuperShellHistory.json 
  jq -s 'reduce .[] as $item ({}; . * $item)' $HOME/SuperShellHistory/*.json > $HOME/SuperShellHistory/SuperShellHistory.json
  if [ ! -f "$HOME/SuperShellHistory/SuperShellHistory.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShellHistory/SuperShellHistory.json"
  fi

  query='.commands[]'
  if [[ ${#fileFlag} != 0 ]] 
  then
    query+=' | select(.filename == "'"$fileFlag"'")'
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
  # echo $query
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
    echo "Query " $query
    echo -n "Total time: "
    seconds=$(cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
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
    cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    if [[ ${#fileFlag} != 0 ]]; then
      :
    else
    echo
    files_edited=$(cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_edited files edited:"
    cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | .[]'
  fi
  else
   echo "Your stats:"
    echo -n "Total time: "
    seconds=$(cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
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
    cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    echo
    files_edited=$(cat $HOME/SuperShellHistory/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_edited files edited:"
    cat /$HOME/SuperShellHistory/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")]  | unique | .[]'
  fi
  # echo "Compressing files..."
  # compress
}


# Show users their super shell history
function rhistory {
  # d=$(date +%Y-%m-%d)
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

  # gzip -d $HOME/SuperShellHistory/SuperShellHistory-${d}.json.gz

  if [ ! -f "$HOME/SuperShellHistory/SuperShellHistory-${d}.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShellHistory/SuperShellHistory-${d}.json"
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
      if [[ ${#dateFlag} != 0 ]] 
      then
	#because Mac dates are formatted differently...
        if [ "$mac" = true ]; then
          currentDateTs=$(date -j -f "%Y-%m-%d" $dateFlag "+%s")
          # echo "$currentDateTs"
          endDateTs=$(date -j -f "%Y-%m-%d" $d "+%s")
          offset=86400
          # gzip $HOME/SuperShellHistory/SuperShellHistory-${d}.json
          while [ "$currentDateTs" -le "$endDateTs" ]
          do
            date=$(date -j -f "%s" $currentDateTs "+%Y-%m-%d")
            # gzip -d $HOME/SuperShellHistory/SuperShellHistory-${date}.json.gz
            if [ -f "$HOME/SuperShellHistory/SuperShellHistory-${date}.json" ]; then
    			cat $HOME/SuperShellHistory/SuperShellHistory-${date}.json | jq ' '"$query"' '
  			fi
  			currentDateTs=$(($currentDateTs+$offset))
            # gzip -f $HOME/SuperShellHistory/SuperShellHistory-${date}.json
          done
        else
          currentdate=$dateFlag
          endDate=$(/bin/date --date "$d 1 day" +%Y-%m-%d)
          # gzip $HOME/SuperShellHistory/SuperShellHistory-${d}.json
          until [ "$currentdate" == "$endDate" ]
          do
          	if [ -f "$HOME/SuperShellHistory/SuperShellHistory-${currentdate}.json" ]; then
    			cat $HOME/SuperShellHistory/SuperShellHistory-${currentdate}.json | jq ' '"$query"' '
            	currentDateTs=$(($currentDateTs+$offset))
  			fi
            # gzip -d $HOME/SuperShellHistory/SuperShellHistory-${currentdate}.json.gz
            # gzip -f $HOME/SuperShellHistory/SuperShellHistory-${currentdate}.json
            currentdate=$(/bin/date --date "$currentdate 1 day" +%Y-%m-%d)
          done
        fi
      else
        cat $HOME/SuperShellHistory/SuperShellHistory-${d}.json | jq ' '"$query"' '
        # gzip -f $HOME/SuperShellHistory/SuperShellHistory-${d}.json
      fi
  else
    cat $HOME/SuperShellHistory/SuperShellHistory-${d}.json | jq
    # gzip -f $HOME/SuperShellHistory/SuperShellHistory-${d}.json
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
  elif [ ${params[0]} = "rhelp" ]
    then
    $COMMANDS
  else
    executeCommand 0
  fi
done
