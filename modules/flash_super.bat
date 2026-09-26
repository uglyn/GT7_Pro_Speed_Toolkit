@echo off
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%fastbootPath%" "cls"
call :log "==========刷写super启动 =========="
call "%modulesDir%choose_source.bat" "imgDir" "imglist"  "线刷包文件夹或者卡刷包.img" || exit /b 1
call "%modulesDir%wait_fastboot_device.bat" fastboot
call :log "获取设备卡槽"
call "%modulesDir%get_slot.bat" || exit /b 1
cls
echo -----------------------------------------------------------------------------
echo 刷写卡槽: %activeSlot%(活动卡槽) 
echo.
echo 镜像目录: %imgDir%
echo -----------------------------------------------------------------------------
set /p confirm=确认开始刷写？输入 y 回车继续，其他任意键取消: 
if /i not "%confirm%"=="y" (
    call :log "用户取消刷写"
    exit /b 0
)

call :log "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "imgDir" || exit /b 1
call "%modulesDir%flash_images.bat" "%imgDir%" "%superParts%" "" 1
"%fastbootPath%" reboot
echo 刷写完成，正在重启手机...
call :log "手机已重启，刷写流程结束"
exit /b 0
:log
echo %time% %~1 >> "%logFile%"
goto :eof