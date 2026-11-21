@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0"  "" "cls"

set "excludeList=%tempDir%exclude_all.txt"
type nul > "%excludeList%" 2>nul
set "vbdisable=%configDir%vbdisable.txt"
set "specialList=%configDir%specialList.txt"
for %%F in ("%vbdisable%" "%specialList%") do (
    if not exist "%%~F" (
        echo([错误] 缺失配置文件: %%F
        call "%modulesDir%logger.bat" "%~nx0"  "缺失配置文件: %%F"
        goto exitb1
    )
)

call "%modulesDir%choose_source.bat" "imgDir" "imgList" "线刷包 或 卡刷包.img"  || exit /b 1
set "imgDir=!imgDir:"=!"
call "%modulesDir%logger.bat" "%~nx0"  "获取img来源"


call "%modulesDir%logger.bat" "%~nx0"  "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "获取设备卡槽"
call "%modulesDir%get_slot.bat"  || exit /b 1
set "inSlot=%activeSlot%"
cls
echo.
echo(               活动卡槽: %activeSlot%     闲置卡槽:%inActiveSlot% 刷机设备重启多次 莫慌
echo.
echo(               镜像目录: %imgDir%                选1 2都行 都是正常刷机   
echo(    --------------------------------------------------------------------------------------------
echo.
echo(    [1]单  刷  只刷活动卡槽:%activeSlot%    可以保留闲置卡槽物理分区
echo.
echo(    [2]AB通刷  同时刷写:%activeSlot% %inActiveSlot%两个卡槽    保证闲置卡槽物理有数据  
echo.
echo(    --------------------------------------------------------------------------------------------

choice /c 12 /n /m "请选择 [1/2]: "
set "mode=!errorlevel!"
echo.

call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "获取动态分区"
copy "%superParts%" "%excludeList%" >nul
type "%specialList%" >> "%excludeList%"

:start
call "%modulesDir%logger.bat" "%~nx0"  "第一阶段：刷写super动态分区" 
call "%modulesDir%flash_images.bat" "%imgDir%" "%superParts%" "" 1 || exit /b 1
cls
echo.
echo(    --------------------------------------------------------------------------------------------
echo(     第一阶段结束 [1/2]  共二阶段  设备重启多次 莫慌
echo.
echo(     [AB包 卡刷包] super逻辑分区 刷完
echo(    --------------------------------------------------------------------------------------------
echo(     第一阶段super分区 如果全部失败请停止刷机  ---- 部分失败可选择停止 或者 继续
echo.
timeout /t 15 

call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "等待设备进bootloader"

call "%modulesDir%flash_images.bat" "%imgDir%" "%specialList%" "" 3  || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "第二阶段：刷写特殊分区到卡槽:%activeSlot%"

if "%mode%"=="1" goto onlya1
if not "%inActiveSlot%"=="" if /i not "%inActiveSlot%"=="%activeSlot%" (
set "activeSlot=%inActiveSlot%"
call "%modulesDir%flash_images.bat" "%imgDir%" "%specialList%" "" 3  || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "第二阶段：刷写特殊分区到卡槽:%inActiveSlot%"
)

:onlya1
call "%modulesDir%logger.bat" "%~nx0"  "等待设备进fastboot"
call "%modulesDir%wait_fastboot_device.bat" "fastboot" || exit /b 1

set "activeSlot=%inSlot%"
call "%modulesDir%logger.bat" "%~nx0"  "第二阶段：刷写物理分区到 %activeSlot% 卡槽"
call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%excludeList%" 0  || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "禁用卡槽:%activeSlot% VB验证"
call "%modulesDir%flash_images.bat" "%imgDir%" "%vbdisable%" "" 2  || exit /b 1

if "%mode%"=="1" goto onlya2
if not "%inActiveSlot%"=="" if /i not "%inActiveSlot%"=="%activeSlot%" (
set "activeSlot=%inActiveSlot%"
call "%modulesDir%flash_images.bat" "%imgDir%" "%imgList%" "%excludeList%" 0  || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "第二阶段：刷写物理分区到%inActiveSlot%卡槽"
call "%modulesDir%flash_images.bat" "%imgDir%" "%vbdisable%" "" 2  || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "禁用卡槽:%inActiveSlot% VB验证"
)

:onlya2
%fastbootp% erase frp
set "activeSlot=%inSlot%"

cls
echo.
echo(    --------------------------------------------------------------------------------------------
echo(     第二阶段结束.[2/2]  共二阶段 
echo.
echo(     刷机结束！当前槽位:%activeSlot%   
echo.
echo(     已经禁用 vbmeta vbmeta_system vbmeta_vendor 开机VB校验
exit /b 11

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

