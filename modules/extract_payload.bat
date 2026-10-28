@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%payloadp%"  "cls"

call "%modulesDir%choose_file.bat" "payloadbinFile" "卡刷包.zip 或 payload.bin"  || exit /b 1

set "rawList=%tempDir%raw_list.txt"
type nul > "!rawList!" 2>nul
set "cleanList=%tempDir%clean_list.txt"
del "!cleanList!" 2>nul

:gen_dir
set "outDir=%pd0Dir%extracted_%random%"
if exist "%outDir%" goto gen_dir
mkdir "%outDir%" 2>nul
if errorlevel 1 (
    echo(创建目录失败。
    goto exitb1
)

"%payloadp%" -l "%payloadbinFile%" > "%rawList%" 2>&1
if errorlevel 1 (
    echo(读取分区列表失败。
    goto exitb1
)

echo(正在提取分区列表...
powershell -NoProfile -Command "$c = Get-Content -LiteralPath '%rawList%' -Raw; if ($c -match 'Found partitions:\s*(.*)') { $s = $matches[1] -replace '\),\s*', '|'; $a = $s -split '\|'; $o = ''; foreach ($i in $a) { if ($i -match '^([a-zA-Z0-9_]+)\s*\((.*)') { $o += $matches[1] + '|' + $matches[2] + [Environment]::NewLine } }; [IO.File]::WriteAllText('%cleanList%', $o) }"

if not exist "%cleanList%" (
    echo([错误] 解析失败，未能生成分区列表。
    goto exitb1
)

:show_list
cls
echo.
echo(------------------------- 可用分区列表 -------------------------------------
set /a rowCount=0
set /a totalCount=0
set "lineStr="

for /f "usebackq tokens=1,2 delims=|" %%A in ("%cleanList%") do (
    set /a totalCount+=1
    set "paddedA=%%A               "
    set "paddedA=!paddedA:~0,15!"
    set "paddedB=%%B        "
    set "paddedB=!paddedB:~0,8!"
    set "padIdx= !totalCount!"
    set "padIdx=!padIdx:~-2!"
    set "lineStr=!lineStr! !padIdx! !paddedA! [!paddedB!]  "
    
    set /a rowCount+=1
    if !rowCount! equ 3 (
        echo(!lineStr!
        set "lineStr="
        set /a rowCount=0
    )
)
if defined lineStr echo(!lineStr!

echo(-----------------------------------------------------------------------------
echo(请输入要提取的分区名 (多个用空格或逗号分隔，例如：boot,tz  或    4 6 )
echo.
echo([0] 输入 0 完整解压 payload.bin  输入0 全部解压
echo(-----------------------------------------------------------------------------
set "userVar=0"
set /p "userVar=提取的分区名(或序号): [0全部解压]:"

rem 1. 输入 0，直接跳去全量解压
if "!userVar!"=="0" goto do_full_extract

rem 2. 如果直接回车，返回列表重输
if "!userVar!"=="" goto show_list

rem 3. 不覆盖 userVar，而是用中间变量存清洗后的输入
set "userVar=!userVar:，= !"
set "userVar=!userVar:,= !"

set "finalParts="
for %%N in (!userVar!) do (
    set "found="
    set "targetLine="
    
    rem 【第一遍】：当数字找行号
    set /a targetLine=%%N 2>nul
    if defined targetLine (
        set /a lineNo=0
        for /f "usebackq tokens=1 delims=|" %%A in ("!cleanList!") do (
            set /a lineNo+=1
            if !lineNo! equ !targetLine! set "found=%%A"
        )
    )
    
    rem 【第二遍】：当英文找名字
    if not defined found (
        for /f "usebackq tokens=1 delims=|" %%A in ("!cleanList!") do (
            if /i "%%A"=="%%N" set "found=%%A"
        )
    )
    
    if defined found set "finalParts=!finalParts!!found!,"
)

rem 4. 遍历结果判断
if not defined finalParts (
    echo.
    echo([错误] 你输入的 [!userVar!] 没有匹配到任何有效分区！
    echo(请按任意键返回列表重新选择...
    pause >nul
    goto show_list
)  
    rem 去掉末尾逗号，并赋值给最终变量
    set "finalParts=!finalParts:~0,-1!"
    set "userVar=!finalParts!"

:do_extract

cls
echo(正在解压指定分区 [!userVar!] 到 !outDir! ...
call "%modulesDir%logger.bat" "%~nx0"  "解压指定分区: !userVar!"
"%payloadp%" -p "!userVar!" -o "%outDir%" "%payloadbinFile%"
goto check_error

:do_full_extract
cls
echo.
echo([全量解压模式]
echo.
echo(正在解压全部分区到 !outDir! ...
call "%modulesDir%logger.bat" "%~nx0"  "解压全部分区"
"%payloadp%" -o "!outDir!" "%payloadbinFile%"
:check_error
if errorlevel 1 (
    echo(解压失败！
    call "%modulesDir%logger.bat" "%~nx0"  "解压失败"
    if defined outDir  rmdir /s /q "!outDir!" 2>nul
    goto exitb1
)

:end
call "%modulesDir%logger.bat" "%~nx0"  "解压成功，输出目录: !outDir!"
if defined rawList if exist "!rawList!" del  "!rawList!" 2>nul
if defined cleanList if exist  "!cleanList!" del "!cleanList!" 2>nul
echo(    --------------------------------------------------------------------------------------------
echo(    解压成功！输出目录: "!outDir!"
echo.
echo(    操作完成！
echo(    --------------------------------------------------------------------------------------------
start "" "!outDir!"
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

