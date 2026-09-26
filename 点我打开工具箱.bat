@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
cd /d %~dp0
if exist "%~dp0toolbox_busy.lock" (
    echo.
    echo 重复打开脚本，或者上次异常退出！
    echo.
    echo 删除%~dp0toolbox_busy.lock后，重新打开。
    timeout /t 6
    exit /b 1
)
set "pd0Dir=%~dp0"
set "imagesDir=%~dp0images\"
set "toolsDir=%~dp0tools\"
set "logsDir=%~dp0logs\"
set "tempDir=%~dp0temp\"
set "configDir=%~dp0config\"
set "modulesDir=%~dp0modules\"
set "gptDir=%~dp0gpt_both0\"
set "apkDir=%~dp0apk\"

mkdir "%~dp0logs" 2>nul
mkdir "%~dp0readback" 2>nul
set "PATH=%toolsDir%;%PATH%"
for /d %%d in ("%toolsDir%*") do set "PATH=%%d;!PATH!"
set "adbPath=adb"
set "fastbootPath=fastboot"
set "payload-dumper-goPath=payload-dumper-go"
set "lpmakePath=lpmake"


set "today=%date:/=%"
set "logFile=%logsDir%%today%.log"

echo [%time%] 主脚本启动 >> "%logFile%"

:: ---------- 驱动预检测（结果存入变量 driverStatus） ----------
pnputil /enum-drivers 2>nul | findstr /i "android_winusb" >nul
if errorlevel 1 (
    set "driverStatus=未知或者未安装"
) else (
    set "driverStatus=已安装"
)

:menu
cls
rd /s /q  "%tempDir%" 2>nul
mkdir "%~dp0temp" 2>nul
echo.
echo                       真我GT7 Pro 竞速版 玩机辅助工具 202600924
echo ============================================================================================================
echo 1.ROOT_TWRP:解锁BL之后 默认ksu         2.手动flash分区:img             3.修复fastbootD模式
echo.
echo 4.合成super.img:卡槽A                  5.一些常用 FB 命令              6.解压卡刷包:payload.bin                         
echo.
echo 7.FASTBOOT驱动:[%driverStatus%]                8.刷写super:自动重建分区        9.刷super空包(super扩容后,其他情况禁用)
echo.
echo 0.[卡]线刷包:不救砖_降级必格式化手机   A.禁用开机VB校验[注意版本]      B.重启手机(手机需正确连接状态) 
echo.
echo C.扩容super教程方法(极危险）           D.手机分区读取[回读] 需要adb和root权限     
echo.
echo E.一键回读AB包[类似卡刷包]             F.开发中:开发中                 G.开发中:开发中      
echo ----------------------------------------------------------------------------------------------------------------------
echo ADB 命令(可 ctrl+ v 粘贴)                           Fastboot 命令(可 ctrl+c 复制)
echo adb devices                           fastboot devices                     // 查看已连接设备
echo adb reboot                            fastboot reboot                     // 重启设备
echo adb reboot bootloader                 fastboot reboot bootloader         // 重启到 Bootloader 模式
echo adb reboot fastboot                   fastboot reboot fastboot          // 重启到 Fastbootd 模式
echo adb shell getprop ro.boot.slot_suffix fastboot getvar current-slot     // 查看当前槽位（_a 或 _b）(可复制_首页查卡槽)
echo [1]刷写 boot 分区（例子）             fastboot flash boot boot.img    //flash 分区名 .img文件
echo                                       fastboot set_active a或者b     //切换卡槽  
echo [2]不知道为什么要换卡槽,禁止切换卡槽 否则黑砖 
echo ----------------------------------------------------------------------------------------------------------------------
echo 工作目录:%pd0Dir%
echo 使用工具 : adb fastboot payload-go lqmake 
echo ----------------------------------------------------------------------------------------------------------------------
set "choice="
set /p choice=请选择 [0-9 A-D]之后 回车[可直接写adb/fastboot/payloadgo/lpmake命令]:
choice /c x /n /t 1 /d x /m "输入已接收，正在继续..."
for %%i in (0 1 2 3 4 5 6 7 8 9 A B C D E F G) do (
    if /i "%choice%"=="%%i"  goto no
)
    echo ----------------------------------------------------------------------------------------------------------------------
    %choice%  
    echo 命令已执行
    goto cleanup
)
:no
::type nul > "%~dp0toolbox_busy.lock" 2>nul
if /i "%choice%"=="0" call "%modulesDir%flash_payload.bat"
if /i "%choice%"=="1" call "%modulesDir%root_twrp.bat"
if /i "%choice%"=="2" call "%modulesDir%manual_flash.bat"
if /i "%choice%"=="3" call "%modulesDir%fix_fastbootd.bat"
if /i "%choice%"=="4" call "%modulesDir%pack_super.bat"
if /i "%choice%"=="5" call "%modulesDir%interactive_tool.bat"
if /i "%choice%"=="6" call "%modulesDir%extract_payload.bat" 
if /i "%choice%"=="7" call "%modulesDir%drivers.bat" 
if /i "%choice%"=="8" call "%modulesDir%flash_super.bat"
if /i "%choice%"=="9" call "%modulesDir%check_super.bat"
if /i "%choice%"=="A" call "%modulesDir%disable_avb.bat"
if /i "%choice%"=="B" call "%modulesDir%wait_fastboot_device.bat" reboot || exit /b 1
if /i "%choice%"=="C" start "" "%gptDir%"
if /i "%choice%"=="D" call "%modulesDir%readback.bat"
if /i "%choice%"=="E" call "%modulesDir%readback_ab.bat"

:cleanup
if errorlevel 1 pause
del "%~dp0toolbox_busy.lock" 2>nul
timeout /t 5
goto :menu