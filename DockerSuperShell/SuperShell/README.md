# SuperShell
## Overview of files:

* shell.sh - online shell of user one

* shell2.sh - online shell of user two

* TestSender.jar - jar used in shell.sh

* TestSender2.jar - jar used in shell2.sh

* offline_with_online.sh - offline shell with online component commented out

* offline.sh - offline shell (no online component)

* install.sh - install script for offline shell

# Initial Setup

## Installation 

* git clone https://github.com/SaumyashreeRay/SuperShell.git

* cd into directory “SuperShell”

* depending on OS, run the following command
    
    * bash mac_install.sh (need to have [brew](https://brew.sh) installed)
    
    * bash linux_install.sh
    
    * bash windows_install.sh (need to have [chocolatey](https://chocolatey.org/install) installed)
        
        Note: This version is a bit buggy
    
* follow prompts for consent (y to install)

* restart bash or open a new bash window for offline SuperShell shell to be activated

SuperShell is running when opening a new bash window displays the banner:

![supershellbanner](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/opening-banner.png)

## Interactive commands

Commands that "take over" the display of the shell must be designated as an interactive command. The command 

    bash add_interactive.sh <command_name>

adds the parameter given to a list of interactive commands like pico, nano, vi, jupyter, etc.

# Enable/Disable SuperShell

## Disable Shell
* open .bash_profile

* comment/remove "bash ~/.offline.sh"

* comment/remove "exit"

## Enable Shell
* open .bash_profile

* uncomment/add "bash ~/.offline.sh"

* uncomment/add "exit"

# Special Commands

## rhistory

This command allows a user to view their command history in json format, and allows for filtering based on date, command, and file. By default, the command shows the history of commands for the current day.

![rhistorydefault](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/rhistory-default.png)

There are a few options for this command.

![rhistoryoptions](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/rhistory-options.png)

Here are some more ways this command can be used:

* This command uses two flags to better search the history logs.
![rhistorydoubleflag](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/rhistory-doubleflag.png)

* This is a short example of a hello world python program that introduces an error.
![rhistorypythonexample](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/helloword-python-example.png)

History for each day is stored in separate json files with the naming convention 
    
    SuperShellHistory-YYYY-MM-DD.json

The standard output is limited to the first 1000 lines. 

## rstats

This command gives the user a more detailed look at their history. It shows the time spent coding, the number of lines  and words changed, and how many files were edited. By default, this command shows stats of commands for the current day.

![rstatsdefault](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/default-rstats.png)

There are a few more options (weekly, monthly, yearly) for this command.

![rstatsoptions](https://github.com/SaumyashreeRay/SuperShell/blob/master/images/rstats-options.png)


## rhelp (in progress)

This command (still in progress) is being designed to suggest fixes to common errors a user might encounter within the shell.

