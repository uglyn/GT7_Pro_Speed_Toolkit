@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

if "%~1"=="" goto exitb1
if "%~2"=="" goto exitb1
if "%~3"=="" goto exitb1
set "rootDir=%~1"
set "retVar=%~2"
set "partCfg=%~3"

set "imgIndex=%tempDir%img_index.txt"
type nul > "!imgIndex!" 2>nul

set "missingFile=%tempDir%missing_list.txt"
type nul > "!missingFile!" 2>nul

rem ============================================================
rem 第一遍：遍历分区，线刷包/卡刷包分别搜主目录
rem          找到的写索引，没找到的记进 missingFile
rem ============================================================
for /f "usebackq delims=" %%P in ("!partCfg!") do (
    set "part=%%P"
    set "part=!part: =!"
    set "part=!part:	=!"

    if not "!part!"=="" (
        set "foundPath="

        rem 线刷包：有 images 目录
        if exist "!rootDir!\images" (
            for /f "delims=" %%F in ('dir /s /b /a-d "!rootDir!\!part!.img" 2^>nul') do (
                set "foundPath=%%F"
            )
            if exist "!rootDir!\images\!part!\" (
                for /f "delims=" %%F in ('dir /b /a-d "!rootDir!\images\!part!\*.img" 2^>nul') do (
                    set "foundPath=!rootDir!\images\!part!\%%F"
                )
            )
        )

        rem 卡刷包：没有 images 目录
        if not exist "!rootDir!\images" (
            if exist "!rootDir!\!part!.img" (
                set "foundPath=!rootDir!\!part!.img"
            )
        )

        rem 主目录找到的写索引，没找到的进缺失列表
        if defined foundPath (
            echo(!part!^|!foundPath!>>"!imgIndex!"
        ) else (
            echo(!part!>>"!missingFile!"
        )
    )
)

rem ============================================================
rem 第二遍：对第一遍没找到的分区，统一去备用目录查一次
rem ============================================================
if exist "!missingFile!" (
    for /f "usebackq delims=" %%P in ("!missingFile!") do (
        set "part=%%P"
        call "%modulesDir%file_fallback.bat" "!part!.img" "fallbackPath"
        if defined fallbackPath (
            echo(!part!^|!fallbackPath!>>"!imgIndex!"
        )
    )
    if defined missingFile if exist "!missingFile!" del "!missingFile!" 2>nul
)

echo(索引字典已生成%imgIndex%
endlocal & set "%retVar%=%imgIndex%"
call "%modulesDir%logger.bat" "%~nx0"  "使用%imgIndex%"
call "%modulesDir%usertimeout.bat"
exit /b 0

:exitb1
echo(参数异常
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1