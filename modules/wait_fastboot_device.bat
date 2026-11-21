@echo off
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" 

set "target=%~1"
set "waitNo=0" 
set "reboot_count=0"

for %%m in (adb bootloader fastboot reboot) do (
    if /i "%target%"=="%%m" goto target_ok
)
    echo(重启模式错误。
    goto exitb1

:target_ok
cls
echo.
echo(---------------------------------- 等待设备进入%target%模式 --
echo.
echo([0]adb模式请打开  开发者和usb调制  
echo.   
echo([1]fastboot模式是fastbootd模式 
echo.
echo([2]bootloader是fastboot模式
echo.
echo([3]如果已经进入[%target%]模式 找不到手机 请检查_驱动_数据线_手机是否已经链接电脑...
echo.
echo([4]开机状态打开 USB调制 可自动进入%target% 
echo.
echo(---------------------------------- 请手动进入%target% 并连接电脑 ---------
:wait_loop
set "cur="
set /a "waitNo+=1"
"%fastbootp%" devices 2>nul | findstr /i "fastboot" >nul
if not errorlevel 1 (
    set "tools=%fastbootp%"
    set "cur=bootloader"
    "%fastbootp%" getvar is-userspace 2>&1 | findstr /i "yes" >nul
    if not errorlevel 1 set "cur=fastboot"
)
%adbp% devices 2>nul | findstr /i "device$" >nul
if not errorlevel 1 (
    set "tools=%adbp%"
    set "cur=adb"
)
    if /i "!cur!"=="%target%" goto end
    if defined cur goto reboot
    rem  走到这里，说明 cur 是空的（没找到设备） 
    if /i "%target%"=="reboot" (
        echo(未检测到设备，直接退出。
        goto exitb1
    )

timeout /t 5 /nobreak >nul
if !waitNo! geq 5 echo( 已等待  !waitNo!*5  秒.....
if !waitNo! geq 15 (
echo(等待时间太久,请手动进入[%target%] 后重试
goto exitb1
)
goto wait_loop

:reboot
set /a reboot_count+=1
echo(正在重启设备，请勿操作 大约20秒  %reboot_count%
if !reboot_count! gtr 2 (
    echo(错误：已尝试重启 !reboot_count! 次，仍未能进入目标模式 [%target%]
    goto exitb1
)

if /i "%target%"=="reboot" (
"%tools%" reboot
exit /b 0
)
if /i "%target%"=="adb" (
%tools% reboot
timeout /t 8
)
if /i not "%target%"=="adb" %tools% reboot %target%
goto wait_loop

:end
call "%modulesDir%logger.bat" "%~nx0"  "已经连接到%target%"
call "%modulesDir%usertimeout.bat" "已经连接到%target%"
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1
