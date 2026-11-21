@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
set "debug=qq110668511"
echo.
if not "%debug%"=="qq11066851" (
    if not "%~1"==""  echo(参数1:%~1
    if not "%~2"=="" echo(参数2:%~2
    if not "%~3"=="" echo(参数3:%~3
    if not "%~4"=="" echo(参数4:%~4
)
echo. 
echo(等待时间长短  请修改 %~f0 
echo(-------------------------------------------------------------------------
echo(卡住请手动按任意键...

rem 等待时间修改脚本 timeout /t 后面的数字
rem 修改下面的数字

timeout /t 2
exit /b 0
