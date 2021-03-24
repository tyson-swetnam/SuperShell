#!/bin/bash
cat consent.txt
#sudo apt-get install jq
cp offline.sh ~/.offline.sh
cp interactive.txt ~/.interactive.txt
cp supershellhelp.txt ~/.supershellinfo.txt
cp supershellhelp.txt ~/.supershellhelp.txt
cp supershellhelpmessage.txt ~/.supershellhelpmessage.txt
cp ruledir.txt ~/.ruledir.txt
cp add_interactive.sh ~/.add_interactive.sh
cp disable_help.sh ~/.disable_help.sh
cp enable_help.sh ~/.enable_help.sh
echo "bash ~/.offline.sh" >> ~/.bash_profile