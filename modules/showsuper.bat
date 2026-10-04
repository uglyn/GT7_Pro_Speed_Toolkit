@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
call "%modulesDir%header.bat" "%~nx0" "%fastbootp%" "cls"

call :log "重启到fastboot"
call "%modulesDir%wait_fastboot_device.bat" fastboot

set "superList=%tempDir%super_list.txt"
type nul > "!superList!"


set "superSizeHex="
set "partCount=0"


set "infoFile=%tempDir%super_info.txt"
type nul > "!infoFile!"

"%fastbootp%" getvar all > "!infoFile!" 2>&1
rem 获取 super 总大小 十六进制
for /f "tokens=3 delims=:" %%a in ('findstr /i "partition-size:super:" "!infoFile!"') do (
    set "s=%%a"
    set "s=!s: =!"
    if not "!s!"=="" if "!superSizeHex!"=="" set "superSizeHex=!s!"
)

rem 遍历所有逻辑分区
for /f "tokens=2 delims=:" %%a in ('findstr /i "is-logical:.*:yes" "!infoFile!"') do (
    set "p=%%a"
    set "p=!p: =!"
    set "skip=0"
    if /i "!p!"=="userdata" set "skip=1"
    if /i "!p!"=="hybridswap_crypto" set "skip=1"
    if "!p!"=="" set "skip=1"
    if !skip! equ 0 (
        set "psize="
        for /f "tokens=3 delims=:" %%s in ('findstr /i "partition-size:!p!:" "!infoFile!"') do (
            set "r=%%s"
            set "r=!r: =!"
            set "hex=!r:0x=!"
            set /a "psize=0x!hex!" 2>nul
            rem 如果为负 说明超过2G 退回十六进制显示
            if !psize! lss 0 set "psize=!r!"
        )
        if "!psize!"=="" set "psize=未知"
        set /a partCount+=1
        echo !partCount! 分区 !p! 大小 !psize!>> "%superList%"
    )
)

cls
echo super总大小 !superSizeHex! 字节
echo 子分区总数 !partCount!
echo ------------------------------------------------------------
type "%superList%"
echo ------------------------------------------------------------
echo 共 !partCount! 个条目
echo.
pause
del "!superList!" > nul
del "!infoFile!" > nul
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof