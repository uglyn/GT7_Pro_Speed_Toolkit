@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""
if "%~1"=="" exit /b 1
set "choice=%~1"

:: 1. 白名单拦截：如果是帮助命令，直接跳过去执行，不查设备
echo !choice! | findstr /i /c:"--" /c:"help"  >nul
if not errorlevel 1 goto run_cmd

:: 检查如果是 adb 命令
if /i "!choice:~0,4!"=="adb " (
    %adbp% devices 2>nul | findstr /r /c:"[0-9A-Za-z].*device$" >nul
    if errorlevel 1 (
        echo(    [错误] 没有检测到adb设备
        exit /b 1
    )
    call "%modulesDir%logger.bat" "%~nx0"  "检测到adb设备..."    
)

:: 检查如果是 fastboot 命令
if /i "!choice:~0,9!"=="fastboot " (
    %fastbootp% devices 2>nul | findstr /r /c:"[0-9A-Za-z].*fastboot$" >nul
    if errorlevel 1 (
        echo(    [错误] 没有检测到fastboot设备
        exit /b 1
    )
    call "%modulesDir%logger.bat" "%~nx0"  "检测到fastboot设备..."
)

rem 执行命令
:run_cmd
    echo 正在执行命令:!choice!
    cmd /c "!choice!" 
    exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

