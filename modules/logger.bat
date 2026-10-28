@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
rem 参数1: 哪个脚本触发的日志
rem 参数2: 日志的具体内容
>>"%logFile%" echo([%time%] [%~1] %~2%~3
exit /b 0