#!/bin/bash

load_vars() {
	bytesize=0
	j=0
	historyFiles=($HOME/SuperShell/SuperShellHistory/SuperShellHistory-*.json)
	for file in ${historyFiles[@]}; do
		let "bytesize+=$(cat $file | wc -c)"
		if (( $bytesize >= 400000 )); then
			break
		fi
		let "j++"
	done
	#echo $bytesize
	i=$(( -j ))
	historyFiles=("${historyFiles[@]:i:j}")
	shistory=$(jq -s '{ commands: map(.commands[]) }' ${historyFiles[@]})

	output=$LAST_STDOUT
	errorMsg=$LAST_STDERR
	errorType=""
	requestId=""

	if [[ -f $HOME/.supershell_profile.sh ]]; then
		source $HOME/.supershell_profile.sh
	else
		echo "could not find profile to load"
	fi

	vars=$1
	for var in "${vars[@]}"; do
	  printf "Is the $var '${!var}'? [Y/n]: "
	  read -r -p "" input
	  case $input in
	      [yY][eE][sS]|[yY]|"")
	    ;;
	      [nN][oO]|[nN])
	    printf "Enter $var or leave blank for '${!var}': "
	    read -r -p "" input
	    if [[ -n $input ]]; then
	      declare $var="$input"
	    fi
	    ;;
	      *)
	    echo "Invalid input..."
	    exit
	    ;;
	  esac
	done

	touch $HOME/.supershell_profile.sh
	printf "language=$language\nenvironment=$environment\ncourse=$course\nterm=$term\nassignment=$assignment\nproblem=$problem\nemail=$email\ninstructor=$instructor\n" > $HOME/.supershell_profile.sh
}

get_available_help() {

	declare -a vars=("language" "environment" "course" "term" "assignment" "problem" "email")
	load_vars "$vars"

	printf "\nFetching available help...\n"

	payload="{
		\"body\": {
			\"code\": $shistory,
			\"output\": \"$output\",
			\"language\": \"$language\",
			\"environment\": \"$environment\",
			\"error-message\": \"$errorMsg\",
			\"error-type\": \"$errorType\",
			\"course\": \"$course\",
			\"assignment\": \"$assignment\",
			\"problem\": \"$problem\",
			\"email\": \"$email\",
			\"term\": \"$term\",
			\"request-id\": \"$requestId\"
		}
	}"

	response=$(curl -s -X POST -H "Content-Type: application/json" \
		-d "$payload" https://us-south.functions.appdomain.cloud/api/v1/web/ORG-UNC-dist-seed-james_dev/V2/get-available-help)

	#help=$(echo $response | jq -r '.help[]')
	#mapfile -t help <<< $(echo '{"help":{"1":"Consider trying this instead", "2":"This is often a result of not tracking array bounds...", "3":"Make sure you take into account the null terminator"}}' | jq -c '.help[]' | tr -d '"')

	mapfile -t help <<< $(echo $response | jq -c '.help[]' | tr -d '"')
	len=${#help[@]}
	rows=$(tput lines)
	cols=$(tput cols)
	i=0
	while [[ $nav != "q" ]]; do
		echo
		echo "-----------------------------------------------------"
		hNum=$i+1
		echo "Help $(( $i+1 ))/$len:"
		printf "\n\n"
		echo "${help[$i]}"
		printf "\n\n"
		printf "[n]ext  [p]revious  [q]uit  [r]equest help: "
		while true; do
		read -p "" -n 1 nav
		if [[ $nav == "n" ]]; then
			if (( $i+1 < $len )); then
				let "i++"
				break
			else
				printf "\nReached end of available help"
				printf "\n[n]ext  [p]revious  [q]uit  [r]equest help: "
			fi
		elif [[ $nav == "p" ]]; then
			if (( $i-1 >= 0 )); then
				let "i--"
				break
			else
				printf "\nReached beginning of available help"
				printf "\n[n]ext  [p]revious  [q]uit  [r]equest help: "
			fi
		elif [[ $nav == "r" ]]; then
			request_help
		elif [[ $nav == "q" ]]; then
			break
		else
			printf "\nCommand not found"
			printf "\n[n]ext  [p]revious  [q]uit  [r]equest help: "
		fi
		done
	done
	echo
}

request_help() {

	printf "\n\nLeave a comment describing the issue:\n"
	read -r -p "" input
	if [[ -n $input ]]; then
  		declare comment="$input"
	fi

	printf "\nSubmitting help request...\n"

	payload="{
		\"body\": {
			\"code\": $shistory,
			\"output\": \"$output\",
			\"language\": \"$language\",
			\"environment\": \"$environment\",
			\"error-message\": \"$errorMsg\",
			\"error-type\": \"$errorType\",
			\"course\": \"$course\",
			\"assignment\": \"$assignment\",
			\"problem\": \"$problem\",
			\"email\": \"$email\",
			\"term\": \"$term\",
			\"comment\": \"$comment\",
			\"request-id\": \"$requestId\"
		}
	}"

	response=$(curl -s -X POST -H "Content-Type: application/json" \
		-d "$payload" https://us-south.functions.appdomain.cloud/api/v1/web/ORG-UNC-dist-seed-james_dev/V2/request-help)

	exit
}

