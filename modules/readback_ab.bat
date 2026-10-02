@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call :log "========== 一键回读开始 =========="

call "%modulesDir%header.bat" "%~nx0" "" "cls"

set "partTxt=%configDir%ab_partitions.txt"
if not exist "%partTxt%" (
    echo [错误] 找不到分区配置文件: %partTxt%
    call :log "[错误] 找不到配置文件: %partTxt%"
    pause
    exit /b 1
)

set "readbackOut=%readbackDir%%today%_%random%\"
if not exist "!readbackOut!" mkdir "!readbackOut!"

set "okCount=0"
set "failCount=0"
set "skipCount=0"
set "totalCount=0"
set "curCount=0"

call :log "遍历获取总数"
for /f "usebackq delims=" %%P in ("%partTxt%") do (
    set "base=%%P"
    set "base=!base: =!"
    set "base=!base:	=!"
    if not "!base!"=="" set /a totalCount+=1
)

call :log "配置文件共发现 !totalCount! 个分区"
echo 配置文件共发现 !totalCount! 个分区待回读。

call :log "等待设备连接到 adb"
call "%modulesDir%wait_fastboot_device.bat" "adb"

%adbp% shell "su -c ""id""" 2>nul | findstr "uid=0" >nul
if errorlevel 1 (
    echo [错误] 未获取 Root 权限，请授权 shell ROOT 权限。
    call :log "[错误] 未获取 Root 权限"
    pause
    exit /b 1
)
echo [OK] 已获取 Root 权限。
call :log "[OK] 已获取 Root 权限"

set "devList=%tempDir%dev_blocks.txt"
type nul>"!devList!"
%adbp% shell "su -c ""ls /dev/block/by-name/""" > "%devList%" 2>nul

call :log "获取卡槽"
call "%modulesDir%get_slot.bat" "adb" || exit /b 1

cls
echo.
echo 当前卡槽 : !activeSlot!
call :log "当前卡槽: !activeSlot!"
echo.
echo 开始回读...

set "remoteImg=/data/local/tmp/readback_tmp.img"

for /f "usebackq delims=" %%P in ("%partTxt%") do (

    set "base=%%P"
    set "base=!base: =!"
    set "base=!base:	=!"
    echo.
    if not "!base!"=="" (
        set /a curCount+=1
        echo [!curCount!/!totalCount!] 正在处理: !base!
        call :log "[!curCount!/!totalCount!] 处理: !base!"

        set "target="

        call :log "优先找当前卡槽的分区，例如 boot_a"
        findstr /x /c:"!base!_!activeSlot!" "!devList!" >nul
        if not errorlevel 1 set "target=!base!_!activeSlot!"

        call :log "找不到再回退到不带后缀的共享分区，例如 modem"
        if not defined target (
            findstr /x /c:"!base!" "!devList!" >nul
            if not errorlevel 1 set "target=!base!"
        )

        if not defined target (
            echo [失败] 设备上没有 !base!_!activeSlot! 或 !base!
            call :log "[失败] !base! 不存在"
            set /a skipCount+=1
            goto :build_failed
        )

        call :log "生成标准卡刷包文件名"
        set "saveFile=%readbackOut%!base!.img"

        echo [回读] !target! -^> !saveFile!
        call :log "[回读] !target! -> !saveFile!"

        call :log "获取分区真实物理大小"
        set "targetSize=0"
        for /f "delims=" %%S in ('!adbp! shell "su -c ""blockdev --getsize64 /dev/block/by-name/!target!""" 2^>nul') do set "targetSize=%%S"
        set "targetSize=!targetSize: =!"
        set "targetSize=!targetSize:	=!"

        if "!targetSize!"=="0" (
            echo [失败] 无法获取分区真实大小
            call :log "[失败] !target! 无法获取真实大小"
            set /a failCount+=1
            goto :build_failed
        )

        !adbp! shell "su -c ""dd if=/dev/block/by-name/!target! of=!remoteImg! bs=4096""" 

        echo 传输中，手机端真实大小: !targetSize! 字节
        !adbp! pull !remoteImg! !saveFile!

        set "localSize=0"
        if exist "!saveFile!" (
            for %%F in ("!saveFile!") do set "localSize=%%~zF"
        )

        if "!localSize!" neq "!targetSize!" (
            echo   [失败] 大小不匹配，电脑端: !localSize!，手机端真实: !targetSize!
            call :log "[失败] !target! 电脑端与手机端真实大小不匹配"
            set /a failCount+=1
            goto :build_failed
        )

        echo [成功] 校验通过，!localSize! 字节
        call :log "[成功] !target! !localSize!字节"
        set /a okCount+=1

        %adbp% shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
    )
)

echo.
echo ============================================================
echo [打包成功] 所有分区已完整回读！ 39物理分区加1spuer 分区 40个img 是完整的AB包
echo   配置总数: !totalCount! 个
echo   成功: !okCount! 个
echo 保存目录: !readbackOut!
echo ============================================================
call :log "[打包成功] 总数=!totalCount! 成功=!okCount!"
exit /b 0


:build_failed
pause
echo.
echo ============================================================
echo [打包失败] 存在异常，正在清空文件夹...
%adbp% shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
if exist "!readbackOut!" rd /s /q "!readbackOut!"
echo 已清空: !readbackOut!
call :log "[打包失败] 已清空文件夹"
echo ============================================================
pause
exit /b 1

:log
echo %time% %~1 >> "%logFile%"
goto :eof