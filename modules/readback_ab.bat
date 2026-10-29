@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

set "partTxt=%configDir%ab_partitions.txt"
if not exist "%partTxt%" (
    echo([错误] 找不到分区配置文件: %partTxt%
    call "%modulesDir%logger.bat" "%~nx0"  "[错误] 找不到配置文件: %partTxt%"
    goto exitb1
)

:gen_dir
set "readbackOut=%readbackDir%%today%_%random%\"
if  exist "!readbackOut!" goto gen_dir
mkdir "!readbackOut!"

set "okCount=0"
set "totalCount=0"
set "curCount=0"

call "%modulesDir%logger.bat" "%~nx0"  "遍历获取总数"
for /f "usebackq delims=" %%P in ("%partTxt%") do (
    set "base=%%P"
    set "base=!base: =!"
    set "base=!base:	=!"
    if not "!base!"=="" set /a totalCount+=1
)

call "%modulesDir%logger.bat" "%~nx0"  "配置文件共发现 !totalCount! 个分区"
echo(配置文件共发现 !totalCount! 个分区待回读。

call "%modulesDir%logger.bat" "%~nx0"  "等待设备连接到 adb"
call "%modulesDir%wait_fastboot_device.bat" "adb" || exit /b 1

"%adbp%" shell "su -c ""id""" 2>nul | findstr "uid=0" >nul
if errorlevel 1 (
    echo([错误] 未获取 Root 权限，请授权 shell ROOT 权限。
    call "%modulesDir%logger.bat" "%~nx0"  "[错误] 未获取 Root 权限"
    goto exitb1
)
echo([OK] 已获取 Root 权限。
call "%modulesDir%logger.bat" "%~nx0"  "[OK] 已获取 Root 权限"

rem 获取物理分区列表
set "devList=%tempDir%dev_blocks.txt"
type nul>"!devList!"
"%adbp%" shell "su -c ""ls /dev/block/by-name/""" > "!devList!" 2>nul

rem 获取动态分区列表
set "mapperList=%tempDir%mapper_blocks.txt"
type nul>"!mapperList!"
"%adbp%" shell "su -c ""ls /dev/block/mapper/""" > "!mapperList!" 2>nul

call "%modulesDir%logger.bat" "%~nx0"  "获取卡槽"
call "%modulesDir%get_slot.bat" "adb" || exit /b 1

cls
echo.
echo(当前卡槽 : !activeSlot!
call "%modulesDir%logger.bat" "%~nx0"  "当前卡槽: !activeSlot!"
echo.
echo(开始回读...
set "remoteImg=/data/local/tmp/readback_tmp.img"

for /f "usebackq delims=" %%P in ("%partTxt%") do (
    set "base=%%P"
    set "base=!base: =!"
    set "base=!base:	=!"
    echo.
    if not "!base!"=="" (
        set /a curCount+=1
        echo([!curCount!/!totalCount!] 正在处理: !base!
        call "%modulesDir%logger.bat" "%~nx0"  "[!curCount!/!totalCount!] 处理: !base!"

        set "target="
        set "isMapper=0"

        rem 1. 优先在物理分区里找 (带槽位后缀)
        findstr /x /c:"!base!_!activeSlot!" "%devList%" >nul
        if not errorlevel 1 set "target=!base!_!activeSlot!"

        rem 2. 再在物理分区里找 (不带后缀)
        if not defined target (
            findstr /x /c:"!base!" "%devList%" >nul
            if not errorlevel 1 set "target=!base!"
        )

        rem 3. 如果物理分区里没有，去动态分区 mapper 里找 (带槽位后缀)
        if not defined target (
            findstr /x /c:"!base!_!activeSlot!" "%mapperList%" >nul
            if not errorlevel 1 (
                set "target=!base!_!activeSlot!"
                set "isMapper=1"
            )
        )

        rem 4. 再去动态分区 mapper 里找 (不带后缀)
        if not defined target (
            findstr /x /c:"!base!" "%mapperList%" >nul
            if not errorlevel 1 (
                set "target=!base!"
                set "isMapper=1"
            )
        )

        rem 如果全找遍了还是没有，直接报错清空
        if not defined target (
            echo([失败] 设备上没有 !base!_!activeSlot! 或 !base!
            call "%modulesDir%logger.bat" "%~nx0"  "[失败] !base! 不存在"
            goto :build_failed
        )

        set "saveFile=%readbackOut%!base!.img"

        rem 判断最终的实际路径
        if "!isMapper!"=="1" (
            set "realPath=/dev/block/mapper/!target!"
        ) else (
            set "realPath=/dev/block/by-name/!target!"
        )

        echo([回读] !realPath! -^> !saveFile!
        call "%modulesDir%logger.bat" "%~nx0"  "[回读] !realPath! -> !saveFile!"

        call "%modulesDir%logger.bat" "%~nx0"  "获取 !base!分区真实物理大小"
        set "sizeTmp=%tempDir%size_tmp.txt"
        type nul > "!sizeTmp!" 2>nul
        "!adbp!" shell "su -c ""blockdev --getsize64 !realPath!""" > "!sizeTmp!" 2>nul
        set "targetSize="
        for /f "usebackq delims=" %%S in ("!sizeTmp!") do set "targetSize=%%S"
        set "targetSize=!targetSize: =!"
        set "targetSize=!targetSize:	=!"

        if not defined targetSize (
            echo([失败] 无法获取分区真实大小
            call "%modulesDir%logger.bat" "%~nx0"  "[失败] !target! 无法获取真实大小"
            goto :build_failed
        )
        if "!targetSize!"=="0" (
            echo([失败] 无法获取分区真实大小
            call "%modulesDir%logger.bat" "%~nx0"  "[失败] !target! 无法获取真实大小"
            goto :build_failed
        )
        
        "!adbp!" shell "su -c ""dd if=!realPath! of=!remoteImg! bs=4096""" >nul 2>&1

        echo(传输中，手机端真实大小: !targetSize! 字节
        "!adbp!" pull "!remoteImg!" "!saveFile!"

        set "localSize=0"
        if exist "!saveFile!" (
            for %%F in ("!saveFile!") do set "localSize=%%~zF"
        )

        if not "!localSize!"=="!targetSize!" (
            echo(  [失败] 大小不匹配，电脑端: !localSize!，手机端真实: !targetSize!
            call "%modulesDir%logger.bat" "%~nx0"  "[失败] !target! 电脑端与手机端真实大小不匹配"   
            goto :build_failed
        )

        echo(!base! [回读成功] 电脑本地大小:!localSize! 字节 校验OK
        call "%modulesDir%logger.bat" "%~nx0"  "!target! 回读成功 电脑本地大小:!localSize! 字节 手机端真实: !targetSize!字节"
        set /a okCount+=1
        "%adbp%" shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
    )
)

echo.
echo(============================================================
echo([打包成功] 所有分区已完整回读！ 
echo(  配置总数: !totalCount! 个
echo(  成功: !okCount! 个
echo(保存目录: !readbackOut!
echo(============================================================
call "%modulesDir%logger.bat" "%~nx0"  "[打包成功] 总数=!totalCount! 成功=!okCount!"
if defined sizeTmp if exist "!sizeTmp!" del "!sizeTmp!" >nul 2>&1
if defined devList if exist "!devList!" del "!devList!" >nul 2>&1
if defined mapperList if exist "!mapperList!" del "!mapperList!" >nul 2>&1
exit /b 1

:build_failed
if defined sizeTmp if exist "!sizeTmp!" del "!sizeTmp!" >nul 2>&1
if defined devList if exist "!devList!" del "!devList!" >nul 2>&1
if defined mapperList if exist "!mapperList!" del "!mapperList!" >nul 2>&1
echo.
echo(============================================================
echo([打包失败] 存在异常，正在清空文件夹...
"%adbp%" shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
if exist "!readbackOut!" rd /s /q "!readbackOut:~0,-1!"
echo(已清空: !readbackOut!
call "%modulesDir%logger.bat" "%~nx0"  "[打包失败] 已清空文件夹"
echo(============================================================
:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1