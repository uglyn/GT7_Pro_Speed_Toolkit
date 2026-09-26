@echo off
chcp 936 >nul
setlocal enabledelayedexpansion

set "partList="
set "missingList="
set "hasMissing=0"
set "SUPER_SIZE=15569256448"
set "configFile=%configDir%super.txt"
set "superImg=%pd0Dir%super.img"
set "partInfoFile=%tempDir%part_sizes_%RANDOM%.tmp"
type nul > "%partInfoFile%" 2>nul || goto error_exit
call "%modulesDir%header.bat" "%~nx0" "%lpmakePath%"  "cls"
call :log "========== 打包 super.img 启动 =========="

if exist "!superImg!" (
    echo 检测到已存在 super.img，跳过打包。
    call :log "检测到已存在 super.img，跳过打包"
    goto ask_flash
)

call "%modulesDir%choose_source.bat" "imgDir" "imglist" "卡刷包.img" || exit /b 1
call :log "卡刷包img目录: %imgDir%"

for /f "usebackq delims=" %%a in ("%configFile%") do (
    if not "%%a"=="" set "partList=!partList! %%a"
)
echo -----------------------------------------------------------------------------
call :log "需要打包的分区列表: %partList%"

set "lpmakeCmd="%lpmakePath%" --device-size %SUPER_SIZE% --metadata-size 65536 --metadata-slots 2 --super-name super --group qti_dynamic_partitions:%SUPER_SIZE% --sparse"

for %%p in (%partList%) do (

    set "fileExists=0"
    set "imgFile=%imgDir%\%%p.img"   
    if exist "!imgFile!" set "fileExists=1"
    
    if !fileExists!==1 (
        :: 文件存在，处理大小和命令
        for %%a in ("!imgFile!") do set "imgSize=%%~za"
        if "!imgSize!"=="" set "imgSize=0"
        set "size_a=!imgSize!"
        set "size_b=0"
        echo %%p_a !size_a! >> "%partInfoFile%"
        echo %%p_b !size_b! >> "%partInfoFile%"
        set "lpmakeCmd=!lpmakeCmd! --partition %%p_a:readonly:!size_a!:qti_dynamic_partitions"
        set "lpmakeCmd=!lpmakeCmd! --partition %%p_b:readonly:!size_b!:qti_dynamic_partitions"
        set "lpmakeCmd=!lpmakeCmd! --image=%%p_a=!imgFile!"
    ) else (
        set "hasMissing=1"
        set "missingList=!missingList! %%p.img"
    )
)

if !hasMissing!==1 (
    echo -----------------------------------------------------------------------------
    echo 错误：以下分区镜像文件不存在：
    echo !missingList!
    echo.
    echo 请将对应的 .img 文件放入以下目录:
    echo   主目录: %imgDir%
    echo -----------------------------------------------------------------------------
    call :log "缺失镜像文件: !missingList!"
    del "%partInfoFile%" 2>nul
    goto error_exit
)
set "lpmakeCmd=!lpmakeCmd! --output %superImg%"
echo super各分区列表及大小：
type "%partInfoFile%"
del "%partInfoFile%" 2>nul
echo.
echo super.img 总大小为 %SUPER_SIZE% 字节 %pd0Dir% 至少保留 15GB 以上
echo -----------------------------------------------------------------------------
set /p confirm=确认开始打包？输入 n 取消，任意键继续: 
if /i "%confirm%"=="n" (
    echo 用户取消
    call :log "用户取消"
    goto error_exit
)

echo 执行命令:
echo !lpmakeCmd!
call :log "执行打包命令"
cmd /c "!lpmakeCmd!"
if errorlevel 1 (
    echo 打包失败！
    call :log "打包失败"
    goto error_exit
) 
echo -----------------------------------------------------------------------------
echo 打包成功！生成 %pd0Dir%super.img
call :log "打包成功，输出 %pd0Dir%super.img"

:ask_flash
echo.
set /p flashConfirm=是否立即刷入 super.img 到设备？(y/n): 
if /i not "%flashConfirm%"=="y" (
    echo 跳过刷写。
    goto error_exit
)
call :log "用户选择刷入 super.img"
echo 正在进入 bootloader 模式...
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1
call "%modulesDir%get_slot.bat" || exit /b 1
if /i not "%activeSlot%"=="a" (
    echo 错误：只允许活动卡槽为 %activeSlot% 。
    echo 请不要手动切换到卡槽a刷入。当活动卡槽为b 你的卡槽a可能没有对应的系统。
    call :log "当前卡槽 %activeSlot%，不是 a，拒绝刷写"
    goto error_exit
)
%fastbootPath% flash super "%pd0Dir%super.img"
echo 正在重启...
%fastbootPath% reboot
exit /b 0

:error_exit

echo 操作失败，按任意键退出...
exit /b 1

:log
echo %time% %~1 >> "%logFile%"
goto :eof