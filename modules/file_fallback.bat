@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

if "%~1"=="" (
    echo(错误 请指定要查找的文件名！
    goto exitb1
)
if "%~2"=="" (
    echo([错误] 请指定接收路径的变量名！
    goto exitb1
)

set "targetFile=%~1"
set "retVar=%~2"
set "foundPath="

rem 这里写了 system 和 super，以后要加 vendor 直接在后面加空格 vendor 即可
for %%D in (system super) do (
    if exist "!imagesDir!%%D\!targetFile!" (
        set "foundPath=!imagesDir!%%D\!targetFile!"
        echo( !targetFile! 已经启用内置文件
        call "%modulesDir%logger.bat" "%~nx0"  "已经启用内置文件: !targetFile!"
        goto :found_done
    )
)

:found_done
:: 无论找没找到，都安全返回结果
endlocal & set "%retVar%=%foundPath%"
timeout /t 2
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

