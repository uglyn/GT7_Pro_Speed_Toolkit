@echo off
chcp 936 >nul
setlocal enabledelayedexpansion

call "%modulesDir%header.bat" "%~nx0" "" "cls"

set "waitNo=0"
set "activeSlot="
set "inActiveSlot="
set "slotCount=2"

:start
set /a "waitNo+=1"

"%adbp%" devices 2>nul | findstr /i "device$" >nul
if not errorlevel 1 (
    call "%modulesDir%logger.bat" "%~nx0"  "找到adb设备"
    for /f "delims=" %%a in ('%adbp% shell getprop ro.boot.slot_suffix 2^>nul') do set "activeSlot=%%a"
)

"%fastbootp%" devices 2>nul | findstr /i "fastboot" >nul
if not errorlevel 1 (
    call "%modulesDir%logger.bat" "%~nx0"  "找到fastboot设备"

    set "slotTmp=%tempDir%slot_tmp.txt"
    type nul > "!slotTmp!" 2>nul

    "%fastbootp%" getvar current-slot > "!slotTmp!" 2>&1
    for /f "tokens=2 delims=:" %%a in ('findstr /i "current-slot" "!slotTmp!"') do (
        set "temp_slot=%%a"
        for /f "tokens=* delims= " %%b in ("!temp_slot!") do set "activeSlot=%%b"
        call "%modulesDir%logger.bat" "%~nx0"  "找到卡槽：!activeSlot!"
    )

    "%fastbootp%" getvar slot-count > "!slotTmp!" 2>&1
    for /f "tokens=2 delims=:" %%a in ('findstr /i "slot-count" "!slotTmp!"') do (
        set "temp_count=%%a"
        for /f "tokens=* delims= " %%b in ("!temp_count!") do set "slotCount=%%b"
        call "%modulesDir%logger.bat" "%~nx0"  "卡槽数量：!temp_count!"
    )

    if exist "!slotTmp!" del "!slotTmp!" >nul 2>&1
)

rem 过滤掉设备抽风返回的等号
if "!activeSlot!"=="=" set "activeSlot="

if "!activeSlot!"=="_a" goto enda
if "!activeSlot!"=="a" goto enda
if "!activeSlot!"=="_b" goto endb
if "!activeSlot!"=="b" goto endb

timeout /t 5 /nobreak >nul
if !waitNo! geq 2 echo( 已等待  !waitNo!*5  秒.....
if !waitNo! geq 4 (
    echo(等待时间太久 无法获取卡槽 确保手机正确连接
    goto exitb1
)
goto start

:enda
set "activeSlot=a"
set "inActiveSlot=b"
goto end

:endb
set "activeSlot=b"
set "inActiveSlot=a"
goto end

:end
set "inSlot=!activeSlot!"
echo(活动槽位: !activeSlot! 
echo(闲置槽位: !inActiveSlot! 
echo(原始槽位: !inSlot! 
echo(卡槽数量：!slotCount!
call "%modulesDir%logger.bat" "%~nx0"  "活动槽位: !activeSlot!  闲置槽位: !inActiveSlot! "
endlocal & set "activeSlot=%activeSlot%" & set "inActiveSlot=%inActiveSlot%" & set "inSlot=%inSlot%" & set "slotCount=%slotCount%"
call "%modulesDir%usertimeout.bat"
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1