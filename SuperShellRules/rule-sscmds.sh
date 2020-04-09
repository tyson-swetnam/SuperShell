#!/usr/bin/bash

if [[ "$LAST_STDERR" == *"command not found"* ]]; then
	if [[ "$LAST_COMMAND" == "ll" ]]; then
		echo "Do you mean ls?" >> $HOME/tmpsuggestions.txt
		echo "" >> $HOME/tmpsuggestions.txt
	fi
	if [[ "$LAST_COMMAND" == "rhistory" ]]; then
		echo "Do you mean shistory?" >> $HOME/tmpsuggestions.txt
		echo "" >> $HOME/tmpsuggestions.txt
	fi
	if [[ "$LAST_COMMAND" == "shidtory" ]]; then
		echo "Do you mean shistory?" >> $HOME/tmpsuggestions.txt
		echo "" >> $HOME/tmpsuggestions.txt
	fi 
	if [[ "$LAST_COMMAND" == "rhisotry" ]]; then
		echo "Do you mean shistory?" >> $HOME/tmpsuggestions.txt
		echo "" >> $HOME/tmpsuggestions.txt
	fi
	if [[ "$LAST_COMMAND" == "rstats" ]]; then
		echo "Do you mean sstats?" >> $HOME/tmpsuggestions.txt
		echo "" >> $HOME/tmpsuggestions.txt
	fi
fi