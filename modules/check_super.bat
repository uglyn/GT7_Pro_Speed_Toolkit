@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%fastbootp%" "cls"

:menu
echo(============================================
echo(请选择要刷写的 super 分区大小：  super数据丢失 之后用功能8
echo.
echo(  1 - 14.5G   官方大小  默认
echo.
echo(  2 -  25G    双系统专用   
echo(============================================
choice /c 12 /n /m  " 请输入数字 [1/2]: "
set "usersel=!errorlevel!"
set "imgFile="
if "!usersel!"=="1" set "imgFile=%imagesDir%super\super14.5_empty.img"
if "!usersel!"=="2" set "imgFile=%imagesDir%super\super25_empty.img"

cls
echo.
echo(即将刷写：%imgFile% 
timeout /t 2
echo.

call "%modulesDir%logger.bat" "%~nx0"  "重启到bootloader"
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "%fastbootp% wipe-super %imgFile%"
echo(%fastbootp% wipe-super %imgFile%
"%fastbootp%" wipe-super "%imgFile%"
if errorlevel 1 (
    echo(实在不行 工具箱首页执行 fastboot wipe-super %imgFile%
    echo(刷写失败，请检查设备连接或文件是否正确。
    goto exitb1
)

:end
echo.
echo(    --------------------------------------------------------------------------------------------
echo.
echo(     super已经初始化,请补刷super  (脚本功能8 不要刷super.img)
echo.
echo(    --------------------------------------------------------------------------------------------
exit /b 1

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

