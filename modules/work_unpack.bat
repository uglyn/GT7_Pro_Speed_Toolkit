@echo off
chcp 936 >nul
setlocal enabledelayedexpansion

:: =========================================================
:: 0. 运行库环境检测
:: =========================================================
if not exist "%SystemRoot%\System32\vcruntime140.dll" (
    cls
    echo ===========================================================
    echo [错误] 您的电脑缺少必要的运行环境！
    echo 缺少文件: vcruntime140.dll
    echo.
    echo 解压工具需要 Microsoft Visual C++ 2015-2022 运行库支持。
    echo 请去微软官网下载安装 x64 版本的运行库后，再运行本工具。
    echo.
    echo 官方下载地址：https://aka.ms/vs/17/release/vc_redist.x64.exe
    echo ===========================================================
    echo.
    pause
    exit /b 1
)

:: =========================================================
:: 1. 初始化与接收参数
:: =========================================================
call "%modulesDir%header.bat" "%~nx0" 
set "currentProj=%~1"
set "currentProjName=%~2"
if "!currentProj!"=="" exit /b 1

:menu_unpack
if %currentProj%=="qq11066851" (
:timeout
call "%modulesDir%logger.bat" "%~nx0" "输入不合法:!ch!"
call "%modulesDir%usertimeout.bat" "输入不合法:!ch!" 
)
cls
echo.
echo(--------------解包镜像[ 项目:!currentProjName! ]----------------
echo.
set "imgCount=0"
echo   可解压的img:
echo(---------------
for %%f in ("!currentProj!\*.img") do (
    set /a imgCount+=1
    set "imgName[!imgCount!]=%%~nxf"
    set "imgPath[!imgCount!]=%%f"
    echo(   !imgCount!. %%~nxf
)

echo.
echo(----菜单: 
echo.
echo(   [A]. 添加img文件
echo(   [G]. 前往打包
echo(   [B]. 返回上层
echo(   [H]. 返回首页
echo(--------------------------------------------------------
set "ch=qq11066851"
set /p "ch=请输入序号或字母: "
echo.
set "ch=%ch:"=%"
if "!ch!"=="qq11066851" goto timeout
if "!ch!"=="" goto timeout
if /i "!ch!"=="A" goto add_img
if /i "!ch!"=="G" exit /b 20
if /i "!ch!"=="B" exit /b 0
if /i "!ch!"=="H" exit /b 99

:: 输入必须为纯数字
for /f "delims=0123456789" %%a in ("!ch!") do goto timeout

:: 序号必须存在
if not defined imgName[!ch!] goto timeout

:: 查表取值
set "selectedImg=!imgName[%ch%]!"
set "targetImgFile=!imgPath[%ch%]!"
set "targetImgName=!selectedImg!"
set "currPartName=!targetImgName:~0,-4!"


:: =========================================================
:: 核心解压逻辑（直接解压到工程目录）
:: =========================================================
echo.
echo 正在处理: !targetImgName!

:: 【安全锁】检查要覆盖的文件夹
if not "!currPartName!"=="" (
    if exist "!currentProj!\!currPartName!\" (
        echo.
        echo [警告] 文件夹 !currPartName! 已存在！
        choice /c YN /m "是否删除旧文件并覆盖"
        if errorlevel 2 (
            echo 已取消解压。
            timeout /t 2 >nul
            goto menu_unpack
        )
        echo 正在清理旧文件夹...
        rd /s /q "!currentProj!\!currPartName!" 2>nul
    )
)

:: 尝试 Sparse 脱壳
set "finalImg=!targetImgFile!"
set "rawTmp=!currentProj!\tmp_raw.img"
"%simg2imgp%" "!targetImgFile!" "!rawTmp!" 2>nul
if not errorlevel 1 set "finalImg=!rawTmp!"

:: 瞬间检测格式
set "imgFormat=EXT4"
dump.erofs.exe -s "!finalImg!" >nul 2>&1
if not errorlevel 1 set "imgFormat=EROFS"

echo 检测到文件系统格式: !imgFormat!

:: 初始化错误码，防止空值报错
set "scuti_err=1"

:: 【直接解压到工程目录】
if "!imgFormat!"=="EROFS" (
    echo 正在调用 extract.erofs 解压...
    set "execName=!targetImgName!"
    if "!finalImg!"=="!rawTmp!" set "execName=tmp_raw.img"
    
    :: 记录当前位置，临时进去项目目录解压（不给 -o 参数），解压完退回
    set "old_cd=%cd%"
    cd /d "!currentProj!"
    "%exerofsp%" -x -i "!execName!" <nul
    set "scuti_err=!errorlevel!"
    cd /d "!old_cd!"
)

if "!imgFormat!"=="EXT4" (
    echo 正在调用 ImgKit-Scuti 解压 EXT4...
    "%scutip%" unpack -i "!finalImg!" -o "!currentProj!" <nul
    set "scuti_err=!errorlevel!"
)


:: =========================================================
:: 统一结果判断
:: =========================================================
:check_result
echo 返回码!scuti_err!
if !scuti_err! neq 0 (
    echo.
    echo [错误] 解压失败！ 错误码: !scuti_err! 
    pause
    echo 请检查文件是否损坏，或工具参数是否正确。
    call "%modulesDir%logger.bat" "%~nx0"  "解压失败:!currentProjName!"
    if exist "!rawTmp!" del /f /q "!rawTmp!" 2>nul
    :: 清理失败留下的一半的垃圾文件夹
    if not "!currPartName!"=="" (
        if exist "!currentProj!\!currPartName!\" rd /s /q "!currentProj!\!currPartName!" 2>nul
    )
    call "%modulesDir%usertimeout.bat" "%~nx0"
    exit /b 0
)

:: =========================================================
:: 成功逻辑
:: =========================================================
for %%F in ("!targetImgFile!") do set "origSize=%%~zF"

:: 写入大小记录文件
if not exist "!currentProj!\config" mkdir "!currentProj!\config"
set "formatFile=!currentProj!\config\!currPartName!.txt"

set "cleanType=!imgFormat: =!"
set "cleanSize=!origSize: =!"

> "!formatFile!" echo !cleanType!^|!cleanSize!

if exist "!rawTmp!" del /f /q "!rawTmp!" 2>nul

echo.
echo ==================================================
echo [成功] 解压完成！
echo 目录: !currentProjName!
echo ==================================================
call "%modulesDir%logger.bat" "%~nx0" "解压成功:!currentProjName! 格式:!imgFormat!"
call "%modulesDir%usertimeout.bat" "%~nx0"
goto menu_unpack


:: =========================================================
:: 添加镜像分支
:: =========================================================
:add_img
echo.
call "%modulesDir%choose_file.bat" "srcImg" "镜像文件 (*.img)"
set "srcImg=!srcImg:"=!"
if errorlevel 1 goto menu_unpack

if exist "!srcImg!" (
    echo 正在复制到工程目录...
    copy /y "!srcImg!" "!currentProj!\" >nul
    echo [成功] 已添加！
    call "%modulesDir%logger.bat" "%~nx0" "添加镜像:!srcImg!"
    call "%modulesDir%usertimeout.bat" 
)
goto menu_unpack