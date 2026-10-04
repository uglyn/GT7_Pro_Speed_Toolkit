@echo     off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0"  "" "cls"

  set "specialList=%configDir%special.txt"
  if not exist "%specialList%" (
    echo     特殊分区表找不到
    pause
    exit /b 1
  )
  set "excludeList=%tempDir%exclude_all.txt"
  type nul > "!excludeList!" 2>nul
  set "vbdisable=%configDir%vbdisable.txt"
  if not exist "%vbdisable%" (
    echo     找不到禁用校验列表
    pause
    exit /b 1
  )

call :log "获取img来源"
call "%modulesDir%choose_source.bat" "imgDir" "imgList" "线刷包 或 卡刷包.img"  || exit /b 1

call :log "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

call :log "获取设备卡槽"
call "%modulesDir%get_slot.bat" "fastboot" || exit /b 1
cls
echo.
echo     --------------------------------------------------------------------------------------------
echo                活动卡槽: %activeSlot%            闲置卡槽:%inActiveSlot% 刷写卡槽
echo.
echo                镜像目录: %imgDir%          正在 线刷  卡刷包 或者 线刷包
echo.
echo                刷机中会多次重启!!!   莫慌 莫慌
echo     --------------------------------------------------------------------------------------------

choice /c 1 /n /m "请选择 [1]: "
choice /c x /n /t 1 /d x /m "输入已接收，正在继续..."

call :log "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" || exit /b 1

  copy "%superParts%" "%excludeList%" >nul
  type "%specialList%" >> "%excludeList%"

call :log "刷写到闲置卡槽%inActiveSlot% "
set "activeSlot=%inActiveSlot%"

call :log "清空super" 
set "superImg=%imagesDir%super\super_empty_15gb.img"
if not exist "%superImg%"  (
 echo 没有superImg 文件
 pause
 exit /b 1
)

call :log "清空super分区"
echo %fastbootPath% flash super "%superImg%"
%fastbootPath% flash super "%superImg%"

call :log "刷写super动态分区"
call "%modulesDir%flash_images.bat" "%imgDir%" "%superParts%" "" 1 || exit /b 1
echo     --------------------------------------------------------------------------------------------
echo      第一阶段结束 [1/2]  共二阶段  设备重启多次 莫慌
echo.
echo      [AB包 卡刷包] super逻辑分区 刷完
echo     --------------------------------------------------------------------------------------------

call :log "等待设备进bootloader"
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

cls
call :log "第二阶段：刷写特殊分区到卡槽:%inActiveSlot%"
call "%modulesDir%flash_images.bat" "%imgDir%" "%specialList%" "" 3  || exit /b 1

call :log "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

call :log "第二阶段：刷写物理分区到 %inActiveSlot% 卡槽"
call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%excludeList%" 0  || exit /b 1
del "%excludeList%"  2>nul

echo     --------------------------------------------------------------------------------------------
echo      第二阶段结束.[2/2]  共二阶段 设备重启多次 莫慌
echo.
echo      已经将[AB包 卡刷包] 物理分区 刷完
echo     --------------------------------------------------------------------------------------------

:end
cls
echo.
%fastbootp% erase frp
set "activeSlot=%inSlot%"
echo     --------------------------------------------------------------------------------------------    
echo.
echo       刷机结束！  结束了  重启手机就行  
echo.     
echo      当前卡槽:%activeSlot%    已经刷机到: %inActiveSlot%  
echo.
echo      默认 禁用 vbmeta vbmeta_system vbmeta_vendor 开机VB校验
echo.
echo      可以刷原厂 vbmeta.img vbmeta_system.img vbmeta_vendor.img   还原
echo.
echo     --------------------------------------------------------------------------------------------
echo.
echo  10秒后切换卡槽.    并重启   [卡槽必须切换]
echo.
timeout /t 10 
"fastbootp" set_active "%inActiveSlot%"
"fastbootp" reboot
call :log "手机已重启到卡槽:%activeSlot%,刷写流程结束"
exit /b 1

:log
echo     %time% %~1 >> "%logFile%"
goto :eof