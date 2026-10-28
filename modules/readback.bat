@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

:gen_dir
set "readbackOut=%readbackDir%%today%_%random%\"
if exist "%readbackOut%" goto gen_dir
mkdir "%readbackOut%"

call "%modulesDir%wait_fastboot_device.bat" "adb"  || exit /b 1

"%adbp%" shell "su -c ""id""" 2>nul | findstr "uid=0" >nul
if errorlevel 1 (
    echo([错误] 未获取 Root 权限。请授权Shell Root权限
    goto exitb1
)

call "%modulesDir%logger.bat" "%~nx0"  "获取卡槽"
call "%modulesDir%get_slot.bat" "adb" || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "获取设备真实分区列表（用于匹配）"
set "devPartList=%tempDir%dev_part.txt"
type nul > "%devPartList%"

rem 全部分区及统计数量
set "totalDevPartCount=0"
set "devPartRaw=%tempDir%dev_part_raw.txt"
type nul > "!devPartRaw!" 2>nul
"%adbp%" shell "su -c ""ls /dev/block/by-name/""" > "!devPartRaw!" 2>nul
for /f "usebackq delims=" %%P in ("!devPartRaw!") do (
    set "pname=%%P"
    set "pname=!pname: =!"
    if not "!pname!"=="" (
        >> "!devPartList!" echo(!pname!
        set /a totalDevPartCount+=1
    )
)

call "%modulesDir%logger.bat" "%~nx0"  "核心：读配置 匹配设备 写入 menuFile"
set "free_parts=%configDir%free_parts.txt"
if not exist "!free_parts!" (
    echo([错误] 找不到配置文件: !free_parts!
    goto exitb1
)

set "menuFile=%tempDir%menu_display.txt"
type nul > "!menuFile!"

set /a menuCount=0
if exist "!free_parts!" (
    for /f "usebackq delims=" %%P in ("!free_parts!") do (
        set "base=%%P"
        set "base=!base: =!"
        set "base=!base:	=!"
        if not "!base!"=="" (
            for /f "usebackq delims=" %%A in ("!devPartList!") do (
                set "realPart=%%A"
                if "!realPart!"=="!base!" (
                    set /a menuCount+=1
                    >> "!menuFile!" echo(!menuCount!^|!realPart!^|!base!
                ) else if "!realPart:~0,-2!"=="!base!" (
                    set /a menuCount+=1
                    >> "!menuFile!" echo(!menuCount!^|!realPart!^|!base!
                )
            )
        )
    )
)

if !menuCount! equ 0 (
    echo([错误] 配置文件 free_parts.txt 里没有一个分区能在设备上找到。
    goto exitb1
)

call "%modulesDir%logger.bat" "%~nx0"  "动态计算专属选项的序号"
set /a opt_common = !menuCount! + 1
set /a opt_all = !menuCount! + 2

:show_menu
cls
echo.
echo(--------------------------以下为常用分区--------------- 
echo(分区配置文件: !free_parts!  
echo(回读保存目录: !readbackOut!
echo(------------------------------------------------------------

set "lastBase="
for /f "usebackq tokens=1,2,3 delims=|" %%A in ("!menuFile!") do (
    if not "%%C"=="!lastBase!" (
        if defined lastBase echo.
        set "lastBase=%%C"
    )
    <nul set /p "=[%%A]%%B "
)
echo.
echo([!opt_common!] 一键回读 !menuCount! 个常用分区
echo([!opt_all!] 一键回读设备全部 !totalDevPartCount! 个分区
echo(------------------------------------------------------------
echo.
echo(当前卡槽：!activeSlot!  注意每个卡槽数据 可能不同
echo.
echo(------------------------------------------------------------
echo([输入数字 回读分区 数字空格隔开，如 1 2 3]
echo.  
echo(输入Q加回车 退出       必须看到回读成功才是成功
echo.
set "sel="
set /p "sel=输入序号回读: "
if /i "!sel!"=="Q" exit /b 0
if "!sel!"=="" goto show_menu
set "sel=!sel:，= !"
set "sel=!sel:,= !"

set "processList="

rem ================= 核心分流：全部化为纯分区名放入 processList =================
if "!sel!"=="!opt_common!" (
    call "%modulesDir%logger.bat" "%~nx0"  "用户选择：全读常用分区"
    for /f "usebackq tokens=2 delims=|" %%P in ("!menuFile!") do (
        set "processList=!processList! %%P"
    )
    goto start_readback
)

if "!sel!"=="!opt_all!" (
    call "%modulesDir%logger.bat" "%~nx0"  "用户选择：全读设备全部分区"
    for /f "usebackq delims=" %%P in ("!devPartList!") do (
        set "processList=!processList! %%P"
    )
    goto start_readback
)

rem =======================================================
rem 如果上面两个都没命中，说明用户输入了具体的数字
rem =======================================================
call "%modulesDir%logger.bat" "%~nx0"  "用户选择：指定序号回读"
for %%N in (!sel!) do (
    for /f "usebackq tokens=1,2 delims=|" %%A in ("!menuFile!") do (
        if "%%A"=="%%N" set "processList=!processList! %%B"
    )
)

:start_readback
if not defined processList (
    echo.
    echo([警告] 未匹配到任何有效分区，请重新输入。
    timeout /t 2
    goto show_menu
)

set /a okCount=0
set /a failCount=0

rem 直接遍历纯净的分区名列表
for %%N in (!processList!) do (
    set "pname=%%N"
    
    echo.
    echo(--------------------------------------------------------------
    echo(正在回读: !pname!
    set "saveFile=!readbackOut!!pname!.img"
    set "remoteImg=/data/local/tmp/readback_tmp.img"

    call "%modulesDir%logger.bat" "%~nx0"  "获取!pname!真实大小"
    set "sizeTmp=%tempDir%size_tmp.txt"
    type nul > "!sizeTmp!" 2>nul
    "%adbp%" shell "su -c ""blockdev --getsize64 /dev/block/by-name/!pname!""" > "!sizeTmp!" 2>nul
    set "targetSize="
    for /f "usebackq delims=" %%S in ("!sizeTmp!") do set "targetSize=%%S"
    set "targetSize=!targetSize: =!"
    set "targetSize=!targetSize:	=!"

    if not defined targetSize (
        echo([失败] 无法获取真实大小。
        goto :fail_cleanup
    )
    if "!targetSize!"=="0" (
        echo([失败] 无法获取真实大小。
        goto :fail_cleanup
    )

    "%adbp%" shell "su -c ""dd if=/dev/block/by-name/!pname! of=!remoteImg! bs=4096""" >nul 2>&1
    
    echo(传输中，手机内部img真实大小: !targetSize! 字节
    echo(%adbp%  pull  !remoteImg!   !saveFile! 
    "%adbp%" pull "!remoteImg!" "!saveFile!"

    set "localSize=0"
    if exist "!saveFile!" (
        for %%F in ("!saveFile!") do set "localSize=%%~zF"
    )

    rem 直接对比电脑端拉回来的文件 和 真实分区大小
    if not "!localSize!"=="!targetSize!" (
        echo([失败] 传输中断或备份失败，电脑端: !localSize!，手机真实: !targetSize!
        call "%modulesDir%logger.bat" "%~nx0"  "!pname!.img电脑端: !localSize!，手机真实: !targetSize!"
        goto :fail_cleanup
    )  
    set /a okCount+=1
    echo([!okCount!] !pname!回读[成功]  电脑本地大小: !localSize! 字节  校验OK!
    call "%modulesDir%logger.bat" "%~nx0"  "!pname!回读[成功]  电脑端大小: !localSize!，手机真实大小: !targetSize!"
    "%adbp%" shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
)

echo.
echo(============================================================
echo(本次执行完毕。成功: !okCount! 个，失败: !failCount! 个。
echo(============================================================
:end
if defined devPartRaw if exist "!devPartRaw!" del "!devPartRaw!" >nul 2>&1
if defined sizeTmp if exist "!sizeTmp!" del "!sizeTmp!" >nul 2>&1
del "!devPartList!" >nul 2>&1
del "!menuFile!" >nul 2>&1
exit /b 1

:fail_cleanup
if defined sizeTmp if exist "!sizeTmp!" del "!sizeTmp!" >nul 2>&1
echo.
echo(============================================================
echo([回读失败] 存在异常，正在清空文件夹...
"%adbp%" shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
if exist "!readbackOut!" rd /s /q "!readbackOut:~0,-1!"
echo(已清空: !readbackOut!
call "%modulesDir%logger.bat" "%~nx0"  "[回读失败] 已清空文件夹"
echo(============================================================

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1