@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"
call :log "========== 修复 fastbootd 模式启动 =========="
call "%modulesDir%choose_source.bat" "imgDir" "imglist" "线刷包或者卡刷包.img" || exit /b 1
set "fastbootdList=%configDir%fastbootd.txt"
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1
call "%modulesDir%flash_images.bat" "%imgDir%" "%fastbootdList%" "" 0
%fastbootPath% reboot fastboot
echo 修复完成，正在尝试重启到fastboot...
call :log "手机已重启，修复流程结束"
exit /b 0
:log
echo %time% %~1 >> "%logFile%"
goto :eof