@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""
call "%modulesDir%wait_fastboot_device.bat" "reboot"
exit /b 1

:log
>>"%logFile%" echo(%time% %~1
goto :eof