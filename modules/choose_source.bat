@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

if not "%~1"=="" if not "%~2"=="" goto params_ok
echo 用法：参数 [目录变量] [目录文件列表] [文件类型]
exit /b 1

:params_ok
set "_outVarDir=%~1"
set "_outVarList=%~2"

echo.
call :log "拦截手速"
choice /c x /n /t 1 /d x /m " 正在继续....如果卡住 请按 x 继续"

:choose_loop
cls
echo.
echo.
echo      -----------------------拖入 [%~3] 文件夹--------------------------------
echo.
echo        [1] win11 如果无法拖入 请先复制%~3 [文件夹]
echo.
echo        [2]然后按shift  在cmd窗口右键粘贴文件夹路径 
echo.
echo        [3]不要拖入奇奇怪怪的文件夹 只支持 %~3 [文件夹]
echo.
echo        [4]卡刷包:文件夹里只有.img文件 线刷包:有images,meta文件夹
echo.
echo        [5] 解压卡刷包.zip得payload.bin  再功能6解压payload 得 [卡刷包.img文件夹]
echo       -----------------------------------------------------------------------------
set "sourceDir="
set /p "sourceDir=请输入%~3[文件夹]路径[之后按回车键]: "
set "sourceDir=!sourceDir:"=!"
if "!sourceDir!"=="" goto choose_loop
if not exist "!sourceDir!" goto choose_loop
if not exist "!sourceDir!\" goto choose_loop

rem ========== 新增：检查 payload.bin ==========
if exist "!sourceDir!\payload.bin" (
    echo --------------------------------------------------------------------------------------
    echo.
    echo [提示] 检测到文件夹中存在 payload.bin 文件。
    echo.
    echo 请先使用功能6 解压 payload.bin 得到包含 .img文件的 [文件夹]后 再拖入本脚本。
    echo.
    echo 本脚本需要自己解压payload.bin 后使用 或者别人分享只包含img文件的刷机包
    echo.
    pause
    exit /b 1
)
rem ========== 新增结束 ==========

:start
set "fileList="
if exist "!sourceDir!\IMAGES" (
    if not exist "!sourceDir!\META\ab_partitions.txt" (
        echo [错误] 检测到 IMAGES 文件夹，但缺少 META\ab_partitions.txt 
        echo 脚本不认识的线刷包，刷机终止.
        call :log "线刷包缺失 ab_partitions.txt"
        goto error
    )
    set "fileList=!sourceDir!\META\ab_partitions.txt"
    call :log "线刷包根目录确认: !sourceDir!"
)

rem ========== 线刷包后面，卡刷包前面，检测 bin/xml ==========
if "!fileList!"=="" (
    dir /b /a-d "!sourceDir!\*.bin" "!sourceDir!\*.xml" >nul 2>nul
    if not errorlevel 1 (
        echo 如果是线刷包 请拖入 images文件夹的上一级目录 
        call :log "检测到 .bin 或 .xml 文件，异常退出"
        goto error
    )
)

rem ========== 卡刷包处理 ==========
if "!fileList!"=="" (
    set "fileList=!tempDir!filelist_sorted.txt"
    type nul > "!fileList!" 2>nul
    for /f "delims=" %%i in ('dir /b /o:s "!sourceDir!\*.img" 2^>nul') do (
        echo %%~ni>> "!fileList!"
    )
)

set "itemCount=0"
for /f "usebackq delims=" %%A in ("!fileList!") do (
    set "p=%%A"
    set "p=!p: =!"
    set "p=!p:	=!"
    if not "!p!"=="" set /a itemCount+=1
)

if !itemCount! equ 0 (
    echo 错误：在 !sourceDir! 中没有有效的.img 文件
    echo 如果是卡刷包 请拖入带.img文件的文件夹 没有.bin或.xml文件
    echo 卡刷包.zip解压之后得到payload.bin 功能6解压payload.bin
    goto error
)

echo 找到 !itemCount! 个条目。
call :log "条目总数: !itemCount!"

echo ====== 文件详情 ====== >> "%logFile%"
for /f "usebackq delims=" %%A in ("!fileList!") do (
    set "part=%%A"
    set "part=!part: =!"
    set "part=!part:	=!"
    if not "!part!"=="" (
        set "found=0"
        for /f "delims=" %%F in ('dir /s /b /a-d "!sourceDir!\!part!.img" 2^>nul') do (
            echo !part!.img  %%~zF 字节  [%%~dpF]
            echo !part!.img  %%~zF 字节  [%%~dpF] >> "%logFile%"
            set "found=1"
        )
        if "!found!"=="0" (
            echo !part!.img  [缺失]
            echo !part!.img  [缺失] >> "%logFile%"
        )
    )
)
echo.
echo.
echo 已使用文件夹: !sourceDir!      文件列表: !fileList!
echo.
endlocal & set "%_outVarDir%=%sourceDir%" & set "%_outVarList%=%fileList%"
timeout /t 1	
exit /b 0

:error
pause
exit /b 1

:log
echo %time% %~1 >> "%logFile%"
goto :eof