provide_help() {

	rid=$(echo "${requests[$i]}" | jq -r '._id')

	echo
	declare -a vars=("instructor")
	load_vars "$vars"

	printf "\n\nEnter help feedback for this request:\n"
	read -r -p "" input
	if [[ -n $input ]]; then
  		declare help_string="$input"
	fi

	printf "\nSubmitting help feedback...\n"

	payload="{
		\"body\": {
			\"request-id\": \"$rid\",
			\"instructor\": \"$instructor\",
			\"help\": [\"$help_string\"],
			\"password\": \"password\"
		}
	}"
	#echo $payload

	response=$(curl -s -X POST -H "Content-Type: application/json" \
		-d "$payload" https://us-south.functions.appdomain.cloud/api/v1/web/ORG-UNC-dist-seed-james_dev/V2/provide-help)

	exit

}

get_requests() {

	declare -a vars=("course" "term" "language")
	load_vars "$vars"

	printf "\nFetching requests...\n"

	#course="Comp524"
	#term="Fall2020"
	payload="{
		\"body\": {
			\"course\": \"$course\",
			\"term\": \"$term\",
			\"password\": \"password\",
			\"filter\": {\"language\": \"$language\"}
		}
	}"
	#echo $payload

	response=$(curl -s -X POST -H "Content-Type: application/json" \
		-d "$payload" https://us-south.functions.appdomain.cloud/api/v1/web/ORG-UNC-dist-seed-james_dev/V2/get-requests)

	#echo $response

	mapfile -t requests <<< $(echo $response | jq -c '.requests[]')
	#declare -A myarray
	#while IFS="=" read -r key value
	#do
	#    myarray[$key]="$value"
    	#done < <(echo $response | jq -r 'to_entries|map("(.key)=(.value)")|.[]')
	#mapfile -t help <<< $(echo '{"help":{"1":"Consider trying this instead", "2":"This is often a result of not tracking array bounds...", "3":"Make sure you take into account the null terminator"}}' | jq -c '.help[]' | tr -d '"')
	len=${#requests[@]}
	rows=$(tput lines)
	cols=$(tput cols)
	i=0
	while [[ $nav != "q" ]]; do
		echo
		echo "-----------------------------------------------------"
		hNum=$i+1
		echo "Help $(( $i+1 ))/$len:"
		printf "\n\n"
		echo "${requests[$i]}" | jq -r '.term'
		echo "${requests[$i]}" | jq -r '.course'
		echo
		echo "${requests[$i]}" | jq -r '.comment[]'
		printf "\n\n"
		printf "[n]ext  [p]revious  [q]uit  [v]iew  [a]nswer: "
		while true; do
		read -p "" -n 1 nav
		if [[ $nav == "n" ]]; then
			if (( $i+1 < $len )); then
				let "i++"
				break
			else
				printf "\nReached end of available help"
				printf "\n[n]ext  [p]revious  [q]uit  [v]iew  [a]nswer: "
			fi
		elif [[ $nav == "p" ]]; then
			if (( $i-1 >= 0 )); then
				let "i--"
				break
			else
				printf "\nReached beginning of available help"
				printf "\n[n]ext  [p]revious  [q]uit  [v]iew  [a]nswer: "
			fi
		elif [[ $nav == "a" ]]; then
			provide_help
		elif [[ $nav == "v" ]]; then
			echo "${requests[$i]}" | jq -r '.code' | more
		elif [[ $nav == "q" ]]; then
			break
		else
			printf "\nCommand not found"
			printf "\n[n]ext  [p]revious  [q]uit  [v]iew  [a]nswer: "
		fi
		done
	done
	echo
}

case $1 in
	"--get-help")
		get_available_help
		exit
		;;
	"--get-requests")
		get_requests
		exit
		;;
	*)
		exit
		;;
esac
