@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""
adb shell lpdump > lpdump.txt
exit /b 1

:log
>>"%logFile%" echo(%time% %~1
goto :eof