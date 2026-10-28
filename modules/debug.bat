@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"
echo(参数1:%1 
echo(参数2:%2
echo(参数3:%3
echo(参数4:%4
call "%modulesDir%usertimeout.bat"
exit /b 0
