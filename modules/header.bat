@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
rem  参数："脚本名字" "工具"  "清屏" "锁定"
if /i "%~3"=="cls" cls 
echo.
echo.
if not "%~1"=="" echo [%time%] %~1 脚本启动
if not "%~2"=="" echo 使用工具:%~2
call :log "========== [%time%] %~1 脚本启动 =========="
exit /b 0
:log
echo %time% %~1 >> "%logFile%"
goto :eof
