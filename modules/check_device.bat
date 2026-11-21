@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""
if "%~1"=="" exit /b 1

:: 1. 用 %* 接收全部参数
set "choice=%*"

rem 去空格
:trim_space
if "!choice:~0,1!"==" " (
    set "choice=!choice:~1!"
    goto trim_space
)
set "check_cmd=!choice:"=!"
:: 3. 白名单拦截
echo !check_cmd! | findstr /i /c:"--" /c:"help"  >nul
if not errorlevel 1 goto run_cmd

:: 4. adb 判断
if /i "!check_cmd:~0,4!"=="adb " (
    %adbp% devices 2>nul | findstr /r /c:"[0-9A-Za-z].*device$" >nul
    if errorlevel 1 (
        echo(    [错误] 没有检测到adb设备
        exit /b 1
    )
    call "%modulesDir%logger.bat" "%~nx0"  "检测到adb设备..."    
)

:: 5. fastboot 判断
if /i "!check_cmd:~0,9!"=="fastboot " (
    %fastbootp% devices 2>nul | findstr /r /c:"[0-9A-Za-z].*fastboot$" >nul
    if errorlevel 1 (
        echo(    [错误] 没有检测到fastboot设备
        exit /b 1
    )
    call "%modulesDir%logger.bat" "%~nx0"  "检测到fastboot设备..."
)

:run_cmd
    echo 正在执行命令:!choice!
    :: 6. 用 call 执行，完美保留带空格路径的引号
    call !choice!
    exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1