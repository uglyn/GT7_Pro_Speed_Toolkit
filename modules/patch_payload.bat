@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
call "%modulesDir%header.bat" "%~nx0" "%payload-dumper-goPath%" "cls"

echo ========================================================
echo            基础包 + 增量包 = 新全量包 
echo ========================================================
echo.

:: ================================================================
:: 第一步：获取基础包文件夹（直接输出到 OLD_DIR）
:: ================================================================
call "%modulesDir%choose_source.bat" "OLD_DIR" "OLD_LIST" "基础包文件夹"
if errorlevel 1 (
    echo 用户取消选择，退出。
    pause
    exit /b 1
)

:: ================================================================
:: 第二步：拖入增量包（支持 .zip / payload.bin）
:: ================================================================
call "%modulesDir%choose_file.bat" "INC_FILE" "增量包(.zip 或 payload.bin)"
if errorlevel 1 (
    echo 用户取消选择，退出。
    pause
    exit /b 1
)

set "INC_PAYLOAD="
set "ZIP_TMP="

for %%i in ("%INC_FILE%") do (
    if /i "%%~xi"==".zip" (
        echo.
        echo 检测到 .zip 增量包，正在提取 payload.bin ...
        set "ZIP_TMP=%tempDir%ota_bin_%random%"
        mkdir "!ZIP_TMP!" 2>nul
        
        rem 使用 PowerShell 精准提取单个文件，$ 变量全在双引号内，彻底避免 bat 语法错误
        powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip=[System.IO.Compression.ZipFile]::OpenRead('!INC_FILE!'); $entry=$zip.Entries | Where-Object { $_.Name -eq 'payload.bin' } | Select-Object -First 1; if($entry){ [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, '!ZIP_TMP!\payload.bin', $true) }; $zip.Dispose()" >nul 2>&1
        
        if exist "!ZIP_TMP!\payload.bin" (
            set "INC_PAYLOAD=!ZIP_TMP!\payload.bin"
            echo [成功] 已提取 payload.bin
        ) else (
            echo [错误] 在 zip 中没有找到 payload.bin！
            rmdir /s /q "!ZIP_TMP!" 2>nul
            pause
            exit /b 1
        )
    ) else (
        set "INC_PAYLOAD=%INC_FILE%"
    )
)

:: ================================================================
:: 第三步：生成输出目录并执行合成
:: ================================================================
:gen_dir
set "outDir=%pd0Dir%patched_%random%"
if exist "%outDir%" goto gen_dir

echo.
echo ========================================================
echo 基础包目录: %OLD_DIR%
echo 增量包路径: %INC_PAYLOAD%
echo 输出目录  : %outDir%
echo ========================================================
echo.
echo 正在合成新包，请稍候...
echo.

mkdir "%outDir%" 2>nul
if errorlevel 1 (
    echo 创建输出目录失败，请检查写入权限。
    pause
    exit /b 1
)

"%payload-dumper-goPath%" -old "%OLD_DIR%" -o "%outDir%" "%INC_PAYLOAD%"

if errorlevel 1 (
    echo.
    echo [错误] 合成失败！基础包与增量包不匹配，或者基础包被精简/混刷过。
    if defined outDir rmdir /s /q "%outDir%" 2>nul
    if defined ZIP_TMP rmdir /s /q "%ZIP_TMP%" 2>nul
    pause
    exit /b 1
)

if defined ZIP_TMP rmdir /s /q "%ZIP_TMP%" 2>nul

echo.
echo ========================================================
echo [成功] 新包已生成到: %outDir%
echo ========================================================
explorer "%outDir%"
pause
exit /b 0