@echo off
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

set "target=%~1"
set "waitNo=0" 
set "reboot_count=0"
for %%m in (adb bootloader fastboot recovery reboot FB) do (
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
del "%tempDir%dev.tmp" "%tempDir%adb.tmp" 2>nul
"%adbPath%" devices > "%tempDir%adb.tmp" 2>nul
findstr /i "device$" "%tempDir%adb.tmp" >nul
if not errorlevel 1 (
    set "tools=%adbPath%"
    if /i "%target%"=="adb"  goto end
    goto reboot
)
"%fastbootPath%" devices > "%tempDir%dev.tmp" 2>nul
findstr /i "fastboot" "%tempDir%dev.tmp" >nul
if not errorlevel 1 (
    set "tools=%fastbootPath%"
    "%fastbootPath%" getvar is-userspace > "%tempDir%is_user.tmp" 2>&1
    for /f "tokens=2 delims=:" %%a in ('findstr /c:"is-userspace" "%tempDir%is_user.tmp"') do set "val=%%a"
    set "val=!val: =!"
    if /i "!val!"=="yes" set "cur=fastboot"
    if /i "!val!"=="no"  set "cur=bootloader"
    if /i "!cur!"=="%target%" goto end
    goto reboot
)
timeout /t 3 /nobreak >nul
set /a "waitNo+=1"
set /a "mod=waitNo%%5"
if !mod! equ 0 echo  已等待  !waitNo!*3  秒.....
if !waitNo! geq 20 (
echo 等待时间太久,请手动进入[%target%]
pause
)
goto wait_loop
:reboot
set /a reboot_count+=1
echo 重启设备中，请耐心等待 大约20秒 %reboot_count%
if !reboot_count! gtr 2 (
    echo 错误：已尝试重启 !reboot_count! 次，仍未能进入目标模式 [%target%]
    pause
    exit /b 1
)
if /i "%target%"=="reboot" (
"%tools%" reboot
exit /b 0
)
if /i "%target%"=="adb" (
"%tools%" reboot
goto wait_loop
)
"%tools%" reboot %target%
if /i "%target%"=="fastboot" goto wait_loop
timeout /t 15 /nobreak >nul
goto wait_loop

:end
echo "已进入%target%模式">> "%logFile%"
exit /b 0