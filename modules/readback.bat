@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call :log "--------------- 自由回读开始 ------------"
call "%modulesDir%header.bat" "%~nx0" "" "cls"

set "readbackOut=%readbackDir%%today%_%random%\"
if not exist "!readbackOut!" mkdir "!readbackOut!"

call "%modulesDir%wait_fastboot_device.bat" adb

%adbp% shell "su -c ""id""" 2>nul | findstr "uid=0" >nul
if errorlevel 1 (
    echo [错误] 未获取 Root 权限。
    pause
    exit /b 1
)
call :log "获取卡槽"
call "%modulesDir%get_slot.bat" "adb" || exit /b 1

call :log " 2. 获取设备真实分区列表（用于匹配）"
set "devPartList=%tempDir%dev_part.txt"
type nul > "!devPartList!"
for /f "usebackq delims=" %%P in (`%adbp% shell "su -c ""ls /dev/block/by-name/""" 2^>nul`) do (
    set "pname=%%P"
    set "pname=!pname: =!"
    if not "!pname!"=="" >> "!devPartList!" echo !pname!
)

call :log "统计设备总分区数量"
set "totalDevPartCount=0"
for /f "usebackq delims=" %%P in ("!devPartList!") do set /a totalDevPartCount+=1

call :log " 3 核心：读配置 匹配设备 写入 menuFile"
set "free_parts=%configDir%free_parts.txt"
if not exist "!free_parts!" (
    echo [错误] 找不到配置文件: !free_parts!
    pause
    exit /b 1
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
                    >> "!menuFile!" echo !menuCount!^|!realPart!^|!base!
                ) else if "!realPart:~0,-2!"=="!base!" (
                    set /a menuCount+=1
                    >> "!menuFile!" echo !menuCount!^|!realPart!^|!base!
                )
            )
        )
    )
)

if !menuCount! equ 0 (
    echo [错误] 配置文件 free_parts.txt 里没有一个分区能在设备上找到。
    pause
    exit /b 1
)

call :log "动态计算专属选项的序号"
set /a opt_common = !menuCount! + 1
set /a opt_all = !menuCount! + 2

:show_menu
cls
echo.
echo --------------------------以下为常用分区--------------- 
echo 分区配置文件: !free_parts!  
echo 回读保存目录: !readbackOut!
echo ------------------------------------------------------------

set "lastBase="
for /f "usebackq tokens=1,2,3 delims=|" %%A in ("!menuFile!") do (
    if not "%%C"=="!lastBase!" (
        if defined lastBase echo.
        set "lastBase=%%C"
    )
    <nul set /p "=[%%A]%%B "
)
echo.
echo [!opt_common!] 一键回读 !menuCount! 个常用分区
echo [!opt_all!] 一键回读设备全部 !totalDevPartCount! 个分区
echo ------------------------------------------------------------
echo.
echo 当前卡槽：!activeSlot!  注意每个卡槽数据 可能不同
echo.
echo ------------------------------------------------------------
echo [回读分区 数字空格隔开，如 1 2 3]
echo.  
echo 输入 Q 退出    必须看到回读成功才是成功
echo.
set "sel="
set /p "sel=输入序号回读: "

if /i "!sel!"=="Q" goto end
call :log "统一分隔符"
set "sel=!sel:，= !"
set "sel=!sel:,= !"

set "workMenuFile=!menuFile!"
set "finalSel="

if "!sel!"=="!opt_common!" (
    call :log "用户选择：全读常用分区"
    for /f "usebackq tokens=1 delims=|" %%P in ("!menuFile!") do (
        set "finalSel=!finalSel! %%P"
    )
) else if "!sel!"=="!opt_all!" (
    call :log "用户选择：全读设备全部分区"
    set "workMenuFile=%tempDir%all_menu.txt"
    type nul > "!workMenuFile!"
    set /a allCount=0
    for /f "usebackq delims=" %%P in ("!devPartList!") do (
        set /a allCount+=1
        >> "!workMenuFile!" echo !allCount!^|%%P
    )
    set "finalSel=0"
) else (
    set "finalSel=!sel!"
)

set /a okCount=0
set /a failCount=0

call :log "如果选中了全读设备，则展开所有序号"
if "!finalSel!"=="0" (
    set "finalSel="
    for /f "usebackq tokens=1 delims=|" %%P in ("!workMenuFile!") do (
        set "finalSel=!finalSel! %%P"
    )
)

for %%N in (!finalSel!) do (
    set "pname="
    for /f "usebackq tokens=1,2 delims=|" %%A in ("!workMenuFile!") do (
        if "%%A"=="%%N" set "pname=%%B"
    )

    if not defined pname (
        echo [警告] 无效的序号 %%N，跳过。
        set /a failCount+=1
    ) else (
        echo.
        echo 正在回读: !pname!
        set "saveFile=!readbackOut!!pname!.img"
        set "remoteImg=/data/local/tmp/readback_tmp.img"

        call :log "获取真实大小"
        set "targetSize=0"
        for /f "delims=" %%S in ('%adbp% shell "su -c ""blockdev --getsize64 /dev/block/by-name/!pname!""" 2^>nul') do set "targetSize=%%S"
        set "targetSize=!targetSize: =!"
        set "targetSize=!targetSize:	=!"

        if "!targetSize!"=="0" (
            echo [失败] 无法获取真实大小。
            goto :fail_cleanup
        ) else (
            %adbp% shell "su -c ""dd if=/dev/block/by-name/!pname! of=!remoteImg! bs=4096""" >nul 2>&1
            
            set "remoteSize=0"
            for /f "delims=" %%S in ('%adbp% shell "su -c ""wc -c < !remoteImg!""" 2^>nul') do set "remoteSize=%%S"
            set "remoteSize=!remoteSize: =!"
            set "remoteSize=!remoteSize:	=!"

            if "!remoteSize!" neq "!targetSize!" (
                echo [失败] dd 写入不完整，期望: !targetSize!，实际: !remoteSize!
                goto :fail_cleanup
            ) else (
                echo 传输中，真实大小: !targetSize! 字节
                %adbp% pull "!remoteImg!" "!saveFile!"

                set "localSize=0"
                if exist "!saveFile!" (
                    for %%F in ("!saveFile!") do set "localSize=%%~zF"
                )

                if "!localSize!" neq "!targetSize!" (
                    echo [失败] 传输中断，电脑端: !localSize!，手机真实: !targetSize!
                    goto :fail_cleanup
                ) else (
                    echo [成功] 回读通过: !localSize! 字节
                    set /a okCount+=1
                )
            )
        )
        %adbp% shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
    )
)

echo.
echo ============================================================
echo 本次执行完毕。成功: !okCount! 个，失败: !failCount! 个。
echo ============================================================

:end
if exist "!devPartList!" del "!devPartList!" >nul 2>&1
if exist "!menuFile!" del "!menuFile!" >nul 2>&1
if exist "!workMenuFile!" del "!workMenuFile!" >nul 2>&1
exit /b 0

:fail_cleanup
echo.
echo ============================================================
echo [打包失败] 存在异常，正在清空文件夹...
%adbp% shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
if exist "!readbackOut!" rd /s /q "!readbackOut:~0,-1!"
echo 已清空: !readbackOut!
call :log "[打包失败] 已清空文件夹"
echo ============================================================
pause
goto show_menu



:log
echo %time% %~1 >> "%logFile%"
goto :eof