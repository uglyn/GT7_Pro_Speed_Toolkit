@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

call :log "添加img来源"
call "%modulesDir%choose_source.bat" "imgDir" "imglist"  "线刷包文件夹或者卡刷包.img" || exit /b 1

call :log "重启到fastbootd"
call "%modulesDir%wait_fastboot_device.bat" fastboot
cls
echo -----------------------------------------------------------------------------
echo.
echo 镜像目录: %imgDir%   项目: 刷写super
echo.
echo -----------------------------------------------------------------------------
set /p confirm=确认开始刷写？输入 y 回车继续，其他任意键取消: 
if /i not "%confirm%"=="y" (
    call :log "用户取消刷写"
    exit /b 0
)

call :log "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "imgDir" || exit /b 1

::set "activeSlot="
call "%modulesDir%flash_images.bat" "%imgDir%" "%superParts%" "" 1

cls
echo.
echo   -----------------------------------------------------------------
echo.
echo   刷写完成，10秒后重启手机...  
echo.
echo  不想重启 断开手机 或者 关闭脚本
echo.
echo   -----------------------------------------------------------------

timeout /t 10 
%fastbootp% reboot
call :log "手机已重启，刷写流程结束  "
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof