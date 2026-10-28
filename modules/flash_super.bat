@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

call "%modulesDir%logger.bat" "%~nx0"  "添加img来源"
call "%modulesDir%choose_source.bat" "imgDir" "imglist"  "线刷包文件夹或者卡刷包.img" || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "重启到fastbootd"
call "%modulesDir%wait_fastboot_device.bat" "fastboot" || exit /b 1
cls
echo(-----------------------------------------------------------------------------
echo.
echo(镜像目录: %imgDir%   项目: 刷写super
echo.
echo(-----------------------------------------------------------------------------
set /p confirm=确认开始刷写？输入 y 回车继续，其他任意键取消: 
if /i not "%confirm%"=="y" (
    call "%modulesDir%logger.bat" "%~nx0"  "用户取消刷写"
    exit /b 0
)

call "%modulesDir%logger.bat" "%~nx0"  "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" || exit /b 1

::set "activeSlot="
call "%modulesDir%flash_images.bat" "%imgDir%" "%superParts%" "" 1  || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "刷写流程结束  "

cls
echo.
echo(    --------------------------------------------------------------------------------------------
echo.
echo(    super分区刷写完成
exit /b 11

