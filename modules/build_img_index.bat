@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""
rem 目录1 字典名字2 需要哪些文件3
if "%~1"=="" goto exitb1
if "%~2"=="" goto exitb1
if "%~3"=="" goto exitb1
set "rootDir=%~1"
set "retVar=%~2"
set "partCfg=%~3"

set "imgIndex=%tempDir%img_index.txt"
type nul > "!imgIndex!" 2>nul

rem ============================================================
rem 一次性遍历分区，主目录找不到直接去备用目录找
rem ============================================================
for /f "usebackq delims=" %%P in ("!partCfg!") do (
    set "part=%%P"
    set "part=!part: =!"
    set "part=!part:	=!"

    if not "!part!"=="" (
        set "foundPath="

        rem 1. 主目录搜索
        if exist "!rootDir!\images" (
            for /f "delims=" %%F in ('dir /s /b /a-d "!rootDir!\!part!.img" 2^>nul') do (
                set "foundPath=%%F"
            )
            if exist "!rootDir!\images\!part!\" (
                for /f "delims=" %%F in ('dir /b /a-d "!rootDir!\images\!part!\*.img" 2^>nul') do (
                    set "foundPath=!rootDir!\images\!part!\%%F"
                )
            )
        ) else (
            if exist "!rootDir!\!part!.img" (
                set "foundPath=!rootDir!\!part!.img"
            )
        )

        rem 2. 如果主目录没找到，立刻去内置备用目录（system / super）找
        if not defined foundPath (
            for %%D in (system super) do (
                if exist "!imagesDir!%%D\!part!.img" (
                    set "foundPath=!imagesDir!%%D\!part!.img"
                    echo( !part!.img 已经启用内置文件
                    call "%modulesDir%logger.bat" "%~nx0"  "已经启用内置文件: !part!.img!"
                )
            )
        )

        rem 3. 最终找到的写入索引
        if defined foundPath (
            echo(!part!^|!foundPath!>>"!imgIndex!"
        )
    )
)

call "%modulesDir%logger.bat" "%~nx0"  "使用%imgIndex%"
call "%modulesDir%usertimeout.bat" "索引字典已生成%imgIndex%"
endlocal & set "%retVar%=%imgIndex%"
exit /b 0

:exitb1
echo(参数异常
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1