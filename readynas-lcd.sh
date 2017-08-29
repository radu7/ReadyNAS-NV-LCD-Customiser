#!/bin/bash
#
# A simple customisable LCD script for the Netgear ReadyNAS NV+ NAS, which
# cycles a selection of system information over LCD, such as CPU usage etc..
#
# Tested with Netgear RND4000-100EUS, should work with similar models with the
# 16x2 LCD display panel. This script uses undocumented functionality of the
# ReadyNAS, so YMMV!
#
# 'Installation' of this script is left as an exercise to the reader, but you
# should look at creating a cronjob, or modifying the main program to loop and
# start the script via init at startup.
#
# v1.0 by phraxoid (23/04/2009)

# ---- Global Variables ----
# LCD display options:
LCD_SHOW_MEM=1
LCD_SHOW_CPU=1
LCD_SHOW_SYS=1
LCD_SHOW_NET=1
LCD_SHOW_IP=1
LCD_SHOW_TIME=1
LCD_SHOW_HDD=1
# You shouldn't need to change these for the NV+ model:
ROTATION_DELAY=10
NET_INT=eth0
HDD_DEV=/dev/hdc1
RAID_DEV=/dev/c/c


# ---- LCD Management Functions ----

function set_backlight
{
    # Change state of LCD backlight
    # args = set_backlight(bool backlight_state)
    if [ $1 = 0 ]; then
        echo 0 > /proc/sys/dev/lcd/backlight
    else
        echo 1 > /proc/sys/dev/lcd/backlight
    fi
}
function print_lcd
{
    # Write string to LCD device (0 for top row output, 1 for bottom row)
    # args = print_lcd(bool lcd_row, str lcd_text)
    if [ $1 = 0 ]; then
        echo 2 > /proc/sys/dev/lcd/cmd
    else
        echo 192 > /proc/sys/dev/lcd/cmd
    fi
    printf "%-16.16s" $2 > /dev/lcd
}
function reset_lcd
{
    # Blank the LCD screen
    # args = reset_lcd()
    set_backlight 0
    print_lcd 0 ""
    print_lcd 1 ""
}


# ---- Statistics Generation Functions ----
# Each function below returns a string of information intended for display on
# one line of the LCD (16x1).

