#!/usr/bin/bash
#pd addition for ctrl-c
# function called by trap
kill_child() {
    # printf "Killing process      "
    #tput setaf 1
    #printf "\rSIGINT caught      "
    #tput sgr0
    #sleep 1
    #printf "\rType a command >>> "
    echo "Killed Process"
	print prompt
}
trap 'kill_child' SIGINT
#trap 'other_commands' TSTP
#trap 'other_commands' SIGTSTP
#end pd addition
# Function to get initial variables set up
init_shell() {
  history -r ~/.script_history
 # trap "goodbye" SIGINT SIGTERM
  home=${PWD##*/}
  host=$(hostname -s)
  user=$(whoami)
  logid=$(openssl rand -hex 32)
  curr=""
  #pd_addition for SuperShellHistory
  SHELL_DIRECTORY="$HOME/SuperShell/"
  if [ ! -d "$SHELL_DIRECTORY" ]; then
     mkdir $SHELL_DIRECTORY
  fi  
  HISTORY_DIRECTORY="$SHELL_DIRECTORY/SuperShellHistory"
  if [ ! -d "$HISTORY_DIRECTORY" ]; then
     mkdir $HISTORY_DIRECTORY
  fi 
  #end pd addition
  #pd addition, should make this a procedure
  TITLE_FILE=$HOME/SuperShell/title.txt
  if test -f "$TITLE_FILE"; then
    cat $TITLE_FILE
  fi
  #cat $HOME/SuperShell/title.txt
  #end pd addition
  d=$(date +%Y-%m-%d)
  testForDate
  DOW=$(date +"%u")
  #pd addition
  WELCOME_FILE=${HOME}/SuperShell/StatParam/welcomestatparam.txt
  if test -f "$WELCOME_FILE"; then
    welcome_stat_param=$(cat $WELCOME_FILE)
  fi
  MAIL_FILE=${HOME}/SuperShell/StatParam/mailstatparam.txt
  if test -f "$MAIL_FILE"; then
    mail_stat_param=$(cat $MAIL_FILE)
  fi
  #welcome_stat_param=$(cat ${HOME}/SuperShell/StatParam/welcomestatparam.txt)
  #mail_stat_param=$(cat ${HOME}/SuperShell/StatParam/mailstatparam.txt)
  #end pd addition
  # echo ${welcome_stat_param}
  # ${welcome_stat_param}
  echo "Learn more about SuperShell by entering 'sinfo'"
  # this is for sending an email on a specific day of the week (1-7) for (Mon-Sun)
  ~/.push_events.sh $logid & 
  echo "Logging your bash history automatically!"
  if [ ${DOW} == 6 ]; then
    if [[ ${SENT_MAIL} == 0 ]]; then
      ${mail_stat_param}
      # Format for command to send email from cs email
      # $(python sendmail.py "Subject"  SuperShell/mail.txt <onyen>@cs.unc.edu --recipient recipientemail@email.com)
      $(python sendmail.py "Your SuperShell Usage"  SuperShell/mail.txt shree@cs.unc.edu --recipient saumya@unc.edu)
    fi
  fi
  if [ ${DOW} == 7 ]; then
    export SENT_MAIL=0
  fi

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
  if [ ! -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json"
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
   echo "Exiting SuperShell"
   exit 0
}

# print prompt
print_prompt() {
  dir=${PWD##*/}
  if [[ ${#dir} > 0 ]] && [ "$dir" = $home ]
  then
    dir="~"
  fi
  prompt="$host:$dir $user$"
}

# test to see if command is a screen based editor
# set interactivet to 1 if true, 0 if false
testForInteractive() {
  if [ $(grep -c ${params[0]} $HOME/.interactive.txt) -gt 0 ]
  then
    interactive=1
  else 
    interactive=0
  fi
}

testForExecute() {
  if [ $(grep -c ${params[0]} $HOME/.execute.txt) -gt 0 ]
  then
    execute=1
  else 
    execute=0
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
  cp ${params[1]} .tmp_${params[1]} 2>/dev/null
  start=`date +%s`
  #allow for the general case of doing "nano" with no arguments. 
  if [[ ${params[1]} != "" ]] && [[ ${params[1]} != "-"* ]]
  then 
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
  fi
  eval "$COMMANDS"
  if [[ ${params[1]} == "" ]] || [[ ${params[1]} == "-"* ]]
  then
    new_words=0
    new_lines=0
  else
    new_wc_res=$(wc -lw < ${params[1]})
    new_words=$(echo $new_wc_res | awk '{print $2}')
    new_lines=$(echo $new_wc_res | awk '{print $1}')
  fi
  end=`date +%s`
  runtime=$((end-start))
}

# update shistory with info on current command
update_stats() {
  # d=$(date +%Y-%m-%d)
  # gzip -d $HOME/SuperShellHistory/SuperShellHistory-${d}.json.gz
  if [ ! -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json"
  fi

  if [ -f "$HOME/logged.txt" ]; then
   logged=$(cat $HOME/logged.txt | head -2000 | sed "s/\"/\\\\\"/g")
   rm $HOME/logged.txt
  else
    logged=""
  fi

  # check if command is interactive

  if [ -f "$HOME/filename.txt" ]; then
    filename=$(cat $HOME/filename.txt)
    rm $HOME/filename.txt
  else
    filename=""
  fi

  if [ "$interactive" == 1 ] && [ "$filename" != "" ]; then
    # echo "This is the last mod file"
    export LAST_MODIFIED="$filename"
  fi
  if [ "${params[0]}" == "gcc" ] && [ "$filename" != "" ]; then
    # echo "This is the last compiled file"
    export LAST_COMPILED="$filename"
  fi
  
  initial="$(echo ${params[0]} | head -c 2)"
  truncFile="${params[0]:2}"
  justName=$truncFile
  truncFile+=".c"

  if [ "$initial" == "./" ]; then
    # echo "This is the last executed file"
    export LAST_EXECUTED="$truncFile"
    export IS_EXEC_COMMAND=true
  fi
  if [ "${params[0]}" == "python" ]; then
    # echo "This is the last executed file"
    export LAST_EXECUTED="$filename"
    export IS_EXEC_COMMAND=true
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

  export LAST_STDERR="$stderr"
  export LAST_STDOUT="$stdout"
  export LAST_FILENAME="$justName"
  export LAST_COMMAND="${params[0]}"
  export LAST_FULL_COMMAND="$COMMANDS"

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
  new_json=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json | jq '.commands  += ['"$json"']' 2> /dev/null)
  if [[ ${#new_json} == 0 ]] 
  then
    return
  else 
    echo $new_json > $HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json
  fi
  # gzip $HOME/SuperShellHistory/SuperShellHistory-${d}.json
}

# recommend new command if there is std err
recommend() {
  if [ -f ${HOME}/allsuggestions.txt ] ; then
    rm ${HOME}/allsuggestions.txt
  fi
  if [ -f ${HOME}/numberedsuggestions.txt ] ; then
    rm ${HOME}/numberedsuggestions.txt
  fi
  if [ -f ${HOME}/tmpsuggestions.txt ] ; then
    rm ${HOME}/tmpsuggestions.txt
  fi
  echo "Auto Helping..."
  rule_dir=$(cat ${HOME}/SuperShell/ruledir.txt)
  for f in $HOME/SuperShell/$rule_dir/*.sh; do  
    bash "$f" -H 
    if [[ -s $HOME/tmpsuggestions.txt ]]
    then
      cat $HOME/tmpsuggestions.txt >> $HOME/allsuggestions.txt
      break
    fi
  done
  for f in $HOME/SuperShell/$rule_dir/**/*.sh; do  
    bash "$f" -H 
    if [[ -s $HOME/tmpsuggestions.txt ]]
    then
      cat $HOME/tmpsuggestions.txt >> $HOME/allsuggestions.txt
      break
    fi
  done
  if [ -f ${HOME}/allsuggestions.txt ] ; then
    # cat -b $HOME/allsuggestions.txt
    awk -v RS= '{print ++i, $0}' $HOME/allsuggestions.txt > $HOME/numberedsuggestions.txt
    cat $HOME/numberedsuggestions.txt
    read -p "Do any of these suggestions look relevant? If so, enter the number or press enter" suggestion
    echo "Try suggestion #" $suggestion
    # cat $HOME/allsuggestions.txt
  else
    echo "No help found."
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
 # echo "Executing command: $COMMANDS" 
  testForInteractive
  if [ "$interactive" == 0 ]
  then
    #echo $COMMANDS
    if [ "${params[0]}" = "cd" ] || [ "${params[0]}" = "exit" ]; then
	    #pd addition

        eval "$COMMANDS" > $HOME/stdout.txt 2>$HOME/stderr.txt
	cat $HOME/stdout.txt 2>/dev/null
		#eval "$COMMANDS" 2>$HOME/stderr.txt | tee $HOME/stdout.txt 
		#end pd addition

    else
      # NOTE: This needs to be changed. This causes output of a program
      # to not get printed out until all input is received. This is due
      # to the stderr redirection. Can be solved on linux machines with
      # the commented out script command below. Should be relatively simple
      # to port to mac.
	  #start pd addition
      #eval "$COMMANDS" > $HOME/stdout.txt 2>$HOME/stderr.txt
	  #end pd addition
	eval "$COMMANDS" 2>$HOME/stderr.txt | tee $HOME/stdout.txt 

	  #EVAL_RESULT=eval "$COMMANDS" 2>$HOME/stderr.txt | tee $HOME/stdout.txt 
	  #echo $EVAL_RESULT
   # script -q -c "$COMMANDS 2>$HOME/stderr.txt" -f /dev/null | tee       $HOME/stdout.txt
    fi 
	#pd addition
    #cat $HOME/stdout.txt 2>/dev/null
	EVAL_ERROR=$(<$HOME/stderr.txt)
	if [ -n "$EVAL_ERROR" ]; then
	    #TRUNCATED_ERROR=${EVAL_ERROR/"offline.sh: line"/""}
		TRUNCATED_ERROR=$(echo "$EVAL_ERROR" | sed "s/.*offline.sh: line ...: //")
		#echo $EVAL_ERROR
		echo $TRUNCATED_ERROR
	fi
    #cat $HOME/stderr.txt 2>/dev/null
	#end pd addition

  else
    ExecuteAndUpdateStats
  fi
  testForFileAndLog
  update_stats
  if [ $(grep -c "YES" $HOME/.supershellhelp.txt) -gt 0 ]
  then
    sshelp=1
  else
    sshelp=0
  fi

  if [ "$LAST_STDERR" != "" ];
  then
    if [ "$sshelp" == 1 ]; then
      recommend
    else
	  #start pd addition
	  HELP_MESSAGE_FILE=$HOME/.supershellhelpmessage.txt
	  if [ -f $HELP_MESSAGE_FILE ]; then
         #cat $HOME/.supershellhelpmessage.txt
		 cat $HELP_MESSAGE_FILE
	  fi
	  #end pd addition
   fi
  fi
  
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

# get info about supershell
function sinfo {
  cat $HOME/.supershellinfo.txt
}
# show user stats about errors in their shell usage
function shelp {
  echo "SuperShell Help"
  recommend

}

# show user stats about their shell usage
function sstats {
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
                -s)
                    shift
                    dateFlag=$1
                    shift
                    ;;
                *)
                   echo "$1 is not a recognized flag!"
                   echo "usage: sstats [ -w | -m | -y] [-f filename | -d directory_name] [-s start_date]"
                   echo "start_date format: YYYY[-MM[-DD]]"
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
  # jq -s 'reduce .[] as $item ({}; . * $item)' $HOME/SuperShellHistory/*.json > $HOME/SuperShellHistory/SuperShellHistory.json
  jq -s '{ commands: map(.commands[]) }' $HOME/SuperShell/SuperShellHistory/SuperShellHistory-*.json > $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json 
  if [ ! -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json"
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
  elif [[ ${#dateFlag} != 0 ]] 
    then 
      ti=$dateFlag
  else
    getDate week
  fi
  query+=' | select(.time >= "'"$ti"'")'
  tot=$((${#fileFlag}+${#directoryFlag}+${#yearFlag}+${#monthFlag}+${#weekFlag}+${#dateFlag}))
  if [[ $tot != 0 ]] 
    then
    echo -n "Your "
    
    if [[ ${#yearFlag} != 0 ]]; then
      echo -n "yearly stats"
    elif [[ ${#monthFlag} != 0 ]]; then
      echo -n "monthly stats"
    elif [[ ${#weekFlag} != 0 ]]; then
      echo -n "weekly stats"
    else
      echo -n "stats starting from " $dateFlag
    fi

    if [[ ${#fileFlag} != 0 ]]; then
      echo " for file $fileFlag:"
    elif [[ ${#directoryFlag} != 0 ]]; then
      echo " for directory $directoryFlag:"
    else
      echo ":"
    fi
    # echo "Query " $query
    echo -n "Total time: "
    seconds=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
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
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    if [[ ${#fileFlag} != 0 ]]; then
      :
    else
    echo
    files_edited=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_edited files edited:"
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | .[]'
    echo
    unique_commands=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$unique_commands unique commands (listing up to 10)"
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | .[]' | sort -R | tail -10
  
  fi
  else
   echo "Your stats:"
    echo -n "Total time: "
    seconds=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
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
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    echo
    files_edited=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_edited files edited:"
    cat /$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")]  | unique | .[]'
    unique_commands=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$unique_commands unique commands:"
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | .[]'
  fi
  # echo "Compressing files..."
  # compress
  # rm $HOME/SuperShellHistory/SuperShellHistory.json 
}

function welcome_stats {
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
                -s)
                    shift
                    dateFlag=$1
                    shift
                    ;;
                *)
                   echo "$1 is not a recognized flag!"
                   echo "Useage: sstats [ -w | -m | -y] [-f filename | -d directory_name] [-s start_date]"
                   echo "start_date format: YYYY[-MM[-DD]]"
                   return 1;
                   ;;
          esac
  done

  jq -s '{ commands: map(.commands[]) }' $HOME/SuperShell/SuperShellHistory/SuperShellHistory-*.json > $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json 
  if [ ! -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json"
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
  echo "*********************************************************"
  if [[ ${#yearFlag} != 0 ]] 
  then
    getDate year
  elif [[ ${#monthFlag} != 0 ]] 
    then
    getDate month
  elif [[ ${#dateFlag} != 0 ]] 
    then 
      ti=$dateFlag
  else
    getDate week
  fi
  query+=' | select(.time >= "'"$ti"'")'
  # echo $query
  tot=$((${#fileFlag}+${#directoryFlag}+${#yearFlag}+${#monthFlag}+${#weekFlag}+${#dateFlag}))
  if [[ $tot != 0 ]] 
    then
    echo -n "Your Supershell Stats "
    
    if [[ ${#yearFlag} != 0 ]]; then
      echo -n "this year"
    elif [[ ${#monthFlag} != 0 ]]; then
      echo -n "this month"
    elif [[ ${#weekFlag} != 0 ]]; then
      echo -n "this week"
    else
      echo -n "since " $dateFlag
    fi

    if [[ ${#fileFlag} != 0 ]]; then
      echo " for file $fileFlag:"
    elif [[ ${#directoryFlag} != 0 ]]; then
      echo " for directory $directoryFlag:"
    else
      echo ":"
    fi
    # echo "Query " $query
    echo -n "Total time: "
    seconds=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
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
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    if [[ ${#fileFlag} != 0 ]]; then
      :
    else
    echo
    files_edited=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_edited files edited:"
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | .[]'
    echo
    unique_commands=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .full_command | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$unique_commands unique commands:"
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .full_command | select(. != "" and . != ".." and . != ".")] | unique | .[]'
  fi
  else
   echo "Your stats:"
    echo -n "Total time: "
    seconds=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
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
    echo -n "commands :  "

    echo -n "Lines of code: "
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_l ) )'
    echo -n "Word count: "
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_wc) )'
    echo
    files_edited=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$files_edited files edited:"
    cat /$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")]  | unique | .[]'
    echo
    unique_commands=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$unique_commands unique commands:"  
  fi
  # echo "Compressing files..."
  # compress
  rm $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json 
  echo "*********************************************************"
}

# Show users their super shell history
function shistory {
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
                   echo "usage: shistory [-f filename] [-c command] [-d start_date]"
                   echo "start_date format: YYYY[-MM[-DD]]"
                   return 1;
                   ;;
          esac
  done

  # gzip -d $HOME/SuperShellHistory/SuperShellHistory-${d}.json.gz

  if [ ! -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json"
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
            if [ -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory-${date}.json" ]; then
    			cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory-${date}.json | jq ' '"$query"' '
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
          	if [ -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory-${currentdate}.json" ]; then
    			cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory-${currentdate}.json | jq ' '"$query"' '
            	currentDateTs=$(($currentDateTs+$offset))
  			fi
            # gzip -d $HOME/SuperShellHistory/SuperShellHistory-${currentdate}.json.gz
            # gzip -f $HOME/SuperShellHistory/SuperShellHistory-${currentdate}.json
            currentdate=$(/bin/date --date "$currentdate 1 day" +%Y-%m-%d)
          done
        fi
      else
        cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json | jq ' '"$query"' '
        # gzip -f $HOME/SuperShellHistory/SuperShellHistory-${d}.json
      fi
  else
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory-${d}.json | jq
    # gzip -f $HOME/SuperShellHistory/SuperShellHistory-${d}.json
  fi
  echo
}

function enablehelp {
  bash $HOME/SuperShell/.enable_help.sh
  echo "Enabled AutoHelp..."
}

function disablehelp {
  bash $HOME/SuperShell/.disable_help.sh
  echo "Disabled Autohelp..."
  echo "You can get help for specific commands with the 'shelp' command"
}

function mailstats {
  yearFlag=""
  monthFlag=""
  weekFlag=""
  fileFlag=""
  directoryFlag=""
  if [ -f ${HOME}/SuperShell/mail.txt ] ; then
    rm ${HOME}/SuperShell/mail.txt
  fi
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
          -s)
              shift
              dateFlag=$1
              shift
              ;;
          *)
              echo "$1 is not a recognized flag!" >> $HOME/SuperShell/mail.txt
              echo "usage: sstats [ -w | -m | -y] [-f filename | -d directory_name] [-s start_date]" >> $HOME/SuperShell/mail.txt
              echo "start_date format: YYYY[-MM[-DD]]" >> $HOME/SuperShell/mail.txt
              return 1;
              ;;
    esac
  done

  jq -s '{ commands: map(.commands[]) }' $HOME/SuperShell/SuperShellHistory/SuperShellHistory-*.json > $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json 
  if [ ! -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json"
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
  elif [[ ${#dateFlag} != 0 ]] 
    then 
      ti=$dateFlag
  else
    getDate week
  fi
  query+=' | select(.time >= "'"$ti"'")'
  # echo $ti
  echo -n "=============== ::: SuperShell Weekly Usage ::: ===============" >> $HOME/SuperShell/mail.txt
  tot=$((${#fileFlag}+${#directoryFlag}+${#yearFlag}+${#monthFlag}+${#weekFlag}+${#dateFlag}))
  if [[ $tot != 0 ]] 
    then
    echo -n "Your " >> $HOME/SuperShell/mail.txt
    
    if [[ ${#yearFlag} != 0 ]]; then
      echo -n "yearly stats" >> $HOME/SuperShell/mail.txt
    elif [[ ${#monthFlag} != 0 ]]; then
      echo -n "monthly stats" >> $HOME/SuperShell/mail.txt
    elif [[ ${#weekFlag} != 0 ]]; then
      echo -n "weekly stats" >> $HOME/SuperShell/mail.txt
    else
      echo -n "stats starting from " $dateFlag >> $HOME/SuperShell/mail.txt
    fi

    if [[ ${#fileFlag} != 0 ]]; then
      echo " for file $fileFlag:" >> $HOME/SuperShell/mail.txt
    elif [[ ${#directoryFlag} != 0 ]]; then
      echo " for directory $directoryFlag:" >> $HOME/SuperShell/mail.txt
    else
      echo ":" >> $HOME/SuperShell/mail.txt
    fi
    # echo "Query " $query
    echo -n ">  Total time: " >> $HOME/SuperShell/mail.txt
    seconds=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
    minutes=$(($seconds/60))
    hours=$(($minutes/60))
    
    seconds=$(($seconds%60))
    minutes=$(($minutes%60))

    if [[ $hours != 0 ]]; then
      echo -n "$hours hours " >> $HOME/SuperShell/mail.txt
    fi

    if [[ $minutes != 0 ]]; then
      echo -n "$minutes minutes " >> $HOME/SuperShell/mail.txt
    fi

    echo "$seconds seconds" >> $HOME/SuperShell/mail.txt

    echo -n ">  Lines of code: " >> $HOME/SuperShell/mail.txt
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_l ) )' >> $HOME/SuperShell/mail.txt
    echo -n ">  Word count: " >> $HOME/SuperShell/mail.txt
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"'] | reduce .[] as $row (0; . + ($row|.diff_wc) )' >> $HOME/SuperShell/mail.txt
    if [[ ${#fileFlag} != 0 ]]; then
      :
    else
    echo >> $HOME/SuperShell/mail.txt
    files_edited=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "****************************************************************" >> $HOME/SuperShell/mail.txt
    echo "$files_edited files edited:" >> $HOME/SuperShell/mail.txt
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .filename | select(. != "" and . != ".." and . != ".")] | unique | .[]' | nl >> $HOME/SuperShell/mail.txt
    echo >> $HOME/SuperShell/mail.txt
    unique_commands=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "$unique_commands unique commands:" >> $HOME/SuperShell/mail.txt
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | .[]' | nl >> $HOME/SuperShell/mail.txt
  
  fi
  else
    echo >> $HOME/SuperShell/mail.txt
    echo "Your stats:" >> $HOME/SuperShell/mail.txt
    echo -n ">  Total time: " >> $HOME/SuperShell/mail.txt
    seconds=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|."total_time(s)") )')
    minutes=$(($seconds/60))
    hours=$(($minutes/60))
    
    seconds=$(($seconds%60))
    minutes=$(($minutes%60))

    if [[ $hours != 0 ]]; then
      echo -n "$hours hours " >> $HOME/SuperShell/mail.txt
    fi

    if [[ $minutes != 0 ]]; then
      echo -n "$minutes minutes " >> $HOME/SuperShell/mail.txt
    fi

    echo "$seconds seconds" >> $HOME/SuperShell/mail.txt

    echo -n ">  Lines of code: " >> $HOME/SuperShell/mail.txt
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_l ) )' >> $HOME/SuperShell/mail.txt
    echo -n ">  Word count: " >> $HOME/SuperShell/mail.txt
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[]] | reduce .[] as $row (0; . + ($row|.diff_wc) )' >> $HOME/SuperShell/mail.txt
    echo >> $HOME/SuperShell/mail.txt
    files_edited=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "****************************************************************" >> $HOME/SuperShell/mail.txt
    echo "$files_edited files edited:" >> $HOME/SuperShell/mail.txt
    cat /$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '[.commands[] | .filename | select(. != "" and . != ".." and . != ".")]  | unique | .[]' | nl >> $HOME/SuperShell/mail.txt
    unique_commands=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | length')
    echo "****************************************************************" >> $HOME/SuperShell/mail.txt
    echo "$unique_commands unique commands:" >> $HOME/SuperShell/mail.txt
    cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '['"$query"' | .command | select(. != "" and . != ".." and . != ".")] | unique | .[]' | nl >> $HOME/SuperShell/mail.txt
  fi
  # echo "Compressing files..."
  # compress
  # rm $HOME/SuperShellHistory/SuperShellHistory.json 
  export SENT_MAIL="1"
}

function sundo {
  # d=$(date +%Y-%m-%d)
  numberFlag=""
  fileNameFlag=""
  dateFlag=""
  while test $# -gt 0; do
           case "$1" in
                -n)
                    shift
                    numberFlag=$1
                    shift
                    ;;
                -f)
                    shift
                    fileNameFlag=$1
                    shift
                    ;;
                # -d)
                #     shift
                #     dateFlag=$1
                #     shift
                #     ;;
                *)
                   echo "$1 is not a recognized flag!"
                   echo "usage: sundo [-f filename] [-n number of versions] [-d start_date]"
                   echo "start_date format: YYYY[-MM[-DD]]"
                   return 1;
                   ;;
          esac
  done
  if [[ ${#fileNameFlag} == 0 ]] 
  then
    echo "Cannot undo without file!"
    return 1;
  fi
  n=1
  if [[ ${#numberFlag} != 0 ]] 
  then
    n=$((numberFlag)) 
  fi
  # echo $n
  jq -s '{ commands: map(.commands[]) }' $HOME/SuperShell/SuperShellHistory/SuperShellHistory-*.json > $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json 
  if [ ! -f "$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json" ]; then
    printf '{"commands":[]}' >> "$HOME/SuperShell/SuperShellHistory/SuperShellHistory.json"
  fi

  file_contents=$(cat $HOME/SuperShell/SuperShellHistory/SuperShellHistory.json | jq '.commands[] | select(.filename == "'"$fileNameFlag"'" and .file != "") | .file' | tail -${n})
  echo "${file_contents//'\n'/$'\n'}"
  
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
  if [ ${params[0]} = "shistory" ]
  then
    $COMMANDS
  elif [ ${params[0]} = "sstats" ]
    then
    $COMMANDS
  elif [ ${params[0]} = "shelp" ]
    then
    $COMMANDS
  elif [ ${params[0]} = "sinfo" ]
    then
    $COMMANDS
  elif [ ${params[0]} = "enablehelp" ]
    then
    $COMMANDS
  elif [ ${params[0]} = "disablehelp" ]
    then
    $COMMANDS
  elif [ ${params[0]} = "mailstats" ]
    then
    $COMMANDS
  elif [ ${params[0]} = "sundo" ]
    then
    $COMMANDS
  #pd addition
  elif [ ${params[0]} = "exit" ]
    then
	goodbye
  #end pd addition
   elif [ ${params[0]} = "!!" ]
     then
       if [ -z $LAST_FULL_COMMAND ]
       then
         echo "No previous command"
       else
	     # This can return an error, let assume it does not
         ${LAST_FULL_COMMAND}
       fi
   elif [ ${params[0]:0:1} = "!" ]
     then
       len=${#params[0]}
       [ $len -gt 0 ] && previousCommand=${params[0]:1:$len}
       #echo $previousCommand
       #echo $(history)
       lastMatchedCommand=$(history | grep "^ *[[:digit:]]\+ *$previousCommand" | tail -1 | cut -c 8- )
       echo $lastMatchedCommand
       if [ -z "$lastMatchedCommand" ]
       then
         echo "No matching command"
       else
         $lastMatchedCommand
       fi
  else
    executeCommand 0
  fi
done
