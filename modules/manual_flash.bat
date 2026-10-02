@echo      off
chcp 936 >nul
setlocal enabledelayedexpansion
call :log "========== 手动刷写分区启动 ========"


call "%modulesDir%header.bat" "%~nx0" "%fastbootp%" "cls"  

call :log "选择文件"
call "%modulesDir%choose_file.bat" "imgFile" ".img" || exit /b 1

cls
echo.
echo.
echo.
for %%f in ("%imgFile%") do set "baseName=%%~nf"
echo      -------------------------------------------------------------------------------------------
echo      [0]当前选择的文件：%baseName% 刷写模式fastbootD  recovery不要在这里刷
echo.
echo      [1]请输入要刷入的分区:（如 boot、 init_boot、system 等）
echo.
echo      [2]twrp(recovery.img) 不同手机可能刷入的分区不同
echo.
echo      [3]注：想指定卡槽请加 _a/_b 后缀（如 boot_a、 init_boot_a、system_a等）
echo      -------------------------------------------------------------------------------------------
echo       recovery 不能用这个功能 刷
:ask_part
echo.
echo 直接回车 将刷入%baseName% 分区:
set /p "userPart=请输入要刷入的分区:" 
if "%userPart%"==""  set "userPart=%baseName%"
if /i not "%userPart%"=="%baseName%" (
echo.
echo.
echo     ---------------  -----------------------安全警告-------------------------------------------
echo      [0]刷入的文件：%baseName%.img 
echo.
echo      [1]你输入的分区：%userPart% 刷错分区很危险
echo.
echo      [2] 文件名 和 分区名 不一致 需要 手工确认
echo      ================================
echo.
echo      输入 YES（全部大写）继续,其他输入取消
    set /p "confirm=.    |:"
    if /i not "!confirm!"=="YES" (
        echo      操作已取消。
        call :log "用户取消刷写"
        exit /b 0
    )
)

call :log "重启到fastboot 可修改成 bootloader"
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

echo %fastbootp% flash %userPart% "%imgFile%"
%fastbootp% flash %userPart% "%imgFile%"

if errorlevel 1 (
    call :log "刷写失败：%userPart%"
    echo 刷写失败
    exit /b 0
)
call :log "刷写成功：%userPart%"
echo.
echo     刷写成功
echo.
exit /b 0

:log
echo      %time% %~1>> "%logFile%"
goto :eof