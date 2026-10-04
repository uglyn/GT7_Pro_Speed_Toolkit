@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%fastbootPath%" "cls"

:menu
echo ============================================
echo 请选择要刷写的 super 分区大小：
echo.
echo   1 - 14.5G   官方包  默认
echo.
echo   2 -  你的super分区会丢失所有数据 空包
echo ============================================
choice /c 1 /n /m  " 请输入数字 [1/2]: "
set "usersel=!errorlevel!"
set "imgFile="
if "!usersel!"=="1" set "imgFile=%imagesDir%super\super14.5_empty.img"
echo.
echo 即将刷写：%imgFile% 
echo.
echo 需要fastbootd 模式刷写 把 bootloader改成 fastboot
timeout /t 2
call :log "重启到bootloader"
call "%modulesDir%wait_fastboot_device.bat" bootloader

call :log "%fastboot% wipe-super %imgFile%"
echo %fastbootp% wipe-super %imgFile%
%fastbootp% flash super %imgFile%
if errorlevel 1 (
    echo 实在不行 工具箱首页执行 fastboot wipe-super %imgFile%
    echo 刷写失败，请检查设备连接或文件是否正确。
    pause
    exit /b 1
)

:end
cls
echo.
echo     ---------------------------------------------------------
echo.
echo      初始化 super分区  线束  现在为空 请补刷super 分区
echo.
echo     ---------------------------------------------------------
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof