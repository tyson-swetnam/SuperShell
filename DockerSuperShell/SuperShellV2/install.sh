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
sudo apt-get install jq
cp offline.sh ~/.offline.sh
echo "bash ~/.offline.sh" >> ~/.bash_profile
echo "exit" >> ~/.bash_profile
