@echo off
echo.
:: echo 参数："脚本名字" "工具"  "清屏" "锁定"
if /i "%~3"=="cls" cls
if not "%~1"=="" echo [%time%] %~1 脚本启动
if not "%~2"=="" echo 使用工具:%~2
