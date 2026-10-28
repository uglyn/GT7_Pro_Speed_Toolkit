@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

call "%modulesDir%choose_source.bat" "imgDir" "imglist" "线刷包或者卡刷包.img" || exit /b 1

set "fastbootdList=%configDir%fastbootd.txt"

call "%modulesDir%logger.bat" "%~nx0"  "重启到bootloader 可修改成fastboot"
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "刷写列表%fastbootdList%"
call "%modulesDir%flash_images.bat" "%imgDir%" "%fastbootdList%" "" 0 || exit /b 1

echo(修复完成，正在尝试重启到fastboot...
call "%modulesDir%logger.bat" "%~nx0"  "手机已重启到fastboot"
exit /b 11

