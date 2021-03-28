#!/usr/bin/bash
init_shell() {
  echo $$ > ~/shell/shell_pid2
  history -r ~/shell/script_history2
  trap "goodbye" SIGINT SIGTERM
  trap "remoteExecution" SIGALRM
  trap "displayRemoteOutput" 16
  trap "allowRemoteConnection" 19
  trap "endRemoteConnection" 18
  trap "handleInteractiveFile" 21
  trap "handleTabCompletion" 23
  trap "serverTabComplete" 24
  set -m
  set -o emacs;
  bind -x '"\tc":"tab"';
  home=${PWD##*/}
  host=$(hostname -s)
  user=$(whoami)
  j_pipe=/tmp/java_pipe2
  mkfifo $j_pipe
  cat > $j_pipe &
  echo $! > ~/shell/java_pipe_pid2
  java -jar ~/shell/TestSender2.jar bdog < $j_pipe > ~/shell/java_output2 &
  connected=false
  controlled=false
  training=true
  clicked=false
  curr=""
}

test() {
  echo "test"
}

tab() {
  echo "Press enter to get custom tab completion results"
  clicked=true
}

handleInteractiveFile() {
  filename=$(cat filename2.txt)
  if [ "$controlled" = true ]
  then
    mv tmp2/"$filename" "$filename" 
  fi
}

handleTabCompletion() {
  comm=$(cat command2.txt)
  cat completions2.txt > ".$comm"
  return
}

serverTabComplete() {
  comm=$(cat commandComplete2.txt)
  server_compl=$(cat completionsComplete2.txt)
  echo "command: $comm"
  echo "result: $server_compl"
}

print_output() {
  cat ~/shell/output2.txt
}

displayRemoteOutput() {
  echo ''
  print_output 
  print_prompt
  echo -n "$prompt "
}

allowRemoteConnection() {
  echo "connection started"
  controlled=true
}

endRemoteConnection() {
  echo "connection finished"
  controlled=false
}

goodbye (){
   history -w ~/shell/script_history2
   kill $(cat ~/shell/java_pipe_pid2)
   pkill -f TestSender2
   rm ~/shell/java_output2
   rm $j_pipe
   rm ~/shell/java_pipe_pid2
   rm ~/shell/shell_pid2
   rm ~/shell/testCommands2.txt
   rm ~/shell/output2.txt
   rm -rf ~/shell/tmp2
   exit 0
}

evalCommand () {
  remote=$(cat ~/shell/testCommands2.txt)
  echo "Executing remote command: $remote"
  eval "$remote" > ~/shell/test_output2
  cat ~/shell/test_output2
  echo "output_start" > $j_pipe
  cat ~/shell/test_output2 > $j_pipe
  echo "output_end" > $j_pipe
}

print_prompt() {
  dir=${PWD##*/}
  if [ $dir = $home ]
  then
    dir="~"
  fi
  prompt="$host:$dir $user$"
}

remoteExecution() {
  echo ''
  evalCommand 
  print_prompt
  echo -n "$prompt "
}

getdiff() {
  echo $old > tmp_old
  echo $new > tmp_new
  dif=$(diff tmp_old tmp_new)
  rm tmp_old
  rm tmp_new
}

sendOverFile() {
  filename=$1
  loc=$2
  echo "file_start $filename" > $j_pipe
  cat $loc > $j_pipe
  echo "file_end" > $j_pipe
}

sendOverFileAndDiff() {
  sendOverFile ${params[1]} ${params[1]}
  echo "output_start" > $j_pipe
  echo "Local host executed command: $COMMANDS" > $j_pipe
  echo "Diff after change:" > $j_pipe
  echo $dif > $j_pipe
  echo "output_end" > $j_pipe
}

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

localInteractive() {
  old=$(cat ${params[1]})
  eval "$COMMANDS"
  new=$(cat ${params[1]})
  getdiff
  sendOverFileAndDiff
}

remoteInteractive() {
  old=$(cat ./tmp2/${params[1]})
  if [[ -z "${old// }" ]] 
  then
    echo "local host must edit or send over file to enable remote editting"
    return 0
  fi
  eval "${params[0]} ./tmp2/${params[1]}"
  sendOverFile ${params[1]} ./tmp2/${params[1]}
}

executeAndSend() {
  testForInteractive
  if [ "$interactive" == 0 ]
  then
    eval "$COMMANDS" > ~/shell/test_output2
    cat ~/shell/test_output2
    echo "output_start" > $j_pipe
    echo "Local host executed command: $COMMANDS" > $j_pipe
    cat ~/shell/test_output2 > $j_pipe
    echo "output_end" > $j_pipe
  else
    localInteractive
  fi
}

sendRemoteCommand() {
  testForInteractive
  if [ "$interactive" == 0 ]
  then
    echo "$COMMANDS" > $j_pipe
  else
    remoteInteractive
  fi
}

sendCommandForTabTraining() {
  echo "command_send" > $j_pipe
  echo "$COMMANDS" > $j_pipe
}

executeCommand() {
  option=$1
  if [ "$training" = true ]
  then
    sendCommandForTabTraining
  fi

  if [ "$option" == 0 ]
  then
    eval "$COMMANDS"
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

tomatch() {
  match=$(printf " %s" "${params[@]}")
  le=${#params[0]}
  match=${match:2+le}
}

completeFunction() {
  echo "tab complete $COMMANDS"
  params=($COMMANDS)
  echo "command: ${params[0]}"
  tomatch
  IFS=$'\n' 
  compl_arr=( $(xargs -n1 <<< "$(cat .${params[0]})") )
  IFS=' '
  tabComplete
  IFS=' '
}

tabComplete() {
  echo "Possible completions:"
  found=false
  compl_index=()
  count=0
  for option in "${compl_arr[@]}"; do
    if [[ $option == $match* ]]
    then
      found=true
      echo "($count) $option"
      compl_index+=($option)
      ((count+=1))
    fi
  done

  if [ "$found" = false ]
  then
    echo "No completions found"
    curr=$COMMANDS
  else
    chooseResult
  fi
}

chooseResult() {
  read -p "Pick a number corresponding with a completion " -e choice
  curr="${params[0]} ${compl_index[$choice]}"
}

init_shell
while :
  do
  clicked=false
  print_prompt
  read -p "$prompt $curr" -e COMMANDS
  COMMANDS="$curr$COMMANDS"
  curr=""
  if [ "$clicked" = true ]
  then
    completeFunction
    continue
  fi
  history -s "$COMMANDS"
  
  if [[ -z "${COMMANDS// }" ]] 
  then
    continue
  fi
  params=($COMMANDS)
  if [ "$connected" = true ]
  then
    if [ ${params[0]} = "rexit" ]
    then 
      echo "ending connection"
      echo "$COMMANDS" > $j_pipe
      connected=false
    else
      executeCommand 2
    fi
  else 
    if [ ${params[0]} = "rjoin" ]
    then
      echo "connecting to ${params[1]}"
      echo "$COMMANDS" > $j_pipe
      connected=true
    else
      if [ "$controlled" = true ]
      then
        if [ ${params[0]} = "rsend" ]
        then
          sendOverFile ${params[1]} ${params[1]}
        else
          executeCommand 1
        fi
      else
        executeCommand 0
      fi
    fi
  fi
  done
