@echo off
chcp 936 >nul
title 交互式刷机工具箱
color 0A

:menu
cls
echo =============================================
echo         欢迎使用交互式工具箱 v1.0
echo =============================================
echo.
echo  1. 重启到 Bootloader (fastboot模式)
echo  2. 重启到 fastbootd (用户空间fastboot)
echo  3. 查看当前活动卡槽 (A/B)(fastboot状态)
echo  4. 切换卡槽到 _a(fastboot状态)
echo  5. 切换卡槽到 _b(fastboot状态)
echo  8. 重启手机(fastboot状态)
echo  9. 自定义命令 (手动输入任意命令)
echo  0. 退出脚本
echo.
echo =============================================
set /p choice=请输入数字 [0-9]: 

REM 判断用户输入并跳转
if "%choice%"=="1" goto cmd_reboot_bootloader
if "%choice%"=="2" goto cmd_reboot_fastbootd
if "%choice%"=="3" goto cmd_getvar_slot
if "%choice%"=="4" goto cmd_set_active_a
if "%choice%"=="5" goto cmd_set_active_b
if "%choice%"=="8" goto cmd_reboot
if "%choice%"=="9" goto custom_cmd
if "%choice%"=="0" goto exit_script

echo 无效输入，请重新选择！
goto menu

REM ==========================================
REM 功能模块
REM ==========================================

:cmd_reboot_bootloader
echo 正在重启到 Bootloader...
%fastbootPath% reboot bootloader
timeout /t 3
goto end

:cmd_reboot_fastbootd
echo 正在重启到 fastbootd...
%fastbootPath% reboot fastboot
timeout /t 3
goto end

:cmd_getvar_slot
echo 当前活动卡槽：
%fastbootPath% getvar current-slot
timeout /t 3
goto end

:cmd_set_active_a
echo 正在切换到卡槽 A...
%fastbootPath% set_active a
timeout /t 3
goto end

:cmd_set_active_b
echo 正在切换到卡槽 B...
%fastbootPath% set_active b
timeout /t 3
goto end



:cmd_reboot
echo 正在重启手机...
%fastbootPath% reboot
timeout /t 3
goto end

REM ==========================================
REM ★★★ 核心功能：选项 9 自定义命令 ★★★
REM ==========================================
:custom_cmd
cls
echo =============================================
echo          进入自定义命令模式
echo  你可以输入任何 %fastbootPath% / ADB / CMD 命令
echo  输入 "exit" 或 "back" 返回主菜单
echo =============================================
echo.

:custom_loop
set /p user_cmd=请输入命令: 

if /i "%user_cmd%"=="exit" goto menu
if /i "%user_cmd%"=="back" goto menu
if "%user_cmd%"=="" goto custom_loop

echo.
echo 正在执行: %user_cmd%
echo ---------------------------------------------
%user_cmd%
echo ---------------------------------------------
echo 命令执行完毕。
echo.
goto custom_loop

REM ==========================================
REM 退出与结束
REM ==========================================
:end
echo.
echo 操作执行完毕。
goto menu

:exit_script
echo 退出工具箱。
exit /b