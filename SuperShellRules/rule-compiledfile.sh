#!/usr/bin/bash

if [ "$LAST_STDERR" != "" ]; then
    if [[ $LAST_STDERR == *"No such file or directory"* ]]; then
		if [ "$LAST_COMMAND" == "cd" ]; then
			echo "_________________________________________________________________"
			echo ""
			echo "Make sure have created the directory you are navigating to!"
			echo "Suggestion: "
			echo "mkdir <directory name>"
			echo "_________________________________________________________________"
		fi
		if [ ! -f "$LAST_FILENAME" ]; then #make more specific
			echo "_________________________________________________________________"
			echo "Make sure you have compiled $LAST_EXECUTED"
			echo "To compile, enter the following command:"
			echo "gcc $LAST_EXECUTED -o $LAST_FILENAME"
			echo "_________________________________________________________________"
		fi
    fi
fi