@echo     off
setlocal enabledelayedexpansion
chcp 936 >nul
cd /d %~dp0
if exist "%~dp0toolbox_busy.lock" (
    echo.
    echo.
    echo     脚本正在工作中 或  脚本上次异常关闭
    echo.
    echo     请勿 多开脚本 容易引发异常
    echo.  
   del "%~dp0toolbox_busy.lock" 2>nul  
    timeout /t 10
)
set "pd0Dir=%~dp0"
set "apkDir=%~dp0apk\"
set "configDir=%~dp0config\"
set "gptDir=%~dp0gpt_both0\"
set "imagesDir=%~dp0images\"
set "logsDir=%~dp0logs\"
set "modulesDir=%~dp0modules\"
set "tempDir=%~dp0temp\"
set "toolsDir=%~dp0tools\"
set "readbackDir=%~dp0readback\"

mkdir "%~dp0logs" 2>nul
mkdir "%~dp0temp" 2>nul
mkdir "%~dp0readback" 2>nul

set "PATH=%toolsDir%;%PATH%"
for /d %%d in ("%toolsDir%*") do set "PATH=%%d;!PATH!"
set "adbp=adb"
set "fastbootp=fastboot"
set "payloadp=payload-dumper-go"
set "lpmakep=lpmake"


set "today=%date:/=%"
set "today=%today::=%"
set "today=%today:\=%"
set "today=%today: =%"
set "today=%today:	=%"
set "logFile=%logsDir%%today%.log"
echo     [%time%] 主脚本启动 >> "%logFile%"
  if not exist "%logFile%" (
    echo     无法生成日志文件.电脑日期格式脚本不认识
    pause
    exit /b 1
  )


:menu
cls
echo.
echo                   真我GT7 Pro 竞速版 玩机辅助工具 20261002   工作目录:%pd0Dir% 不要重复打开脚本
echo     --------------------------------------------------------------------------------------------------------------
echo     1.ROOT_TWRP:解锁BL之后 默认ksu         2.手动flash分区:img             3.修复fastbootD模式
echo.
echo     4.合成super:默认卡槽A                  5.查看super分区                 6.提取卡刷包:payload.bin
echo.
echo     7.纯FBD刷物理分区到闲置卡槽            8.刷写super:自动重建分区        9.刷super空包 [扩容后,其他情况禁用]
echo.
echo     0.[卡]线刷包:不救砖_降级必格式化手机   A.禁用开机VB校验[注意版本]      B.重启手机(手机需正确连接状态)
echo.
echo     C.一键回读AB包[类似卡刷包]             D.刷机到闲置卡槽:刷完会切换卡槽 E.手机分区读取[回读] 需adb和root权限
echo. 
echo     F.扩容super教程方法(极危险）           G.使用说明                      H.基础包+OTA增量包合并[只做测试用]
echo     --------------------------------------------------------------------------------------------------------------
echo     ADB 命令(可 ctrl+v 粘贴) 开机状态     Fastboot 命令(可 ctrl+c 复制) fastboot模式
echo     adb devices                           fastboot devices                     // 查看已连接设备
echo     adb reboot                            fastboot reboot                     // 重启设备
echo     adb reboot bootloader                 fastboot reboot bootloader         // 重启到 Bootloader 模式
echo     adb reboot fastboot                   fastboot reboot fastboot          // 重启到 Fastbootd 模式
echo     adb shell getprop ro.boot.slot_suffix fastboot getvar current-slot     // 查看当前槽位（_a 或 _b）
echo     [1]刷写 boot 分区（例子）             fastboot flash boot boot.img    //flash 分区名 .img文件
echo                                           fastboot set_active a或者b     //切换卡槽  
echo     [2]不知道为什么要换卡槽,禁止切换卡槽 否则黑砖 如果你在别的地方使用了adb/fb  重启一下电脑再用脚本
echo     --------------------------------------------------------------------------------------------------------------
adb devices 2>nul | findstr /i /e "device" >nul
if %errorlevel% equ 0 (
for /f "delims=" %%a in ('adb shell getprop ro.product.model') do set "model_name=%%a"
for /f "delims=" %%a in ('adb shell getprop ro.build.display.id') do set "dev_name=%%a"
for /f "delims=" %%a in ('adb shell getprop ro.boot.slot_suffix') do  set "slot_name=%%a"
for /f "delims=" %%a in ('adb shell uname -r') do set "u_name=%%a"
echo     设备名称:!model_name! 固件 :!dev_name! 卡槽:!slot_name!  
echo     内核:!u_name!
echo     --------------------------------------------------------------------------------------------------------------
)  
set "choice="
set /p choice=     请选择 [0-9 A-H]之后 回车[可直接写adb/fastboot/payloadgo/lpmake命令]:

for %%i in (0 1 2 3 4 5 6 7 8 9 A B C D E F G H) do (
    if /i "%choice%"=="%%i"  goto no
)
    choice /c x /n /t 1 /d x /m "输入已接收，正在继续..."
    echo     --------------------------------------------------------------------------------------------------------------
    echo     命令已执行
    %choice%
    ver >nul  
    goto cleanup
)
:no
::type nul > "%~dp0toolbox_busy.lock" 2>nul
if /i "%choice%"=="0" call "%modulesDir%flash_payload.bat"
if /i "%choice%"=="1" call "%modulesDir%root_twrp.bat"
if /i "%choice%"=="2" call "%modulesDir%manual_flash.bat"
if /i "%choice%"=="3" call "%modulesDir%fix_fastbootd.bat"
if /i "%choice%"=="4" call "%modulesDir%pack_super.bat"
if /i "%choice%"=="5" call "%modulesDir%showsuper.bat"
if /i "%choice%"=="6" call "%modulesDir%extract_payload.bat" 
if /i "%choice%"=="7" call "%modulesDir%flash_payload_partition.bat" 
if /i "%choice%"=="8" call "%modulesDir%flash_super.bat"
if /i "%choice%"=="9" call "%modulesDir%check_super.bat"
if /i "%choice%"=="A" call "%modulesDir%disable_avb.bat"
if /i "%choice%"=="B" call "%modulesDir%wait_fastboot_device.bat" reboot || exit /b 1
if /i "%choice%"=="C" call "%modulesDir%readback_ab.bat" 
if /i "%choice%"=="D" call "%modulesDir%flash_payload_inSlot.bat" 
if /i "%choice%"=="E" call "%modulesDir%readback.bat"
if /i "%choice%"=="F" start "" "%gptDir%"
if /i "%choice%"=="G" start "" "%pd0Dir%使用方法.txt"
if /i "%choice%"=="H" call "%modulesDir%patch_payload.bat"
:cleanup
if not  errorlevel 1 timeout /t 6 
del "%~dp0toolbox_busy.lock" 2>nul
goto :menu