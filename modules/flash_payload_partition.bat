@echo     off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0"  "" "cls"

call :log "获取img来源"
call "%modulesDir%choose_source.bat" "imgDir" "imgList" "  线刷包 或 卡刷包.img  "  || exit /b 1

call :log "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

call :log "获取设备卡槽"
call "%modulesDir%get_slot.bat"  "fastboot" || exit /b 1
cls
echo.    
echo     --------------------------------------------------------------------------------------------
echo     活动卡槽: %activeSlot%                  闲置卡槽: %inActiveSlot%  
echo.    
echo     纯fastbootD  可能无法刷写modem   
echo.    
echo     镜像目录: %imgDir%          正在 线刷 物理分区 到  闲置卡槽:%inActiveSlot%  
echo     --------------------------------------------------------------------------------------------
echo     确认信息  闲置卡槽不影响你的 活动卡槽系统      不补刷modem 不影响fastboot
echo.    
choice /c 1 /n /m "请选择 [1] 继续: "

call :log "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" || exit /b 1

  set "activeSlot=%inActiveSlot%"
  call :log "刷写物理分区到 %inActiveSlot% 卡槽"
  call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%superParts%" 0  || exit /b 1

cls
echo.  
set "activeSlot=%inSlot%"
echo      ------------------------------------------------------------------------
echo     刷写结束！  如果 modem  刷写失败   可手动补刷
echo.    
echo     当前槽位:%activeSlot%     不补刷modem 不影响fastboot 功能
echo.    
echo     10秒后重启手机   不想重启可以 断开手机 或者 关闭脚本
echo.    
echo      ------------------------------------------------------------------------

timeout /t 10 
fastboot reboot
call :log "手机已重启到卡槽:%activeSlot%,刷写流程结束"
exit /b 1

:log
echo     %time% %~1 >> "%logFile%"
goto :eof