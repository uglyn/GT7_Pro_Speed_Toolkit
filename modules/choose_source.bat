@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

if not "%~1"=="" if not "%~2"=="" goto params_ok
echo(用法：参数 [目录变量] [目录文件列表] [文件类型]
goto exitb1

:params_ok
set "_outVarDir=%~1"
set "_outVarList=%~2"

echo.
call "%modulesDir%logger.bat" "%~nx0"  "拦截手速"
choice /c x /n /t 1 /d x /m " 正在继续....  丢失焦点会卡住 请手动按 x 继续...."

:choose_loop
if "%_outVarDir%"=="qq11066851"   (
:timeout
echo(   *******请拖入文件夹呀******** 
call "%modulesDir%logger.bat" "%~nx0"  "请输入[拖入] 正确的文件夹路径:%userDir%"
call "%modulesDir%usertimeout.bat" "%userDir%"
)
cls
echo.
echo.
echo(     -----------------------拖入 [%~3] 文件夹--------------------------------
echo.
echo(       [1] win11 如果无法拖入 请先复制%~3 [文件夹]
echo.
echo(       [2]然后按shift  在cmd窗口右键粘贴[文件夹]路径 
echo.
echo(       [3]不要拖入奇奇怪怪的文件夹 只支持 %~3 [文件夹]
echo.
echo(       [4]卡刷包:文件夹里只有.img文件 线刷包:有images,meta[文件夹]
echo.
echo(       [5] 解压卡刷包.zip得 卡刷包.img[文件夹] 可解压payload.bin 或 卡刷包.zip
echo(      -----------------------------------------------------------------------------
set "userDir=qq11066851"
set /p "userDir=请拖入%~3 [文件夹] 路径[之后按回车键]: "
echo.
set "userDir=%userDir:"=%"
if "%userDir%"=="" goto timeout
if not "%userDir:~1,1%"==":" goto timeout
if not exist "%userDir%"  goto timeout

if /i "%userDir:~-4%"==".lnk" (
	echo(   *******不支持快捷方式******** 
                call "%modulesDir%logger.bat" "%~nx0"  "不支持快捷方式:%userDir%"
                goto timeout
)

rem 3. 提取属性，判断是否为文件夹
set "attr="
for %%I in ("!userDir!") do set "attr=%%~aI"
if /i not "!attr:~0,1!"=="d" (
    echo(   *******请不要拖入文件********
    call "%modulesDir%logger.bat" "%~nx0"  "!userDir! 请不要拖入文件!"
    goto timeout
)
rem ========== 检查 payload.bin ==========
if exist "%userDir%\payload.bin" (
    echo(--------------------------------------------------------------------------------------
    echo.
    echo([提示] 检测到文件夹中存在 payload.bin 文件。
    echo.
    echo(请先使用功能6 解压 卡刷包.zip 得到包含 .img文件的 [文件夹]后 再拖入本脚本。
    echo.
    echo(本脚本需要自己解压payload.bin 后使用 或者别人分享只包含img文件的刷机包
    echo.
    goto exitb1
)

:start
set "fileList=%tempDir%filelist_sorted.txt"
type nul > "%fileList%" 2>nul
set "ab_partitions="

:: --- 1. 线刷包处理 ---
if exist "%userDir%\IMAGES" (
    if not exist "%userDir%\META\ab_partitions.txt" (
        echo([错误] 检测到 IMAGES 文件夹，但缺少 META\ab_partitions.txt 
        echo(脚本不认识的线刷包，刷机终止.
        echo(如果是卡刷包直接选择.img所在的文件夹
        call "%modulesDir%logger.bat" "%~nx0"  "线刷包缺失 ab_partitions.txt"
        goto exitb1
    )
    set "ab_partitions=%userDir%\META\ab_partitions.txt"
    copy "%ab_partitions%" "%fileList%" >nul
    call "%modulesDir%logger.bat" "%~nx0"  "线刷包根目录确认: %userDir%"
)

rem ========== 线刷包后面，卡刷包前面，检测 bin/xml ==========
if "%ab_partitions%"=="" (
    dir /b /a-d "%userDir%\*.bin" "%userDir%\*.xml" >nul 2>nul
    if not errorlevel 1 (
        echo(如果是线刷包 请拖入 images文件夹的上一级目录 
        echo(解压卡刷包.zip   得到img 散包文件夹
        call "%modulesDir%logger.bat" "%~nx0"  "检测到 .bin 或 .xml 文件，异常退出"
        goto exitb1
    )
)

:: --- 2. 卡刷包处理 ---
if "%ab_partitions%"=="" (
    for /f "delims=" %%i in ('dir /b /o:s "%userDir%\*.img" 2^>nul') do (
        >> "%fileList%" echo(%%~ni
    )
)

:: --- 3. 【合并逻辑】一边统计，一边打印详情 ---
set "itemCount=0"
echo(====== 文件详情 ====== >> "%logFile%"

for /f "usebackq delims=" %%A in ("%fileList%") do (
    set "part=%%A"
    set "part=!part: =!"
    set "part=!part:	=!"
    if not "!part!"=="" (
        set /a itemCount+=1
        set "found=0"
        for /f "delims=" %%F in ('dir /s /b /a-d "%userDir%\!part!.img" 2^>nul') do (
            echo(!part!.img  %%~zF 字节  [%%~dpF]
            >> "%logFile%" echo(!part!.img  %%~zF 字节  [%%~dpF]
            set "found=1"
        )
        if "!found!"=="0" (
            echo(!part!.img  [缺失]
            echo(!part!.img  [缺失] >> "%logFile%"
        )
    )
)

:: --- 4. 最终判断 ---
if !itemCount! equ 0 (
    echo(错误：在 %userDir% 中没有有效的.img 文件
    echo(如果是卡刷包 请拖入带.img文件的文件夹 没有.bin或.xml文件
    echo(卡刷包.zip解压之后得到payload.bin 功能6解压payload.bin
    goto exitb1
)

echo(找到 !itemCount! 个条目。
call "%modulesDir%logger.bat" "%~nx0"  "条目总数: !itemCount!"

echo.
echo.
echo(已使用文件夹: "%userDir%"      文件列表: "%fileList%"
echo.

endlocal & set "%_outVarDir%=%userDir%" & set "%_outVarList%=%fileList%"
call "%modulesDir%usertimeout.bat"
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

