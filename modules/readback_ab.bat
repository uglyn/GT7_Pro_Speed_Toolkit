@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
call "%modulesDir%header.bat" "%~nx0" "" "cls"

set "partTxt=%configDir%ab_partitions.txt"
if not exist "%partTxt%" (
    echo [错误] 找不到配置文件: %partTxt%
    pause
    exit /b 1
)

set "readbackRoot=%pd0Dir%readback\"
if not exist "%readbackRoot%" mkdir "%readbackRoot%"
set "readbackDir=%readbackRoot%%today%_%random%\%"
if not exist "!readbackDir!" mkdir "!readbackDir!"

call :log "========== 一键回读开始，会话目录: !readbackDir! =========="

echo.
echo ============================================================
echo            一键回读 %partTxt%
echo ============================================================
echo 保存目录: !readbackDir!
echo.

call "%modulesDir%wait_fastboot_device.bat" adb

"%adbPath%" shell "su -c ""id""" 2>nul | findstr "uid=0" >nul
if errorlevel 1 (
    echo [错误] 未获取 Root 权限，请授权 shell ROOT 权限
    call :log "[错误] 未获取 Root 权限"
    pause
    exit /b 1
)
echo [OK] 已获取 Root 权限。


set "devList=%tempDir%dev_blocks.txt"
"%adbPath%" shell "su -c ""ls /dev/block/by-name/""" > "%devList%" 2>nul
if not exist "%devList%" (
    echo [错误] 无法获取设备分区节点。
    pause
    exit /b 1
)

set "slotSuffix="
for /f "delims=" %%s in ('adb shell getprop ro.boot.slot_suffix 2^>nul') do set "slotSuffix=%%s"
set "slotSuffix=!slotSuffix:"=!"

if "!slotSuffix!"=="" (
    echo [错误] 无法获取当前卡槽 _a 或 _b，脚本终止。
    pause
    exit /b 1
)

echo.
echo 当前卡槽后缀: !slotSuffix!
echo.
echo 开始一键回读...
echo.
echo ----------------------------------------------------------------------------------
set "okCount=0"
set "skipCount=0"
set "failCount=0"

rem 初始化记录文件（回读结束后保留）
type nul > "!readbackDir!readback_info.txt" 2>nul
type nul > "!readbackDir!remote_sizes.txt" 2>nul
type nul > "!readbackDir!fail_list.txt" 2>nul
type nul > "!readbackDir!final_report.txt" 2>nul

rem ====== 统计总分区数 ======
set /a totalCount=0
for /f "usebackq delims=" %%P in ("%partTxt%") do (
    set "base=%%P"
    set "base=!base: =!"
    set "base=!base:	=!"
    if not "!base!"=="" set /a totalCount+=1
)

rem ====== 带进度执行回读 ======
set /a curCount=0
for /f "usebackq delims=" %%P in ("%partTxt%") do (
    set "base=%%P"
    set "base=!base: =!"
    set "base=!base:	=!"
    if not "!base!"=="" (
        set /a curCount+=1
        echo.
        echo [!curCount!/!totalCount!] !base!
        call :read_one "!base!"
    )
)

echo.
echo ====== 终检：校验所有回读文件 ======
set "checkOk=0"
set "checkFail=0"

if exist "!readbackDir!readback_info.txt" (
    for /f "usebackq tokens=1,2 delims=|" %%A in ("!readbackDir!readback_info.txt") do (
        set "cname=%%A"
        set "csize=%%B"
        set "cfile=!readbackDir!!cname!.img"
        if exist "!cfile!" (
            for %%F in ("!cfile!") do set "actualSize=%%~zF"
            if "!actualSize!"=="!csize!" (
                echo [OK] !cname! !actualSize! 字节
                set /a checkOk+=1
            ) else (
                echo [异常] !cname! 大小不匹配，记录: !csize!，实际: !actualSize!
                >> "!readbackDir!final_report.txt" echo [异常] !cname! 记录: !csize! 实际: !actualSize!
                set /a checkFail+=1
            )
        ) else (
            echo [缺失] !cname!.img 不存在
            >> "!readbackDir!final_report.txt" echo [缺失] !cname!.img
            set /a checkFail+=1
        )
    )
)
echo 终检完成：正常 !checkOk! 个，异常 !checkFail! 个

echo.
echo ============================================================
echo 回读完成！
echo   成功: !okCount! 个
echo   跳过: !skipCount! 个
echo   失败: !failCount! 个
echo 保存目录: !readbackDir!
echo ============================================================

rem ====== 把最终统计写进报告文件 ======
>> "!readbackDir!final_report.txt" echo.
>> "!readbackDir!final_report.txt" echo ====== 最终统计 ======
>> "!readbackDir!final_report.txt" echo 回读成功: !okCount! 个
>> "!readbackDir!final_report.txt" echo 跳过: !skipCount! 个
>> "!readbackDir!final_report.txt" echo 失败: !failCount! 个
>> "!readbackDir!final_report.txt" echo 终检正常: !checkOk! 个
>> "!readbackDir!final_report.txt" echo 终检异常: !checkFail! 个

call :log "回读完成 成功=!okCount! 跳过=!skipCount! 失败=!failCount! 终检异常=!checkFail!"
timeout /t 5 >nul
exit /b 0


:: ============================================================
:: 单分区回读
:: ============================================================
:read_one
set "pname=%~1"
set "target="

rem 优先匹配当前卡槽后缀
findstr /x /c:"!pname!!slotSuffix!" "%devList%" >nul
if not errorlevel 1 set "target=!pname!!slotSuffix!"

rem 找不到再匹配无后缀的物理分区
if not defined target (
    findstr /x /c:"!pname!" "%devList%" >nul
    if not errorlevel 1 set "target=!pname!"
)

rem 都没有，跳过
if not defined target (
    echo [跳过] !pname! - 当前卡槽 !slotSuffix! 不存在该分区节点
    call :log "[跳过] !pname! 节点不存在"
    set /a skipCount+=1
    goto :eof
)

set "saveName=!target!"
if "!saveName:~-2!"=="_a" set "saveName=!saveName:~0,-2!"
if "!saveName:~-2!"=="_b" set "saveName=!saveName:~0,-2!"
set "saveFile=!readbackDir!!saveName!.img"

echo [回读] !target!  -^>  !saveFile!
call :log "[回读] !target! -> !saveFile!"

set "remoteImg=/data/local/tmp/readback_tmp.img"

echo 正在手机内部读取数据，请稍候...
"%adbPath%" shell "su -c ""dd if=/dev/block/by-name/!target! of=!remoteImg! bs=4096""" >nul 2>&1

:: ===== 获取手机端大小 =====
set "remoteSizeTmp=%tempDir%remote_size.txt"
set "remoteSize=0"

"%adbPath%" shell "su -c ""stat -c %%s !remoteImg!""" > "%remoteSizeTmp%" 2>nul

if exist "%remoteSizeTmp%" (
    for /f "usebackq delims=" %%S in ("%remoteSizeTmp%") do set "remoteSize=%%S"
    >> "!readbackDir!remote_sizes.txt" echo !saveName!^|!remoteSize!
    del "%remoteSizeTmp%" >nul 2>&1
)

set "remoteSize=!remoteSize: =!"
set "remoteSize=!remoteSize:	=!"
if "!remoteSize!"=="" set "remoteSize=0"

:: ===== 失败情况1：手机端读取失败 =====
if "!remoteSize!"=="0" (
    echo [失败] 手机端读取失败，临时文件为空
    call :log "[失败] !target! 手机端 dd 失败"
    set /a failCount+=1
    >> "!readbackDir!fail_list.txt" echo [!pname!] 手机内部读取失败（dd 空文件）
    if exist "!saveFile!" del "!saveFile!" >nul 2>&1
    "%adbPath%" shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
    goto :eof
)

echo 传输中 (手机端大小: !remoteSize! 字节):
"%adbPath%" pull "!remoteImg!" "!saveFile!"

:: ===== 对比大小 =====
set "localSize=0"
if exist "!saveFile!" (
    for %%F in ("!saveFile!") do set "localSize=%%~zF"
)

:: ===== 失败情况2：传输不完整 =====
if "!localSize!" neq "!remoteSize!" (
    echo   [失败] 传输不完整或中断
    call :log "[失败] !target! 大小不一致，电脑端: !localSize!，手机端: !remoteSize!"
    set /a failCount+=1
    >> "!readbackDir!fail_list.txt" echo [!pname!] 传输中断（电脑端: !localSize!，手机端: !remoteSize!）
    if exist "!saveFile!" del "!saveFile!" >nul 2>&1
) else (
    echo [成功] 校验通过，!localSize! 字节
    call :log "[成功] !target! !localSize! 字节"
    set /a okCount+=1
    >> "!readbackDir!readback_info.txt" echo !saveName!^|!localSize!
)

:: 清理手机临时文件
"%adbPath%" shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
goto :eof

:log
echo %time% %~1 >> "%logFile%"
goto :eof