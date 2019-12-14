# Overview of files:

shell.sh - online shell of user one

shell2.sh - online shell of user two

TestSender.jar - jar used in shell.sh

TestSender2.jar - jar used in shell2.sh

offline_with_online.sh - offline shell with online component commented out

offline.sh - offline shell (no online component)

install.sh - install script for offline shell

# Initial Setup
•	git clone https://github.com/SaumyashreeRay/SuperShell.git

•	cd into directory “SuperShell”

•	depending on OS, run the following command

    bash mac_install.sh (need to have brew installed)
    
    bash linux_install.sh
    
•	follow prompts for consent (y to install)

•	restart bash or open a new bash window for offline SuperShell shell to be activated

SuperShell is running when opening a new bash window displays the banner:


# Enable/Disable SuperShell

## Disable Shell
•	open .bash_profile

•	comment/remove "bash ~/.offline.sh"

•	comment/remove "exit"

## Enable Shell
•	open .bash_profile

•	uncomment/add "bash ~/.offline.sh"

•	uncomment/add "exit"

# Special Commands

## rhistory

Default command shows history of commands for the current day.

There are a few options for this command.

Here are some ways this command can be used:


## rstats

Default command shows stats of commands for the current day.

There are a few options for this command.

Here are some ways this command can be used:



## rhelp (in progress)


