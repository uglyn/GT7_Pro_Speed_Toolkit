@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%fastbootPath%" "cls"
call :log "========== 初始化super 启动 =========="

:menu
echo ============================================
echo 请选择要刷写的 super 分区大小：你的super分区会丢失所有数据
echo.
echo   1 - 15GB（对应 super_empty_15gb.img）官方(空包)
echo.
echo   2 - 25GB（对应 super_empty_25gb.img）扩容25GB以上之后(空包)

echo ============================================
set /p "choice=请输入数字 1 或 2 后按回车: "

set "imgFile="
if "%choice%"=="1" set "imgFile=%imagesDir%super\super_empty_15gb.img"
if "%choice%"=="2" set "imgFile=%imagesDir%super\super_empty_25gb.img"
if not defined imgFile goto menu
if not exist "%imgFile%" goto menu

echo 即将刷写：%imgFile%
call "%modulesDir%wait_fastboot_device.bat" bootloader
timeout /t 5
echo %fastbootPath% flash super %imgFile%
%fastbootPath% flash super %imgFile%

if errorlevel 1 (
    echo 刷写失败，请检查设备连接或文件是否正确。
    exit /b 1
)

echo 刷写完成，使用文件：%imgFile%
exit /b 0
:log
echo %time% %~1 >> "%logFile%"
goto :eof