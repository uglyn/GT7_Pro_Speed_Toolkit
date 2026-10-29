@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
cd /d "%~dp0"
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

if exist "%pd0Dir%toolbox_busy.lock" (
    echo.
    echo     ---------------------------请不要重复打开脚本-------------------------------
    echo              *****请手动删除: %pd0Dir%toolbox_busy.lock ********* 状态锁
    echo     ---------------------------或上次异常关闭脚本-------------------------------
    echo.
    echo      5秒后退出脚本
    echo.
    timeout /t 5
    exit /b 1
    
)
mkdir "%pd0Dir%logs" 2>nul
mkdir "%pd0Dir%readback" 2>nul
mkdir "%pd0Dir%temp" 2>nul

for /d %%d in ("%toolsDir%*") do set "PATH=%%d;!PATH!"
set "adbp=adb"
set "ksudp=ksud"
set "fastbootp=fastboot"
set "lpmakep=lpmake"
set "payloadp=payload-dumper-go"

set "today=%date:/=%"
set "today=%today::=%"
set "today=%today:\=%"
set "today=%today: =%"
set "today=%today:	=%"
set "logFile=%logsDir%%today%.log"
call "%modulesDir%logger.bat" "%~nx0" "脚本启动"
if not exist "%logFile%" (
    echo(     无法生成日志文件. 暂停使用
    pause
    exit /b 1
  )
:menu
cls
echo.
echo         GT7Pro 竞速版工具箱  ******关闭其他刷机工具后使用****  20261029   工作目录:%pd0Dir%  
echo     --------------------------------------------------------------------------------------------------------------
echo     1.ROOT_TWRP:解锁BL之后 默认ksu         2.手动flash分区:img             3.修复fastbootD模式
echo.
echo     4.合成super:默认卡槽A                  5.查看super分区                 6.[卡刷包.zip]解压提取分区
echo.
echo     7.纯FBD刷物理分区到闲置卡槽            8.刷写super:自动重建分区        9.初始化super
echo.
echo     0.[卡]线刷包:刷机_降级必格式化手机     A.禁用开机VB校验[注意版本]      B.重启手机(手机需正确连接状态)
echo.
echo     C.一键回读AB包[类似卡刷包]             D.刷机到闲置卡槽:会切换卡槽     E.手机分区读取[回读] 需adb和root权限
echo. 
echo     F.扩容super教程方法(极危险）           G.使用说明                      H.基础包+OTA增量包合并 成 全量包
echo     --------------------------------------------------------------------------------------------------------------
echo     ADB 命令(可 ctrl+v 粘贴) 开机状态     Fastboot 命令(可 ctrl+c 复制) fastboot模式
echo     adb devices                           fastboot devices                     // 查看已连接设备
echo     adb reboot                            fastboot reboot                     // 重启设备
echo     adb reboot bootloader                 fastboot reboot bootloader         // 重启到 Bootloader 模式
echo     adb reboot fastboot                   fastboot reboot fastboot          // 重启到 Fastbootd 模式
echo     adb shell getprop ro.boot.slot_suffix fastboot getvar current-slot     // 查看当前槽位（_a 或 _b）
echo     [1]刷写 boot 分区（例子）             fastboot flash boot boot.img    //flash 分区名 .img文件
echo                                           fastboot set_active a或者b     //切换卡槽  
echo     [2]不知道为什么要换卡槽,禁止切换卡槽 否则黑砖   [3]fastboot 乱码请重启电脑和手机 原因是软件冲突
echo     --------------------------------------------------------------------------------------------------------------

%adbp% devices 2>nul | findstr /i "device$" >nul
if not errorlevel 1 (
    for /f "delims=" %%a in ('%adbp% shell getprop ro.product.model 2^>nul') do set "model_name=%%a"
    for /f "delims=" %%a in ('%adbp% shell getprop ro.build.display.id 2^>nul') do set "dev_name=%%a"
    for /f "delims=" %%a in ('%adbp% shell getprop ro.boot.slot_suffix 2^>nul') do set "slot_name=%%a"
    for /f "delims=" %%a in ('%adbp% shell uname -r 2^>nul') do set "u_name=%%a"
    
    echo     设备名称:!model_name! 固件 :!dev_name! 卡槽:!slot_name!  
    echo     内核:!u_name!
    echo     --------------------------------------------------------------------------------------------------------------
) 

set "choice=qq11066851"
set /p choice=请输入[0-9 A-J]后 按回车键 [可直接写 粘贴:adb/fastboot/payloadgo/lpmake命令]:
echo ------------------------------------------------------------------------------------------------------------------
set "choice=%choice:"=%"
call "%modulesDir%logger.bat" "%~nx0" "正在执行命令:!choice!"
rem 输入审查
:trim_space
ver>nul
if "%choice%"=="" goto cleanup
:: 2. 剥洋葱：只要第一个字符是空格，就砍掉，继续循环
if "!choice:~0,1!"==" " (
    set "choice=!choice:~1!"
    goto :trim_space
)
for %%i in (0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J) do (
    if /i "!choice!"=="%%i"  goto %%i
)
call "%modulesDir%check_device.bat" "!choice!"  & goto cleanup
rem 进入战斗
:0
call "%modulesDir%flash_payload.bat" & goto cleanup
:1
call "%modulesDir%root_twrp.bat" & goto cleanup
:2
call "%modulesDir%manual_flash.bat" & goto cleanup
:3
call "%modulesDir%fix_fastbootd.bat" & goto cleanup
:4
call "%modulesDir%pack_super.bat" & goto cleanup
:5
call "%modulesDir%showsuper.bat" & goto cleanup
:6
call "%modulesDir%extract_payload.bat"  & goto cleanup
:7
call "%modulesDir%flash_payload_partition.bat"  & goto cleanup
:8
call "%modulesDir%flash_super.bat" & goto cleanup
:9
call "%modulesDir%check_super.bat" & goto cleanup
:A
call "%modulesDir%disable_avb.bat" & goto cleanup
:B
call "%modulesDir%wait_fastboot_device.bat" "reboot" & goto cleanup
:C
call "%modulesDir%readback_ab.bat"  & goto cleanup
:D
call "%modulesDir%flash_payload_inSlot.bat" & goto cleanup 
:E
call "%modulesDir%readback.bat" & goto cleanup
:F
start "" "%gptDir%" & goto cleanup
:G
start "" "%pd0Dir%使用方法.txt" & goto cleanup
:H
call "%modulesDir%patch_payload.bat" & goto cleanup
:I
call "%modulesDir%pack_super_25empty.bat" & goto cleanup
:J
call "%modulesDir%test.bat" & goto cleanup

rem 打扫战场
:cleanup
echo.
set "rc=%ERRORLEVEL%"
del "%pd0Dir%toolbox_busy.lock" 2>nul
del /f /q "%tempDir%*" >nul 2>&1
if %rc% EQU 11 (
         echo.
         echo(     不需要重启手机 可关闭脚本 或 断开手机 
         echo.
         echo(     10秒后重启手机
         echo(     --------------------------------------------------------------------------------------------
         timeout /t 10 
         call "%modulesDir%wait_fastboot_device.bat" "reboot" & goto cleanup
)
if %rc% EQU 1  pause
if %rc% EQU 0 choice /c 0 /n /t 2 /d 0 /m  "2秒后继续. 按0直接继续.. 丢失焦点会卡住.. 卡住请手动按 0 " 
goto :menu