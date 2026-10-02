@echo     off
setlocal enabledelayedexpansion
call :log "========== 线刷卡刷包启动 =========="
call "%modulesDir%header.bat" "%~nx0"  "" "cls"

  set "excludeList=%tempDir%exclude_all.txt"
  type nul > %excludeList" 2>nul

  set "specialList=%configDir%special.txt"
  if not exist "%specialList%" (
    echo     特殊分区表找不到
    call :log "特殊分区表找不到"
    goto error
  )

  set "vbdisable=%configDir%vbdisable.txt"
  if not exist "%vbdisable%" (
    echo     找不到禁用校验列表
    call :log "找不到禁用校验列表"
    goto error
  )

call :log "获取img来源"
call "%modulesDir%choose_source.bat" "imgDir" "imgList" "  线刷包或者卡刷包.img  "  || exit /b 1

call :log "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

call :log "获取设备卡槽"
call "%modulesDir%get_slot.bat" "fastboot" || exit /b 1
cls
echo.
echo     --------------------------------------------------------------------------------------------
echo                活动卡槽: %activeSlot%            闲置卡槽:%inActiveSlot%
echo.
echo                镜像目录: %imgDir%                选1 2都行 都是正常刷机   
echo     --------------------------------------------------------------------------------------------
echo.
echo     [1]单  刷  只刷活动卡槽:%activeSlot%    可以保留闲置卡槽物理分区
echo.
echo     [2]AB通刷  同时刷写:%activeSlot% %inActiveSlot%两个卡槽    保证闲置卡槽物理有数据  
echo.
echo     --------------------------------------------------------------------------------------------

choice /c 12 /n /m "请选择 [1/2]: "
set "mode=!errorlevel!"
choice /c x /n /t 1 /d x /m "输入已接收，正在继续..."

call :log "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" || exit /b 1

copy "%superParts%" "%excludeList%" >nul
type "%specialList%" >> "%excludeList%"

:start

call :log "第一阶段：刷写super动态分区" 
::call "%modulesDir%flash_images.bat" "%imgDir%" "%superParts%" "" 1 || exit /b 1
echo     --------------------------------------------------------------------------------------------
echo      第一阶段结束 [1/2]  共二阶段  设备重启多次 莫慌
echo.
echo      [AB包 卡刷包] super逻辑分区 刷完
echo     --------------------------------------------------------------------------------------------

call :log "等待设备进bootloader"
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

cls
call :log "第二阶段：刷写特殊分区到卡槽:%activeSlot%"
call "%modulesDir%flash_images.bat" "%imgDir%" "%specialList%" "" 3  || exit /b 1

if "%mode%"=="1" goto onlya1
if not "%inActiveSlot%"=="" if /i not "%inActiveSlot%"=="%activeSlot%" (
  set "activeSlot=%inActiveSlot%"
  call :log "第二阶段：刷写特殊分区到卡槽:%inActiveSlot%"
  call "%modulesDir%flash_images.bat" "%imgDir%" "%specialList%" "" 3  || exit /b 1
)

:onlya1
call :log "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

set "activeSlot=%inSlot%"
call :log "第二阶段：刷写物理分区到 %activeSlot% 卡槽"
call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%excludeList%" 0  || exit /b 1
call :log "禁用卡槽:%activeSlot% VB验证"
call "%modulesDir%flash_images.bat" "%imgDir%" "%vbdisable%" "" 2  || exit /b 1

if "%mode%"=="1" goto onlya2
if not "%inActiveSlot%"=="" if /i not "%inActiveSlot%"=="%activeSlot%" (
set "activeSlot=%inActiveSlot%"
call :log "第二阶段：刷写物理分区到%inActiveSlot%卡槽"
call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%excludeList%" 0  || exit /b 1
call :log "禁用卡槽:%inActiveSlot% VB验证"
call "%modulesDir%flash_images.bat" "%imgDir%" "%vbdisable%" "" 2  || exit /b 1
)

:onlya2
echo     --------------------------------------------------------------------------------------------
echo      第二阶段结束.[2/2]  共二阶段 设备重启多次 莫慌
echo.
echo      已经将[AB包 卡刷包] 物理分区 刷完
echo     --------------------------------------------------------------------------------------------

:end
del "%excludeList%"  2>nul

cls
echo.
"fastbootp" erase frp
set "activeSlot=%inSlot%"
echo     --------------------------------------------------------------------------------------------    
echo.
echo     刷机结束！当前槽位:%activeSlot%      结束了
echo.
echo      默认 禁用 vbmeta vbmeta_system vbmeta_vendor 开机VB校验
echo.
echo     可以刷原厂 vbmeta.img vbmeta_system.img vbmeta_vendor.img   还原
echo.
echo     10秒后重启手机   不想重启可以断开手机   或者关闭脚本
echo.
echo     --------------------------------------------------------------------------------------------
timeout /t 10 
"%fastbootp%" reboot
call :log "手机已重启到卡槽:%activeSlot%  刷写流程结束"
exit /b 1

:error
pause
exit /b 1

:log
echo     %time% %~1 >> "%logFile%"
goto :eof