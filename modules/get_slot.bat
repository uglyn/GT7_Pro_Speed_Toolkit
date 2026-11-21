@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "cls"

rem ===== 参数落地：传了用传入的变量名，没传用默认名 =====
set "out1=activeSlot"
set "out2=inActiveSlot"
set "out3=slotCount"
if not "%~1"=="" set "out1=%~1"
if not "%~2"=="" set "out2=%~2"
if not "%~3"=="" set "out3=%~3"

set "waitNo=0"
set "activeSlot=qq11066851"
set "inActiveSlot=qq11066851"
set "slotCount=2"

:start
set /a "waitNo+=1"

%adbp% devices 2>nul | findstr /i "device$" >nul
if not errorlevel 1 (
    call "%modulesDir%logger.bat" "%~nx0"  "找到adb设备"
    for /f "delims=" %%a in ('%adbp% shell getprop ro.boot.slot_suffix 2^>nul') do if not "%%a"=="" set "activeSlot=%%a"
    for /f "delims=" %%a in ('%adbp% shell bootctl get-number-slots 2^>nul') do set "slotCount=%%a"
)

"%fastbootp%" devices 2>nul | findstr /i "fastboot" >nul
if not errorlevel 1 (
    call "%modulesDir%logger.bat" "%~nx0"  "找到fastboot设备"
    for /f "tokens=2 delims=:" %%a in ('%fastbootp% getvar current-slot 2^>^&1 ^| findstr /i "current-slot"') do set "activeSlot=%%a"
    for /f "tokens=2 delims=:" %%a in ('%fastbootp% getvar slot-count 2^>^&1 ^| findstr /i "slot-count"') do (
        set "slotCount=%%a"
        set "slotCount=!slotCount: =!"
    )
)

rem ===== 统一清洗 activeSlot：去空格、去下划线，首字符 a/b 归一，否则哨兵 =====
set "activeSlot=!activeSlot: =!"
set "activeSlot=!activeSlot:_=!"
if "!slotCount!"=="1" set "inActiveSlot=!activeSlot!"
if "!activeSlot!"=="a" (
    if not "!slotCount!"=="1" set "inActiveSlot=b"
    goto end
)
if "!activeSlot!"=="b" (
    if not "!slotCount!"=="1" set "inActiveSlot=a"
    goto end
)

timeout /t 5 /nobreak >nul
if !waitNo! geq 2 echo( 已等待  !waitNo!*5  秒.....
if !waitNo! geq 4 (
    echo(等待时间太久 无法获取卡槽 确保手机正确连接
    goto exitb1
)
goto start

:end
call "%modulesDir%logger.bat" "%~nx0"  "活动槽位: !activeSlot!  闲置槽位: !inActiveSlot! 卡槽数量：!slotCount!"
call "%modulesDir%usertimeout.bat" "%~nx0"  "活动槽位: !activeSlot!"  "闲置槽位: !inActiveSlot!" "卡槽数量：!slotCount!"
endlocal & set "%out1%=%activeSlot%" & set "%out2%=%inActiveSlot%" & set "%out3%=%slotCount%"
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1