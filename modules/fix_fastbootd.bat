@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

call "%modulesDir%choose_source.bat" "imgDir" "imglist" "  线刷包或者卡刷包.img  " || exit /b 1

set "fastbootdList=%configDir%fastbootd.txt"

call :log "重启到bootloader 可修改成fastboot"
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

call :log "刷写列表%fastbootdList%"
call "%modulesDir%flash_images.bat" "%imgDir%" "%fastbootdList%" "" 0

echo.
echo 修复完成，正在尝试重启到fastboot...
echo.
echo 如果不开机 禁用开机校验
echo.
%fastbootp% reboot fastboot
call :log "手机已重启，修复流程结束"
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof