#!/bin/bash
sudo apt-get install jq
cp offline.sh ~/.offline.sh
echo "bash ~/.offline.sh" >> ~/.bash_profile
echo "exit" >> ~/.bash_profile