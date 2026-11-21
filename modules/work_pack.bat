@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

set "currentProj=%~1"
set "currentProjName=%~2"
if "!currentProj!"=="" exit /b 1

:menu_pack
if %currentProj%=="qq11066851" (
:timeout
call "%modulesDir%logger.bat" "%~nx0" "输入不合法:!ch!"
call "%modulesDir%usertimeout.bat" "输入不合法:!ch!" 
)
cls
echo.
echo ================== 打包[ 文件夹: !currentProjName! ] ==================
echo.
set "dirCount=0"
:: 遍历当前工程下的文件夹，排除 config
for /d %%d in ("!currentProj!\*") do (
    if /i not "%%~nxd"=="config" (
        set /a dirCount+=1
        set "dirName[!dirCount!]=%%~nxd"
        echo   !dirCount!. %%~nxd
    )
)

echo.
echo   [G]. 前往解包
echo   [B]. 返回上一级
echo   [H]. 返回主菜单
echo ==================================================
set "ch=qq11066851"
set /p "ch=请输入序号或字母: "
echo.
set "ch=%ch:"=%"
if /i "!ch!"=="qq11066851" goto timeout
if /i "!ch!"==""   goto timeout
if /i "!ch!"=="G" exit /b 20
if /i "!ch!"=="B" exit /b 0
if /i "!ch!"=="H" exit /b 99

:: 输入必须为纯数字
for /f "delims=0123456789" %%a in ("!ch!") do goto timeout

:: 序号必须存在
if not defined dirName[!ch!] goto timeout

:: 查表取值
set "selectedDir=!dirName[%ch%]!"

:: 设置全局变量，进入打包逻辑
set "targetDirPath=!currentProj!\!selectedDir!"
set "targetDirName=!selectedDir!"
goto do_pack


:: =========================================================
:: 核心打包逻辑
:: =========================================================
:do_pack
set "outImg=!currentProj!\!targetDirName!_new.img"
set "formatFile=!currentProj!\config\!targetDirName!.txt"

echo.
echo 正在准备打包: !targetDirName!

:: 1. 默认值（packSize 只做参考，不参与打包）
set "packType=EROFS"
set "packSize="

:: 2. 从 config 文件提取格式和大小
if exist "!formatFile!" (
    findstr /i "EROFS" "!formatFile!" >nul
    if not errorlevel 1 set "packType=EROFS"
    
    findstr /i "EXT4" "!formatFile!" >nul
    if not errorlevel 1 set "packType=EXT4"

    for /f "usebackq tokens=1,2,3 delims=|" %%a in ("!formatFile!") do (
        if not "%%c"=="" ( set "tSize=%%c" ) else ( set "tSize=%%b" )
        set "tSize=!tSize: =!"
        if defined tSize set "packSize=!tSize!"
    )
)

:: 3. 强制同步最新 img 大小
if exist "!currentProj!\!targetDirName!.img" for %%F in ("!currentProj!\!targetDirName!.img") do set "packSize=%%~zF"

:: 4. 指定 config 文件路径
set "fsCfg=!currentProj!\config\!targetDirName!_fs_config"
set "fileCtx=!currentProj!\config\!targetDirName!_file_contexts"

echo 目标格式: !packType!
echo 输出文件: !targetDirName!_new.img
echo.

:: 5. 纯 goto 分流
if /i "!packType!"=="EROFS" goto run_erofs
goto run_ext4


:run_erofs
echo 目标格式: EROFS
echo [提示] 屏幕会滚动处理进度，请耐心等待...
echo.

:: 【核心修改】保留 config 和 file-contexts 指定，去掉 --mount-point 参数，解决找不到路径的问题
mkfs.erofs -zlz4hc,0 -C65536 --fs-config-file="!fsCfg!" --file-contexts="!fileCtx!" "!outImg!" "!targetDirPath!"

if errorlevel 1 goto pack_fail
goto check_result

:run_ext4
echo.
echo [提示] 打包 EXT4
echo.
echo [参考] 原镜像大小: !packSize! 字节 请输入比原大小大30 50M
echo.

:ext4_input_size
set "inputSize="
set /p "inputSize=请输入打包大小(纯字节数，必填): "

if defined inputSize set "inputSize=!inputSize: =!"

if not defined inputSize (
    echo.
    echo [错误] 未输入打包大小，已取消。
    call "%modulesDir%logger.bat" "%~nx0" "EXT4 打包取消:未指定大小"
    goto menu_pack
)

:ext4_input_done

:: 绝对路径用于生成文件和最终重命名
set "tempImg=!currentProj!\!targetDirName!_temp.img"
set "outImg=!currentProj!\!targetDirName!_new.img"

if exist "!tempImg!" del /f /q "!tempImg!" >nul 2>&1

echo.
echo 1/3 正在创建临时空壳镜像...
fsutil file createnew "!tempImg!" !inputSize! >nul
if errorlevel 1 goto pack_fail

echo.
echo 2/3 正在格式化 EXT4 文件系统...
"%mke2fsp%" -t ext4 -b 4096 -F "!tempImg!"
if errorlevel 1 goto pack_fail

echo.
echo 3/3 正在写入文件并恢复权限...
ping 127.0.0.1 -n 2 >nul

:: 【核心绝杀】只在 e2fsdroid 传参时，现场拼出相对路径（去掉盘符）
if not defined e2fsdroidp set "e2fsdroidp=e2fsdroid"
"!e2fsdroidp!" -e -T 1167580800 -S "work\!currentProjName!\config\!targetDirName!_file_contexts" -C "work\!currentProjName!\config\!targetDirName!_fs_config" -f "work\!currentProjName!\!targetDirName!" -a /!targetDirName! "work\!currentProjName!\!targetDirName!_temp.img"

if errorlevel 1 goto pack_fail

echo.
echo 正在生成最终文件...
if exist "!outImg!" del /f /q "!outImg!" >nul 2>&1
move /y "!tempImg!" "!outImg!" >nul
goto check_result

:check_result
echo.
echo ==================================================
echo [成功] 打包完成！
echo 生成文件: !targetDirName!_new.img
echo ==================================================
call "%modulesDir%logger.bat" "%~nx0" "打包成功:!targetDirName! 格式:!packType!"
pause
goto menu_pack

:pack_fail
echo.
echo [错误] 打包失败！请输入比原大小大30 50M 正在清理临时文件...
:: 【关键点】只要出错，立刻删掉半残的临时镜像，绝不留下祸害
if exist "!tempImg!" del /f /q "!tempImg!" >nul 2>&1
:: 保险起见，把正式文件也扫掉（防止有旧版本的废包）
if exist "!outImg!" del /f /q "!outImg!" >nul 2>&1
call "%modulesDir%logger.bat" "%~nx0" "打包失败:!targetDirName!"
pause
goto menu_pack