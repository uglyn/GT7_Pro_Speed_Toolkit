@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call :log "========== 禁用开机校验VB =========="
call "%modulesDir%header.bat" "%~nx0" "" "cls"

:select_file
echo.
echo 支持拖入 vbmeta.img (默认), vbmeta_system.img  ,vbmeta_vendor.img
call "%modulesDir%choose_file.bat" "imgFile" "vbmeta.img "
if errorlevel 1 (
    echo 选择文件失败，请重新尝试。
    goto select_file
)

:: 获取文件名（不含路径）
for %%f in ("%imgFile%") do set "fname=%%~nxf"

:: 校验文件名是否合法
set "valid=0"
if /i "%fname%"=="vbmeta.img" set "valid=1"
if /i "%fname%"=="vbmeta_system.img" set "valid=1"
if /i "%fname%"=="vbmeta_vendor.img" set "valid=1"

if %valid% equ 0 (
    echo 错误: 不支持的文件 "%fname%"
    echo 请确保文件名为 vbmeta.img、vbmeta_system.img 或 vbmeta_vendor.img
    echo 按任意键重新选择...
    pause >nul
    goto select_file
)

:: 根据文件名确定分区基础名
set "partition_base="
if /i "%fname%"=="vbmeta.img" set "partition_base=vbmeta"
if /i "%fname%"=="vbmeta_system.img" set "partition_base=vbmeta_system"
if /i "%fname%"=="vbmeta_vendor.img" set "partition_base=vbmeta_vendor"

call "%modulesDir%wait_fastboot_device.bat" fastboot

:: 刷写 _a 分区
echo %fastbootPath% --disable-verity --disable-verification flash %partition_base%_a %imgFile%
%fastbootPath% --disable-verity --disable-verification flash %partition_base%_a %imgFile%

:: 刷写 _b 分区
echo %fastbootPath% --disable-verity --disable-verification flash %partition_base%_b %imgFile%
%fastbootPath% --disable-verity --disable-verification flash %partition_base%_b %imgFile%

%fastbootPath% reboot
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof

:error_exit
exit /b 1