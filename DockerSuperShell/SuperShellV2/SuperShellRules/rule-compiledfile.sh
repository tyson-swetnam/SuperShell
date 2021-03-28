#!/usr/bin/bash

if [ "$LAST_STDERR" != "" ]; then
    if [[ $LAST_STDERR == *"No such file or directory"* ]]; then
		if [ "$LAST_COMMAND" == "cd" ]; then
			# echo "_________________________________________________________________"
			# echo "" >> $HOME/tmpsuggestions.txt
			echo "Make sure have created the directory you are navigating to!" >> $HOME/tmpsuggestions.txt
			echo "Suggestion: " >> $HOME/tmpsuggestions.txt
			echo "mkdir <directory name>" >> $HOME/tmpsuggestions.txt
			echo "" >> $HOME/tmpsuggestions.txt
			# echo "_________________________________________________________________"
		fi
		if [ ! -f "$LAST_FILENAME" ]; then #make more specific
			# echo "" >> $HOME/tmpsuggestions.txt
			echo "Make sure you have compiled $LAST_EXECUTED" >> $HOME/tmpsuggestions.txt
			echo "To compile, enter the following command:" >> $HOME/tmpsuggestions.txt
			echo "gcc $LAST_EXECUTED -o $LAST_FILENAME" >> $HOME/tmpsuggestions.txt
			echo "" >> $HOME/tmpsuggestions.txt
			# echo ""
		fi
    fi
fi