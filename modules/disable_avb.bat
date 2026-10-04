@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

:select_file
echo.
echo 仅支持拖入 vbmeta.img 默认 vbmeta_system.img vbmeta_vendor.img
call "%modulesDir%choose_file.bat" "imgFile" "vbmeta.img" || exit /b 1

for %%f in ("%imgFile%") do set "partName=%%~nf"
for %%m in (vbmeta vbmeta_system vbmeta_vendor) do if /i "!partName!"=="%%m" goto start
    echo 仅支持 vbmeta.img vbmeta_system.img 或 vbmeta_vendor.img
    echo.
    echo 3秒返回
    timeout /t 2
    goto select_file
)
:start
call :log "重启到bootloader 可修改成fastboot"
call "%modulesDir%wait_fastboot_device.bat" bootloader

echo %fastbootp% --disable-verity --disable-verification flash  !partName!  "%imgFile%"
"%fastbootp%" --disable-verity --disable-verification flash "!partName!" "%imgFile%"
if errorlevel 1 (
    echo 刷写失败 请检查设备连接和镜像文件
    pause
    exit /b 1
)
echo.
echo 刷写成功 已经禁用%partName% 开机校验
echo.
echo 正在重启手机
echo.
%fastbootp% reboot
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof