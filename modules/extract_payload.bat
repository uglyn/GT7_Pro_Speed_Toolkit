@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%payloadp%"  "cls"

call "%modulesDir%choose_file.bat" "payloadbinFile" " 卡刷包 payload.bin  "  || exit /b 1

set "rawList=%tempDir%raw_list.txt"
type nul > "!rawList!" 2>nul
set "cleanList=%tempDir%clean_list.txt"
type nul > "!cleanList!" 2>nul

"%payloadp%" -l "%payloadbinFile%" > "%rawList%" 2>&1
if errorlevel 1 (
    echo 读取分区列表失败。
    goto end
)

echo 正在提取分区列表...
powershell -NoProfile -Command "$c = Get-Content -LiteralPath '%rawList%' -Raw; if ($c -match 'Found partitions:\s*(.*)') { $s = $matches[1] -replace '\),\s*', '|'; $a = $s -split '\|'; $o = ''; foreach ($i in $a) { if ($i -match '^([a-zA-Z0-9_]+)\s*\((.*)') { $o += $matches[1] + '|' + $matches[2] + [Environment]::NewLine } }; [IO.File]::WriteAllText('%cleanList%', $o) }"

if not exist "%cleanList%" (
    echo [错误] 解析失败，未能生成分区列表。
    pause
    exit /b 1
)

echo.
echo ------------------------- 可用分区列表 -------------------------------------
set /a rowCount=0
set /a totalCount=0
set "lineStr="

for /f "usebackq tokens=1,2 delims=|" %%A in ("%cleanList%") do (
    set /a totalCount+=1
    set "idx=00!totalCount!"
    set "idx=!idx:~-3!"
    rem 拼接字符串： 序号 分区名 [大小描述]
    set "lineStr=!lineStr! !idx! %%A [%%B]   "
    set /a rowCount+=1
    if !rowCount! equ 4 (
        rem 使用 echo( 防止括号解析炸弹
        echo(!lineStr!
        set "lineStr="
        set /a rowCount=0
    )
)

if defined lineStr echo(!lineStr!

echo -----------------------------------------------------------------------------
echo 请输入要提取的分区名 (多个用英文逗号分隔，例如：boot,system_ext)
echo.
echo 直接回车[完整解压payload.bin]
echo.
echo 全部解压%pd0Dir%至少需要保留 15GB 空间
echo -----------------------------------------------------------------------------
set /p "partInput=提取的分区名: "

:gen_dir

set "outDir=%pd0Dir%extracted_%random%"
if exist "%outDir%" goto gen_dir
echo 输出目录: %outDir%
call :log "输出目录: %outDir%"
mkdir "%outDir%" 2>nul

if errorlevel 1 (
    echo 创建目录失败，请检查写入权限。
    pause
    exit /b 1
)


if "%partInput%"=="" (
    echo 正在解压全部分区到 %outDir% ...
    call :log "解压全部分区"
    "%payloadp%" -o "%outDir%" "%payloadbinFile%"
) else (
    echo 正在解压指定分区 [%partInput%] 到 %outDir% ...
    call :log "解压指定分区: %partInput%"
    "%payloadp%" -p "%partInput%" -o "%outDir%" "%payloadbinFile%"
)

if errorlevel 1 (
    echo 解压失败！请检查分区名是否正确 或 payload.bin 文件是否损坏。
    call :log "解压失败"
    if defined outDir  rmdir /s /q "%outDir%" 2>nul
    pause
    exit /b 1
)

echo 解压成功！输出目录: "%outDir%"
call :log "解压成功，输出目录: %outDir%"
start "" "%outDir%"
echo 操作完成！

:end
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof