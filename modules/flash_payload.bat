@echo off
setlocal enabledelayedexpansion

set "specialList=%configDir%special.txt"
set "excludeList=%tempDir%exclude_all.txt"

call :log "========== 线刷卡刷包启动 =========="
call "%modulesDir%header.bat" "%~nx0"  "" "cls"

call :log "获取img来源%imgDir%"
call "%modulesDir%choose_source.bat" "imgDir" "imgList" "线刷包或者卡刷包.img"  || exit /b 1

call :log "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

call :log "获取设备卡槽"
call "%modulesDir%get_slot.bat" || exit /b 1

call :log "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" || exit /b 1

copy "%superParts%" "%excludeList%" >nul
type "%specialList%" >> "%excludeList%"


echo --------------------------------------------------------------------------------------------
echo 活动卡槽: %activeSlot%
echo 闲置卡槽:%inActiveSlot%
echo 镜像目录: %imgDir%
echo --------------------------------------------------------------------------------------------
echo [1]单刷 只刷卡槽:%activeSlot%  优点 保留闲置卡槽:%inActiveSlot%原有数据 
echo [2]通刷 同时刷写:%activeSlot%和%inActiveSlot%卡槽  不包含super分区
echo.
echo AB通刷可防止%inActiveSlot%卡槽:为空 切换后黑砖 只要不是风险包 选 2 好一点。
echo --------------------------------------------------------------------------------------------

choice /c 12 /n /m "请选择 [1/2]: "
set "mode=%errorlevel%"

if "%mode%"=="1" goto onlya1

if not "%inActiveSlot%"=="" if /i not "%inActiveSlot%"=="%ActiveSlot%" (
    set "activeSlot=%inActiveSlot%"
    echo 开始刷写卡槽: %inActiveSlot%
    call :log "第一阶段：刷写物理分区到 %inActiveSlot% 卡槽"
    call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%excludeList%" 0  || exit /b 1
)
:onlya1
set "activeSlot=%inSlot%"
echo 开始刷写卡槽: %ActiveSlot%
call :log "第一阶段：刷写物理分区到%ActiveSlot%卡槽"
call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%excludeList%" 0  || exit /b 1
echo --------------------------------------------------------------------------------------------
echo                                   第一阶段结束.[1/3]   共三阶段
echo.
echo                        已经将[AB包 卡刷包] super以外的分区 刷完     需要按一个按键继续
echo --------------------------------------------------------------------------------------------
pause
call :log "第二阶段：刷写super动态分区"
call "%modulesDir%flash_images.bat" "%imgDir%" "%superParts%" "" 1 || exit /b 1
echo --------------------------------------------------------------------------------------------
echo                              第二阶段结束.[2/3]   共三阶段
echo.
echo                                AB包[卡刷包super分区]
echo --------------------------------------------------------------------------------------------


call :log "等待设备进bootloader"
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

call :log "第三阶段：刷写特殊分区"
echo 开始刷写卡槽: %ActiveSlot%
call :log "第三阶段：刷写特殊分区到卡槽:%ActiveSlot%"
call "%modulesDir%flash_images.bat" "%imgDir%" "%specialList%" "" 0  || exit /b 1

if "%mode%"=="1" goto end
if not "%inActiveSlot%"=="" if /i not "%inActiveSlot%"=="%ActiveSlot%" (
    set "activeSlot=%inActiveSlot%"
    echo 开始刷写卡槽: %ActiveSlot%
    call :log "第三阶段：刷写特殊分区到卡槽:%inActiveSlot%"
    call "%modulesDir%flash_images.bat" "%imgDir%" "%specialList%" "" 0  || exit /b 1
)

:end
echo 刷机结束！当前槽位:%ActiveSlot%
%fastbootPath% reboot
call :log "手机已重启到卡槽:%ActiveSlot%,刷写流程结束"
exit /b 0
:log
echo %time% %~1 >> "%logFile%"
goto :eof
:error_exit
exit /b 1
