@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
echo.
echo(参数1:%1   
echo(参数2:%2
echo. 
echo(等待时间长短  请修改 %~f0 
echo(-------------------------------------------------------------------------
echo(卡住请手动按任意键...

rem 等待时间修改脚本 timeout /t 后面的数字
rem 修改下面的数字

timeout /t 2

exit /b 0