function get_meminfo
{
    # Generate memory usage info
    # args = get_meminfo()
    local s=""
    sMemUsed=$(free -m | awk 'NR == 2 {print $3;}')
    sMemTotal=$(free -m | awk 'NR == 2 {print $2;}')
    s="RAM:"$sMemUsed"MB/"$sMemTotal"MB"
    echo $s
}
function get_swapinfo
{
    # Generate swap usage info
    # args = get_swapinfo()
    local s=""
    sSwapUsed=$(free -m | awk 'NR == 4 {print $3;}')
    sSwapTotal=$(free -m | awk 'NR == 4 {print $2;}')
    s="Swap:"$sSwapUsed"MB/"$sSwapTotal"MB"
    echo $s
}
function get_uptimeinfo
{
    # Generate system uptime info
    # args = get_uptimeinfo()
    local s=""
    sUp=$(cat /proc/uptime | awk '{print $1;}' | cut -f1 -d.)
    let "sUp /= 3600"
    # sUnit=$(uptime | awk '{print $4;}' | cut -b1)
    sUsers=$(uptime | awk '{print $4;}')
    s="Up:"$sUp"h/Users:"$sUsers
    echo $s
}
function get_hostnameinfo
{
    # Generate domain name info
    # args = get_hostnameinfo()
    local s=""
    sHostname=$(hostname -f)
    s=$sHostname
    echo $s
}
function get_loadinfo
{
    # Generate CPU load average info
    # args = get_loadinfo()
    local s=""
    sOneLoad=$(uptime | awk '{print $8;}' | cut -d, -f1)
    sFifteenLoad=$(uptime | awk '{print $10;}' | cut -d, -f1)
    s="Load:"$sOneLoad"/"$sFifteenLoad
    echo $s
}
function get_procinfo
{
    # Generate CPU processes info
    # args = get_procinfo
    local s=""
    sProcs=$(ps ax | wc -l | awk '{print $1}')
    s="Processes:"$sProcs
    echo $s
}
function get_ethrxinfo
{
    # Generate network interface received data info
    # args = get_ethrxinfo()
    local s=""
    sRX=$(ifconfig $NET_INT | grep "RX bytes:" | awk '{print $2}' | cut -b7-64)
    let "sRX /= 1048576"
    s="Rcvd:"$sRX"MB"
    echo $s
}
function get_ethtxinfo
{
    # Generate network interface sent data info
    # args = get_ethtxinfo()
    local s=""
    sTX=$(ifconfig $NET_INT | grep "RX bytes:" | awk '{print $6}' | cut -b7-64)
    let "sTX /= 1048576"
    s="Sent:"$sTX"MB"
    echo $s
}
function get_ipinfo
{
    # Generate network interface IP address info
    # args = get_ipinfo()
    local s=""
    sIPV4=$(ifconfig $NET_INT | awk 'NR == 2 {print $2;}' | cut -b6-20)
    s="IP:"$sIPV4
    echo $s
}
function get_mtuinfo
{
    # Generate network interface MTU info
    # args = get_mtuinfo()
    local s=""
    sMTU=$(ifconfig -s $NET_INT | awk 'NR == 2 {print $2}')
    s="MTU:"$sMTU
    echo $s
}
function get_dateinfo
{
    # Generate system date info
    # args = get_dateinfo()
    local s=""
    sDate=$(date +%a-%d/%m/%Y)
    s=$sDate
    echo $s
}
function get_timeinfo
{
    # Generate system time info
    # args = get_timeinfo()
    local s=""
    sTime=$(date +%H:%M)
    s=$sTime
    echo $s
}
function get_syshdinfo
{
    # Generate free disc info for system partition
    # args = get_syshdinfo()
    local s=""
    sUsedSys=$(df -h $HDD_DEV | awk 'NR == 2 {print $3}')
    sTotalSys=$(df -h $HDD_DEV | awk 'NR == 2 {print $2}')
    s="Sys:"$sUsedSys"/"$sTotalSys
    echo $s
}
function get_raidhdinfo
{
    # Generate free disc info for raid array partition
    # args = get_raidhdinfo()
    local s=""
    sUsedRaid=$(df -h $RAID_DEV | awk 'NR == 2 {print $3}')
    sTotalRaid=$(df -h $RAID_DEV | awk 'NR == 2 {print $2}')
    s="RAID:"$sUsedRaid"/"$sTotalRaid
    echo $s
}


# ---- Main Program ----
# Display a series of statistics on the LCD

reset_lcd
set_backlight 1

# Display Memory Information
if [ $LCD_SHOW_MEM = 1 ]; then
       print_lcd 0 `get_meminfo`
       print_lcd 1 `get_swapinfo`
       sleep $ROTATION_DELAY
fi

# Display Disk Space Information
if [ $LCD_SHOW_HDD = 1 ]; then
       print_lcd 0 `get_syshdinfo`
       print_lcd 1 `get_raidhdinfo`
       sleep $ROTATION_DELAY
fi

# Display CPU Information
if [ $LCD_SHOW_CPU = 1 ]; then
       print_lcd 0 `get_procinfo`
       print_lcd 1 `get_loadinfo`
       sleep $ROTATION_DELAY
fi

# Display System Information
if [ $LCD_SHOW_SYS = 1 ]; then
       print_lcd 0 `get_hostnameinfo`
       print_lcd 1 `get_uptimeinfo`
       sleep $ROTATION_DELAY
fi

# Display Network Transport Information
if [ $LCD_SHOW_NET = 1 ]; then
       print_lcd 0 `get_ethtxinfo`
       print_lcd 1 `get_ethrxinfo`
       sleep $ROTATION_DELAY
fi

# Display Network IP Information
if [ $LCD_SHOW_IP = 1 ]; then
       print_lcd 0 `get_ipinfo`
       print_lcd 1 `get_mtuinfo`
       sleep $ROTATION_DELAY
fi

# Display Date and Time Information
if [ $LCD_SHOW_TIME = 1 ]; then
       print_lcd 0 `get_dateinfo`
       print_lcd 1 `get_timeinfo`
       sleep $ROTATION_DELAY
fi

reset_lcd
exit 0