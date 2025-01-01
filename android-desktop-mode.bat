@echo off
rem ****************************************************************
rem Android Desktop Mode
rem - Depend on scrcpy 3.1 above, https://github.com/Genymobile/scrcpy/releases
rem ****************************************************************
SETLOCAL ENABLEEXTENSIONS

rem Params
rem  %1: SERIAL | HOST[:PORT]
set P_SERIAL=%1

set PHONE_NAME=my-phone
set CMD_ADB="D:\dev\android-sdk\platform-tools\adb.exe"
set ADB_SERIAL=
set CMD_SCRCPY="D:\Program Files\scrcpy\scrcpy.exe"
set TEMP_FILE="C:\Users\%username%\AppData\Local\Temp\scrcpy_display_id_%RANDOM%.txt"
set DISPLAY_W=1920
set DISPLAY_H=1008
set DISPLAY_DPI=180
rem set DISPLAY_ID=0

call :f_main
goto end

rem Log message
rem Params
rem  %1: log level
rem  %2: message
:f_log
    set lv_index=%~1
    if "%lv_index%" == "i" (
        set lv=INFO
    ) else if "%lv_index%" == "w" (
        set lv=WARN
    ) else if "%lv_index%" == "e" (
        set lv=ERR
    ) else (
        set lv=NONE
    )
    echo [%lv%] %~2
goto :eof

:f_init
    set %~1=n
    
    rem Do connect
    call :f_connect is_connected
    if "%is_connected%" == "y" (
        set %~1=y
        set ADB_SERIAL=-s %P_SERIAL%
        goto :eof
    )
    call :f_log w,"Connect failed. SERIAL or HOST is invalid, or need pairing"
    
    rem Do pair
    set /p need_pair=Need to pair device? Enter "y" for yes, otherwise exit:
    if "%need_pair%" neq "y" (
        echo Exit
        goto :eof
    )
    call :f_pair is_paired
    if "%is_paired%" neq "y" (
        call :f_log e,"Pair failed, exit"
        goto :eof
    ) else (
        call :f_log i,"Pair succeed"
    )
    call :f_connect is_connected
    if "%is_connected%" neq "y" (
        call :f_log e,"Connect failed, exit"
        goto :eof
    ) else (
        call :f_log i,"Connect succeed"
    )
    set ADB_SERIAL=-s %P_SERIAL%
    set %~1=y
goto :eof

:f_get_serialno
    for /f "delims=" %%i in ('%CMD_ADB% get-serialno') do set dev_serialno=%%i
    if "%dev_serialno%" == "" (
        goto :eof
    )
    set %~1=%dev_serialno%
goto :eof

:f_check_serialno
    set %~1=n
    for /f "delims=" %%i in ('%CMD_ADB% -s %P_SERIAL% get-serialno') do set dev_serialno=%%i
    if "%P_SERIAL%" neq "%dev_serialno%" (
        goto :eof
    )
    set %~1=y
goto :eof

:f_connect
    set %~1=n
    
    rem Get serialno of default device
    if "%P_SERIAL%" == "" (
        call :f_get_serialno dev_serialno
    )
    if "%P_SERIAL%%dev_serialno%" == "" (
        call :f_log e,"No connected device"
        goto :eof
    ) else if "%P_SERIAL%%dev_serialno%" == "%dev_serialno%" (
        set %~1=y
        set P_SERIAL=%dev_serialno%
        goto :eof
    )
    
    rem Check if the device is connected
    call :f_check_serialno is_connected
    if "%is_connected%" == "y" (
        set %~1=y
        goto :eof
    )
    
    rem Connect to the device
    for /f "delims=" %%i in ('%CMD_ADB% connect %P_SERIAL%') do set dev_connect=%%i
    if "%dev_connect:~0,9%" == "connected" (
        rem Do nothing
    ) else if "%dev_connect:~0,17%" == "already connected" (
        rem Do nothing
    ) else (
        goto :eof
    )
    set %~1=y
goto :eof

:f_pair
    set %~1=n
    echo Enter "HOST[:PORT]" of the paired device: & set /p pair_host=
    echo Enter "PAIRING CODE": & set /p pair_code=
    for /f "delims=" %%i in ('%CMD_ADB% pair %pair_host% %pair_code%') do set dev_pair=%%i
    if "%dev_pair:~0,19%" neq "Successfully paired" (
        goto :eof
    )
    set %~1=y
goto :eof

:f_tips
    echo + Tips ------------------
    echo   - Ctrl + H, back to desktop
    echo   - Ctrl + Shift + O, turn ON screen of the connected device
    echo   - Ctrl + O, turn OFF screen of the connected device
    echo + -----------------------
goto :eof

:f_run_before
    rem timeout 2
    rem Start Taskbar app
    rem %CMD_ADB% %ADB_SERIAL% shell am start-activity --display %DISPLAY_ID% -n com.farmerbb.taskbar/.activity.MainActivity
    
    rem Stop Android Settings app which is preventing Taskbar app to run.
    %CMD_ADB% %ADB_SERIAL% shell am force-stop com.android.settings
goto :eof

:f_run_after
    rem %CMD_ADB% %ADB_SERIAL% shell am start-activity --display %DISPLAY_ID% -a com.aistra.hail.action.FREEZE -e package cu.axel.smartdock
goto :eof

rem main function
:f_main
    call :f_init is_init
    if "%is_init%" neq "y" (
        goto :eof
    )
    call :f_log i,"Connected device: %P_SERIAL%"

    rem Turn on auxiliary display device
    rem %CMD_ADB% %ADB_SERIAL% shell settings put global overlay_display_devices 1920x1008/180

    rem Get display id of auxiliary display device
    rem %CMD_SCRCPY% %ADB_SERIAL% --list-displays | %CMD_ADB% %ADB_SERIAL% shell "grep -o 'display-id=[1-9][0-9]*' | sed 's/display-id=\([1-9][0-9]*\)/\1/'" > %TEMP_FILE%
    rem set /p DISPLAY_ID=<%TEMP_FILE%
    rem del %TEMP_FILE%
    rem call :f_log i,"Display id: %DISPLAY_ID%"

    rem Show tips
    call :f_tips

    rem Run apps
    call :f_run_before

    rem Run scrcpy
    rem keyboard=[sdk, uhid, aoa, disabled]
    rem video-codec=h265, scrcpy.exe --list-encoders
    %CMD_SCRCPY% %ADB_SERIAL% --new-display=%DISPLAY_W%x%DISPLAY_H%/%DISPLAY_DPI% --keyboard=sdk --mouse=sdk --no-audio --no-vd-destroy-content --power-off-on-close --push-target=/sdcard/Download/ --shortcut-mod="lctrl,rctrl" --show-touches --stay-awake --turn-screen-off --video-codec=h265 --video-encoder=c2.qti.hevc.encoder --window-title="%PHONE_NAME% - Android Desktop Mode"--window-width=%DISPLAY_W% --window-height=%DISPLAY_H% --window-x=0 --window-y=25
    rem %CMD_SCRCPY% %ADB_SERIAL% --display-id=%DISPLAY_ID% --keyboard=sdk --mouse=sdk --no-audio --no-vd-destroy-content --power-off-on-close --push-target=/sdcard/Download/ --shortcut-mod="lctrl,rctrl" --show-touches --stay-awake --turn-screen-off --window-title="%PHONE_NAME% - Android Desktop Mode" --window-x=0 --window-y=25

    rem Stop apps
    call :f_run_after

    rem Turn off auxiliary display device
    rem %CMD_ADB% %ADB_SERIAL% shell settings put global overlay_display_devices null
goto :eof

:end
