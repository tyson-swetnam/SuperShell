#!/usr/bin/bash

if [[ "$LAST_STDERR" == *"command not found"* ]]; then
	if [[ "$LAST_COMMAND" == "ll" ]]; then
		echo "Do you mean ls?" >> $HOME/tmpsuggestions.txt
		echo "" >> $HOME/tmpsuggestions.txt
	fi
fi