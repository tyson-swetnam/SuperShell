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

![rhistorydefault](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/rhistory-default.png)

There are a few options for this command.

![rhistoryoptions](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/rhistory-options.png)

Here are some more ways this command can be used:

* This command uses two flags to better search the history logs.
![rhistorydoubleflag](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/rhistory-doubleflag.png)

* This is a short example of a hello world python program that introduces an error.
![rhistorypythonexample](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/helloword-python-example.png)

## rstats

Default command shows stats of commands for the current day.

![rstatsdefault](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/default-rstats.png)

There are a few options for this command.

![rstatsoptions](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/rstats-options.png)


## rhelp (in progress)


