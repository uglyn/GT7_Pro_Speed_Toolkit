@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%payloadp%" "cls"

call "%modulesDir%logger.bat" "%~nx0"  "获取基础包img来源"
call "%modulesDir%choose_source.bat" "OLD_DIR" "OLD_LIST" "解压好的基础包.img"  || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "获取OTA 增量包"
call "%modulesDir%choose_file.bat" "INC_FILE" "增量包 payload.bin 或 zip"  || exit /b 1

:gen_dir
set "outDir=%pd0Dir%patched_%random%"
if exist "%outDir%" goto gen_dir
mkdir "%outDir%" 2>nul

call "%modulesDir%usertimeout.bat" "基础包目录 !OLD_DIR!" "增量包路径 !INC_FILE!" "输出目录   !outDir!"
cls
echo.
echo.
echo.

echo(%payloadp%  -old  !OLD_DIR!  -o  %outDir%   %INC_FILE% 
"%payloadp%" -old "!OLD_DIR!" -o "%outDir%" "%INC_FILE%"
if errorlevel 1 (
    echo.
    echo(合成失败 基础包与增量包不匹配 或者基础包被精简 混刷过
    if defined outDir rmdir /s /q "%outDir%" 2>nul
    goto exitb1
)

echo.
echo(========================================================
echo(合成成功 新包已生成到 !outDir!
echo.
echo( 只能官方的基础全量包+ota增量包合并[需要配套 ]      
echo.
echo( 测试功能 别拿来刷机
echo(========================================================
start "" "!outDir!"
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

