@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""
if "%~1"=="" exit /b 1


:: 如果是查 ADB
if /i "%~1"=="adb" (
        
    %adbp% devices 2>nul | findstr /r /c:"[0-9A-Za-z].*device$" >nul
    if errorlevel 1 (
        echo(    [错误] 没有检测到adb设备
        exit /b 1
    )
    call "%modulesDir%logger.bat" "%~nx0"  "检测到adb设备..."
)

:: 如果是查 Fastboot
if /i "%~1"=="fastboot" (
    %fastbootp% devices 2>nul | findstr /r /c:"[0-9A-Za-z].*fastboot$" >nul
    if errorlevel 1 (
        echo(    [错误] 没有检测到fastboot设备
        exit /b 1
    )
    call "%modulesDir%logger.bat" "%~nx0"  "检测到fastboot设备..."
)
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

