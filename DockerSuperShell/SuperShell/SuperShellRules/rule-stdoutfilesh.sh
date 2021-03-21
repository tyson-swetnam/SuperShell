#!/usr/bin/bash

if [ "$LAST_STDOUT" == "" ] && [ "$IS_EXEC_COMMAND" ] ; then
	echo "This program doesn't have any output!" >> $HOME/tmpsuggestions.txt
	echo "" >> $HOME/tmpsuggestions.txt
fi
