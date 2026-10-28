@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
type nul > "%pd0Dir%toolbox_busy.lock" 2>nul
rem  参数："脚本名字" "工具"  "清屏" "锁定"
if /i "%~3"=="cls" cls 
echo.
echo.
if not "%~1"=="" echo([%time%] %~1 脚本启动
call "%modulesDir%logger.bat" "%~1"  "脚本启动"
exit /b 0

