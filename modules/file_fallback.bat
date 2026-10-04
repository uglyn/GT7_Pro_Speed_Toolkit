@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

if "%~1"=="" (
    echo 错误 请指定要查找的文件名！
    pause
    exit /b 1
)
if "%~2"=="" (
    echo [错误] 请指定接收路径的变量名！
    pause
    exit /b 1
)

set "targetFile=%~1"
set "retVar=%~2"
set "foundPath="

rem ====== 拼接要查找的固定目录 ======
set "searchDirs=%imagesDir%system;%imagesDir%super"

if not "!searchDirs!"=="!searchDirs: =!" (
    echo.
    echo  发现路径中包含空格！
    echo 有问题的路径: !searchDirs!
    echo 请将相关文件夹重命名，去掉空格后再运行。
    echo.
    call :log " 错误 路径包含空格，已退出: !searchDirs!"
    pause
    exit /b 1
)


set searchDirs="!searchDirs:;=" "!"

for %%D in (!searchDirs!) do (
    if exist "%%~D\!targetFile!" (
        set "foundPath=%%~D\!targetFile!"
        echo  !targetFile! 已经启用内置文件
        call :log "已经启用内置文件: !targetFile!"
    )
)

endlocal & set "%retVar%=%foundPath%"
timeout /t 2 
exit /b 0

:log
echo     %time% %~1 >> "%logFile%"
goto :eof