@echo off
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

set "target=%~1"
set "mode=%target%"
set "waitNo=0" 
set "reboot_count=0"

for %%m in (adb bootloader fastboot recovery reboot) do (
    if /i "%target%"=="%%m" goto target_ok
)
    echo 重启模式错误。
    pause
    exit /b 1

:target_ok
echo -----------------------------------------------------------------------------------------------
echo [0] 等待设备进入[%target%]模式   
echo [1] adb模式需要打开 开发者usb调制   twrp也有adb模式      
echo [2] fastboot模式是fastbootd模式  FB模式是 fastbootd和bootloader 都可以
echo [3] 如果已经进入[%target%]模式   长时间找不到手机 请检查_驱动_数据线_手机是否已经链接电脑.
echo -----------------------------------------------------------------------------------------------

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
"%adbp%" devices 2>nul | findstr /i "device$" >nul
if not errorlevel 1 (
    set "tools=%adbp%"
    set "cur=adb"
)
    if /i "!cur!"=="%target%" goto end
    if defined cur goto reboot

timeout /t 5 /nobreak >nul

if !waitNo! geq 5 echo  已等待  !waitNo!*5  秒.....
if !waitNo! geq 12 (
echo 等待时间太久,请手动进入[%target%]
pause
)
goto wait_loop


:reboot
set /a reboot_count+=1
echo 设备已重启，请勿操作 大约20秒  %reboot_count%
if !reboot_count! gtr 2 (
    echo 错误：已尝试重启 !reboot_count! 次，仍未能进入目标模式 [%target%]
    pause
    exit /b 1
)

if /i "%target%"=="reboot" (
"%tools%" reboot
exit /b 0
)

if /i "%target%"=="adb" set "mode="
"%tools%" reboot %mode%
goto wait_loop

:end
echo "已进入%target%模式">> "%logFile%"
exit /b 0

:log
echo     %time% %~1 >> "%logFile%"
goto :eof