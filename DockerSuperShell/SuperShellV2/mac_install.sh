#!/bin/bash
cat consent.txt
echo
echo
while :
   do
    echo "Do you consent to this study(y/n): "
    read -e COMMANDS
   if [ "$COMMANDS" = "y" ]; then
       break
   elif [ "$COMMANDS" = "n" ]; then
       echo "Ending installation"
       exit 0
   else 
       echo "Unrecognized input. Please use y/n."
   fi
done
brew install jq
cp offline.sh ~/.offline.sh
cp interactive.txt ~/.interactive.txt
cp supershellhelp.txt ~/.supershellhelp.txt
cp supershellinfo.txt ~/.supershellinfo.txt
cp supershellhelpmessage.txt ~/.supershellhelpmessage.txt
cp ruledir.txt ~/.ruledir.txt
cp add_interactive.sh ~/.add_interactive.sh
echo "bash ~/.offline.sh" >> ~/.bash_profile
echo "exit" >> ~/.bash_profile
