@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0"  "" "cls"

call "%modulesDir%logger.bat" "%~nx0"  "获取img来源"
call "%modulesDir%choose_source.bat" "imgDir" "imgList" "线刷包 或 卡刷包.img"  || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" "fastboot" || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "获取设备卡槽"
call "%modulesDir%get_slot.bat"  "fastboot" || exit /b 1
cls
echo.    
echo(    --------------------------------------------------------------------------------------------
echo(    活动卡槽: %activeSlot%                  闲置卡槽: %inActiveSlot%  
echo.    
echo(    纯fastbootD刷写
echo.    
echo(    镜像目录: %imgDir%          正在线刷 物理分区 到  闲置卡槽:%inActiveSlot%  
echo(    --------------------------------------------------------------------------------------------
echo(    确认信息  闲置卡槽不影响你的 活动卡槽的系统  
echo.    
choice /c 1 /n /m "请选择 [1] 继续: "

call "%modulesDir%logger.bat" "%~nx0"  "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" || exit /b 1

set "activeSlot=%inActiveSlot%"
call "%modulesDir%logger.bat" "%~nx0"  "刷写物理分区到 %inActiveSlot% 卡槽"
call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%superParts%" 0  || exit /b 1

cls
echo.  
set "activeSlot=%inSlot%"
echo(    --------------------------------------------------------------------------------------------
echo(    刷写结束！  modem 如果失败不影响
echo.    
echo(    当前槽位:%activeSlot%     已刷物理分区到:%inActiveSlot%  
exit /b 11

