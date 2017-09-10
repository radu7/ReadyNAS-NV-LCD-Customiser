# ReadyNAS-NV-LCD-Customiser

`readynas-lcd.sh` is a simple customisable LCD script for the Netgear ReadyNAS NV+ NAS, which cycles a selection of system information over LCD, such as CPU usage etc.

Tested with Netgear RND4000-100EUS, should work with similar models with the 16x2 LCD display panel. This script uses undocumented functionality of the ReadyNAS, so YMMV!

Installation of this script is left as an exercise to the reader, but you should look at creating a cronjob, or modifying the script to loop/start with initd.

You will need to configure your ReadyNAS to allow SSH access in order to deploy and run this script.
