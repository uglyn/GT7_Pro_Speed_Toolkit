@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
del "%pd0Dir%toolbox_busy.lock" 2>nul

set "readbackRoot=%pd0Dir%readback\"
if not exist "%readbackRoot%" mkdir "%readbackRoot%"
if not exist "%tempDir%" mkdir "%tempDir%"

if not defined today set "today=%date:/=%"
set "readbackDir=%readbackRoot%readback_%today%_%random%\%"
if not exist "!readbackDir!" mkdir "!readbackDir!"

echo.
echo 保存目录 !readbackDir!
echo ============================================================

call "%modulesDir%wait_fastboot_device.bat" adb

"%adbPath%" shell "su -c ""id""" 2>nul | findstr "uid=0" >nul
if errorlevel 1 (
    echo 错误 未获取 Root 权限
    pause
    exit /b 1
)
echo OK 已获取 Root 权限

set "partListFile=%tempDir%part_list.txt"
"%adbPath%" shell "su -c ""ls /dev/block/by-name/""" > "%partListFile%" 2>nul
if not exist "%partListFile%" (
    echo 错误 无法获取分区列表
    pause
    exit /b 1
)

set "partMap=%tempDir%part_map.txt"
type nul > "%partMap%"

set "partCount=0"
for /f "usebackq delims=" %%A in ("%partListFile%") do (
    set "pname=%%A"
    set "pname=!pname: =!"
    if not "!pname!"=="" (
        set /a partCount+=1
        >> "%partMap%" echo !partCount!^|!pname!
    )
)

if %partCount%==0 (
    echo 错误 分区列表为空
    pause
    exit /b 1
)

:show_menu
cls
echo ============================================================
echo              分区回读工具
echo ============================================================
echo 保存目录 !readbackDir!
echo 共 %partCount% 个分区
echo.

set "line="
set /a col=0
for /f "usebackq tokens=1,2 delims=|" %%A in ("%partMap%") do (
    set "item=%%A %%B                    "
    set "item=!item:~0,22!"
    set "line=!line! !item!"
    set /a col+=1
    if !col! equ 4 (
        echo !line!
        set "line="
        set /a col=0
    )
)
if not "!line!"=="" echo !line!

echo.
echo 输入序号回读 用逗号分隔 如 1,2,11 输入 Q 退出
echo.

set "sel="
set /p "sel=请输入 "
if "%sel%"=="" goto :show_menu
if /i "%sel%"=="Q" exit /b 0

:: 将中英文逗号和空格全部统一为英文逗号 保证多选正常
set "sel=%sel:，=,%"
set "sel=%sel: =,%"

set "selFile=%tempDir%sel_parts.txt"
type nul > "%selFile%"

for %%s in (%sel:,= %) do (
    set "n=%%s"
    set "partName="
    for /f "usebackq tokens=1,2 delims=|" %%A in ("%partMap%") do (
        if "%%A"=="!n!" set "partName=%%B"
    )
    if defined partName (
        >>"%selFile%" echo !partName!
    )
    if not defined partName (
        echo 跳过 序号 %%s 无效
    )
)

set "selCount=0"
for /f "usebackq delims=" %%X in ("%selFile%") do set /a selCount+=1
if !selCount! equ 0 (
    echo 提示 没有有效的分区被选中
    pause >nul
    goto :show_menu
)

set /a curCount=0

for /f "usebackq delims=" %%P in ("%selFile%") do (
    set /a curCount+=1
    set "pname=%%P"
    set "saveFile=!readbackDir!!pname!.img"

    echo.
    echo ============================================================
    echo 进度 !curCount! / !selCount! 正在回读 !pname!
    echo ============================================================

    set "remoteImg=/data/local/tmp/readback_tmp.img"

    echo 正在手机内部读取数据
    "%adbPath%" shell "su -c ""dd if=/dev/block/by-name/!pname! of=!remoteImg! bs=4096""" >nul 2>&1

    set "remoteSize=0"
    "%adbPath%" shell "su -c ""stat -c %%s !remoteImg!""" > "%tempDir%rs.txt" 2>nul
    if exist "%tempDir%rs.txt" (
        for /f "usebackq delims=" %%S in ("%tempDir%rs.txt") do set "remoteSize=%%S"
    )
    set "remoteSize=!remoteSize: =!"
    set "remoteSize=!remoteSize:	=!"
    if "!remoteSize!"=="" set "remoteSize=0"

    if "!remoteSize!"=="0" (
        echo 失败 读取失败或分区不存在
        "%adbPath%" shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
        goto :read_next
    )

    echo 传输中 手机端大小 !remoteSize! 字节
    "%adbPath%" pull "!remoteImg!" "!saveFile!"

    set "localSize=0"
    if exist "!saveFile!" (
        for %%F in ("!saveFile!") do set "localSize=%%~zF"
    )

    if "!localSize!" neq "!remoteSize!" (
        echo 失败 传输中断 删除残缺文件
        if exist "!saveFile!" del "!saveFile!" >nul 2>&1
    )

    if "!localSize!"=="!remoteSize!" (
        echo 成功 !localSize! 字节
    )

    :read_next
    "%adbPath%" shell "su -c ""rm -f !remoteImg!""" >nul 2>&1
)

echo.
echo ============================================================
echo 回读结束
echo 文件保存目录 !readbackDir!
echo ============================================================
echo.
echo 按任意键返回菜单
timeout /t 4
goto :show_menu