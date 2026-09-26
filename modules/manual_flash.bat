@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%fastbootPath%" "cls"  
call :log "========== 手动刷写分区启动 ========"
call "%modulesDir%choose_file.bat" "imgFile" ".img" || exit /b 1
for %%f in ("%imgFile%") do set "baseName=%%~nf"
echo -------------------------------------------------------------------------------------------
echo 当前选择的文件：%imgFile%
echo.
echo 请输入要刷入的分区:（如 boot、recovery、init_boot、system 等）
echo.
echo twrp(recovery.img) 不同手机可能刷入的分区不同
echo 注：想指定卡槽请加 _a/_b 后缀（如 boot_a、recovery_b、init_boot_a、system_a等）
echo -------------------------------------------------------------------------------------------
:ask_part

set /p "userPart=直接回车 将刷入%baseName% 分区: " 
if "%userPart%"==""  set "userPart=%baseName%"
if /i not "%userPart%"=="%baseName%" (
    cls
    echo ========== 安全警告 ==========
    echo 文件名称：%baseName%.img
    echo 您输入的分区名：%userPart%
    echo.
    echo  需要手工确认  boot.img 只能刷如boot分区 
    echo ================================
    set /p "confirm=输入 YES（大写）以继续，其他任意键取消: "
    if /i not "!confirm!"=="YES" (
        echo 操作已取消。
        call :log "用户取消刷写"
        exit /b 0
    )
)
call "%modulesDir%wait_fastboot_device.bat" fastboot || exit /b 1

:: ---------- 执行刷写 ----------
echo 正在刷写 %userPart% 分区，镜像：%imgFile%
%fastbootPath% flash %userPart% "%imgFile%"
if errorlevel 1 (
    call :log "刷写失败：%userPart%"
    echo 刷写失败！
    exit /b 0
)

:: ---------- 成功返回 ----------
call :log "刷写成功：%userPart%"
echo 刷写完成。
:end
echo [%today% %time%] 返回主脚本 >> "%logFile%"
exit /b 0

:log
echo %time% %~1>> "%logFile%"
goto :eof