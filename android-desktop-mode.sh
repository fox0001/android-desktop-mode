#!/bin/bash
# ****************************************************************
# Android Desktop Mode
# - Depend on scrcpy 3.1 above, https://github.com/Genymobile/scrcpy/releases
# ****************************************************************

# Params
#  $1: SERIAL | HOST[:PORT]
P_SERIAL=$1

PHONE_NAME="My Phone"
CMD_ADB="/opt/dev/android-sdk/platform-tools/adb"
ADB_SERIAL=
CMD_SCRCPY="/opt/deploy/scrcpy/scrcpy"
DISPLAY_W=1920
DISPLAY_H=1008
DISPLAY_DPI=180
#DISPLAY_ID=0
# Log level
declare -A LOG_LEVEL=([i]=INFO [w]=WARN [e]=ERR)

# Log message
# Params
#  $1: log level
#  $2: message
function f_log() {
    lv=${LOG_LEVEL[$1]}
    if [ -z "$lv" ]; then
        lv=NONE
    fi
    echo [$lv] $2 1>&2
    return
}

function f_init() {
    result=n
    
    # Do connect
    is_connected=$(f_connect)
    if [ "$is_connected" == "y" ]; then
        echo y
        return
    fi
    f_log w "Connect failed. SERIAL or HOST is invalid, or need pairing"
    
    # Do pair
    read -p "Need to pair device? Enter "y" for yes, otherwise exit:" need_pair
    if [ "$need_pair" != "y" ]; then
        echo Exit 1>&2
        echo $result
        return
    fi
    is_paired=$(f_pair)
    if [ "$is_paired" != "y" ]; then
        f_log e "Pair failed, exit"
        echo $result
        return
    else
        f_log i "Pair succeed"
    fi
    is_connected=$(f_connect)
    if [ "$is_connected" != "y" ]; then
        f_log e "Connect failed, exit"
        echo $result
        return
    else
        f_log i "Connect succeed"
    fi
    echo y
    return
}

function f_get_serialno() {
    dev_serialno=$($CMD_ADB get-serialno)
    if [ -z "$dev_serialno" ]; then
        return
    fi
    echo $dev_serialno
    return
}

function f_check_serialno() {
    result=n
    dev_serialno=$($CMD_ADB -s "$P_SERIAL" get-serialno)
    if [ "$P_SERIAL" != "$dev_serialno" ]; then
        echo $result
        return
    fi
    echo y
    return
}

function f_connect() {
    result=n
    
    # Get serialno of default device
    if [ -z $P_SERIAL ]; then
        dev_serialno=$(f_get_serialno)
        if [ -z "$dev_serialno" ]; then
            f_log e "No connected device"
            echo $result
        else
            echo y
            P_SERIAL=$dev_serialno
        fi
        return
    fi
    
    # Check if the device is connected
    is_connected=$(f_check_serialno)
    if [ "$is_connected" == "y" ]; then
        echo y
        return
    fi
    
    # Connect to the device
    dev_connect=$($CMD_ADB connect "$P_SERIAL")
    if [ "${dev_connect:0:9}" != "connected" ] && [ "${dev_connect:0:17}" != "already connected" ]; then
        echo $result
        return
    fi
    echo y
    return
}

function f_pair() {
    result=n
    echo Enter "HOST[:PORT]" of the paired device:; read pair_host
    echo Enter "PAIRING CODE":; read pair_code
    dev_pair=$($CMD_ADB pair "$pair_host" pair_code)
    if [ "${dev_pair:0:19}" != "Successfully paired" ]; then
        echo $result
        return
    fi
    echo y
    return
}

function f_tips() {
    echo + Tips ------------------
    echo   - Ctrl + H, back to desktop
    echo   - Ctrl + Shift + O, turn ON screen of the connected device
    echo   - Ctrl + O, turn OFF screen of the connected device
    echo + -----------------------
}

function f_run_before() {
    # timeout /T 2
    # Start Taskbar app
    # $CMD_ADB $ADB_SERIAL shell am start-activity --display $DISPLAY_ID -n com.farmerbb.taskbar/.activity.MainActivity
    
    # Stop Android Settings app which is preventing Taskbar app to run.
    $CMD_ADB $ADB_SERIAL shell am force-stop com.android.settings
    
    return
}

function f_run_after() {
    #$CMD_ADB $ADB_SERIAL shell am start-activity --display $DISPLAY_ID -a com.aistra.hail.action.FREEZE -e package cu.axel.smartdock
    return
}

# main function
function f_main() {
    is_init=$(f_init)
    if [ "$is_init" != "y" ]; then
        return
    fi

    # Turn on auxiliary display device
    #$CMD_ADB $ADB_SERIAL shell settings put global overlay_display_devices 1920x1008/180

    # Get display-id of Simulate secondary displays
    #DISPLAY_ID=$($CMD_SCRCPY $ADB_SERIAL --list-displays | $CMD_ADB $ADB_SERIAL shell "grep -o 'display-id=[1-9][0-9]*' | sed 's/display-id=\([1-9][0-9]*\)/\1/'")
    #f_log i "Display id: $DISPLAY_ID"

    # Show tips
    f_tips

    # Do sth before run scrcpy
    f_run_before

    # Run scrcpy
    #$CMD_SCRCPY $ADB_SERIAL --display-id=$DISPLAY_ID --keyboard=sdk --mouse=sdk --no-audio --power-off-on-close --shortcut-mod="lctrl,rctrl" --stay-awake --turn-screen-off --window-title="$PHONE_NAME - Android Desktop Mode" --window-x=0 --window-y=25
    $CMD_SCRCPY $ADB_SERIAL --new-display=1920x1008/180 --keyboard=sdk --mouse=sdk --no-audio --no-vd-destroy-content --power-off-on-close --push-target=/sdcard/Download/ --shortcut-mod="lctrl,rctrl" --show-touches --stay-awake --turn-screen-off --video-codec=h265 --video-encoder=c2.qti.hevc.encoder --window-title="$PHONE_NAME - Android Desktop Mode" --window-x=0 --window-y=25

    # Do sth after run scrcpy
    f_run_after

    # Turn off auxiliary display device
    #$CMD_ADB $ADB_SERIAL shell settings put global overlay_display_devices null
}

f_main
exit
