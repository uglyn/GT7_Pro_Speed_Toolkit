@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%fastbootPath%" "cls"
call :log "========== 初始化super 启动 =========="

:menu
echo ============================================
echo 请选择要刷写的 super 分区大小：你的super分区会丢失所有数据 空包
echo.
echo   1 - 15GB（对应 super_empty_15gb.img）官方大小(非官方包)  默认
echo.
echo   2 - 25GB（对应 super_empty_25gb.img）扩容25GB以上之后(空包)
echo ============================================
choice /c 12 /n /m  " 请输入数字 [1/2]: "
set "usersel=!errorlevel!"
set "imgFile="
if "!usersel!"=="1" set "imgFile=%imagesDir%super\super_empty_15gb.img"
if "!usersel!"=="2" set "imgFile=%imagesDir%super\super_empty_25gb.img"
echo.
echo 即将刷写：%imgFile% 
echo.
echo 需要fastbootd 模式刷写 把 bootloader改成 fastboot
timeout /t 5
pause
call :log "重启到bootloader"
call "%modulesDir%wait_fastboot_device.bat" bootloader

call :log "%fastboot% flash super %imgFile%"
echo %fastbootp% flash super %imgFile%
%fastbootp% flash super %imgFile%

if errorlevel 1 (
    echo 刷写失败，请检查设备连接或文件是否正确。
    pause
    exit /b 1
)

:end
cls
echo.
echo     ---------------------------------------------------------
echo.
echo      刷写线束  super分区   现在为空 请补刷super 分区
echo.
echo     ---------------------------------------------------------
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof