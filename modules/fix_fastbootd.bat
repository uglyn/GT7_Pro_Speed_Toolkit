@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0"  "cls"

call "%modulesDir%choose_source.bat" "imgDir" "imglist" "线刷包或者卡刷包.img" || exit /b 1
set "imgDir=!imgDir:"=!"

set "fastbootdList=%configDir%fastbootd.txt"

call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "重启到bootloader"

call "%modulesDir%logger.bat" "%~nx0"  "刷写列表%fastbootdList%"
call "%modulesDir%flash_images.bat" "%imgDir%" "%fastbootdList%" "" 0 || exit /b 1
call "%modulesDir%wait_fastboot_device.bat" "fastboot"
call "%modulesDir%logger.bat" "%~nx0"  "手机重启到fastboot"
exit /b 0

