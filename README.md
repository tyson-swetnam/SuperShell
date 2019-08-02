Overview of files:
shell.sh - online shell of user one
shell2.sh - online shell of user two
TestSender.jar - jar used in shell.sh
TestSender2.jar - jar used in shell2.sh
offline_with_online.sh - offline shell with online component commented out
offline.sh - offline shell (no online component)
install.sh - install script for offline shell

The reason for shell.sh and shell2.sh is that I tested out the program on the same computer so I needed to have the two shells write to different files so one shell doesn't overwrite what the other shell is doing/storing. Should not be necessary to deploy to students.