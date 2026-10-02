@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
call "%modulesDir%header.bat" "%~nx0" "%payloadp%" "cls"

call :log "获取基础包img来源"
call "%modulesDir%choose_source.bat" "OLD_DIR" "OLD_LIST" " 解压好的基础包.img"  || exit /b 1

call :log "获取OTA 增量包"
call "%modulesDir%choose_file.bat" "INC_FILE" "增量包 payload.bin 或 zip"  || exit /b 1

:gen_dir
set "outDir=%pd0Dir%patched_%random%"
if exist "%outDir%" goto gen_dir

cls
echo.
echo.
echo.
echo 基础包目录 !OLD_DIR!
echo 增量包路径 !INC_FILE!
echo 输出目录   !outDir!
echo -----------------------------------------------------------------------
echo.
echo 正在合成新包 请稍候...
echo.
timeout /t 4
cls
echo.
echo.
echo.
mkdir "%outDir%" 2>nul
if errorlevel 1 (
    echo 创建输出目录失败 请检查写入权限
    pause
    exit /b 1
)

"%payloadp%" -old "!OLD_DIR!" -o "%outDir%" "%INC_FILE%"

if errorlevel 1 (
    echo.
    echo 合成失败 基础包与增量包不匹配 或者基础包被精简 混刷过
    if defined outDir rmdir /s /q "%outDir%" 2>nul
    pause
    exit /b 1
)

echo.
echo ========================================================
echo 合成成功 新包已生成到 !outDir!
echo.
echo  只能官方的基础全量包+ota增量包合并[需要配套 ]      
echo.
echo  测试功能 别拿来刷机
echo ========================================================
start "" "!outDir!"
pause
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof
