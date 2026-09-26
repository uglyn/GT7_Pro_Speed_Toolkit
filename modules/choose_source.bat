@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
call "%modulesDir%header.bat" "%~nx0"  "" ""

if not "%~1"=="" if  not "%~2"=="" goto params_ok
echo 用法：参数 [目录变量] [目录文件列表] [文件类型]
exit /b 1

:params_ok
set "_outVarDir=%~1"
set "_outVarList=%~2"

:choose_loop
echo -----------------------------------------------------------------------------
echo [win11]请先复制%~3文件夹，按shift 然后在cmd窗口右键粘贴（或直接拖入文件）
echo.
echo 请将%~3文件夹拖入此处下方（或手动输入完整路径）
echo -----------------------------------------------------------------------------
set "sourceDir="
set /p "sourceDir=请输入%~3文件夹路径[之后按回车]: "
set "sourceDir=!sourceDir:"=!"
if not exist "!sourceDir!" (
    echo [提示] 输入为空或文件夹不存在，请重新选择。
    goto choose_loop
)

choice /c x /n /t 1 /d x /m "输入已接收，正在继续..."

set "fileList="
if exist "!sourceDir!\IMAGES" (
    if not exist "!sourceDir!\META\ab_partitions.txt" (
        echo [错误] 检测到 IMAGES 文件夹，但缺少 META\ab_partitions.txt 
        echo 脚本不认识的线刷包，刷机终止.
        call :log "线刷包缺失 ab_partitions.txt，拒绝执行"
        exit /b 1
    )
    set "fileList=!sourceDir!\META\ab_partitions.txt"
    echo [信息] 检测到线刷包根目录：!sourceDir!
    call :log "线刷包根目录确认: !sourceDir!"
)

if "!fileList!"=="" (
    set "fileList=!tempDir!filelist_sorted.txt"
    type nul > "!fileList!" 2>nul
    call :log "卡刷包列表: !fileList!"
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
    echo 错误：在 !sourceDir! 中没有找到任何 .img 文件
    exit /b 1
)

echo 找到 !itemCount! 个条目。
call :log "条目总数: !itemCount!"

echo. >> "%logFile%"
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
echo ================================= >> "%logFile%"
endlocal & set "%_outVarDir%=%sourceDir%" & set "%_outVarList%=%fileList%"
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof