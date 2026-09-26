@echo off
setlocal enabledelayedexpansion

call "%modulesDir%header.bat" "%~nx0"  "fastboot" ""
set "imgDir=%~1"
set "flashListFile=%~2"
set "excludeFile=%~3"
set "isDynamic=%~4"
set "Slot="
if not "%activeSlot%"=="" set "Slot=_%activeSlot%"
set "failureList=%tempDir%failure_list.txt"
set "skippedList=%tempDir%skipped_list.txt"
set "filtered=%tempDir%filtered.txt"
if "%imgDir%"=="" goto param_error 
if "%flashListFile%"=="" goto param_error
if not exist "%flashListFile%" goto param_error
type nul > "%failureList%" 2>nul
type nul > "%skippedList%" 2>nul

set "cleanFlashList=%tempDir%clean_flash_list.txt"
set "cleanExclude=%tempDir%clean_exclude.txt"

type nul > "!cleanFlashList!"
for /f "usebackq delims=" %%A in ("%flashListFile%") do (
    set "line=%%A"
    set "line=!line: =!"
    set "line=!line:	=!"
    if not "!line!"=="" echo !line!>> "!cleanFlashList!"
)

copy "!cleanFlashList!" "%filtered%" >nul
if exist "%excludeFile%" (
    type nul > "!cleanExclude!"
    for /f "usebackq delims=" %%A in ("%excludeFile%") do (
        set "line=%%A"
        set "line=!line: =!"
        set "line=!line:	=!"
        if not "!line!"=="" echo !line!>> "!cleanExclude!"
    )
    echo 跳过的分区：
    type "!cleanExclude!"
    echo.
    echo ====== 排除列表 ====== >> "%logFile%"
    type "!cleanExclude!" >> "%logFile%"
    echo ====================== >> "%logFile%"

    for %%A in ("!cleanExclude!") do set "excludeSize=%%~zA"
    if not defined excludeSize set "excludeSize=0"
    if !excludeSize! GTR 0 (
        findstr /v /i /x /g:"!cleanExclude!" "!cleanFlashList!" > "%filtered%"
    )
    del "!cleanExclude!" 2>nul
)
del "!cleanFlashList!" 2>nul

echo ====== 过滤后列表 ====== >> "%logFile%"
type "%filtered%" >> "%logFile%"
echo. >> "%logFile%"
echo ========================== >> "%logFile%"

set "imgIndex=%tempDir%img_index.txt"
type nul > "!imgIndex!"
for /f "delims=" %%f in ('dir /s /b /a-d "%imgDir%\*.img" 2^>nul') do (
    for /f "tokens=1 delims=." %%A in ("%%~nf") do (
        echo %%A^|%%f>>"!imgIndex!"
    )
)

:start_flash
set "total=0"
for /f "usebackq delims=" %%i in ("%filtered%") do set /a total+=1
if "!total!"=="0" (
    call :log "警告：没有需要刷写的分区"
    echo  警告：没有需要刷写的分区
    del "%filtered%" 2>nul
    del "!imgIndex!" 2>nul
    exit /b 0
)

echo.
echo ----------------------------------------------------------------------------------
echo ---------------------------------------------------------------------------------- >> "%logFile%"
echo 需要刷写 !total! 个分区到槽位 %activeSlot%
call :log "需要刷写 !total! 个分区到槽位 %activeSlot%"
set "cur=0"
set "failure=0"
set "success=0"
set "skipped=0"
echo.

for /f "usebackq delims=" %%i in ("%filtered%") do (
    set /a cur+=1
    set "part=%%i"
    set "imgPath="
    set "skip=0"

    for /f "usebackq tokens=1,* delims=|" %%A in ("!imgIndex!") do (
        if /i "%%A"=="!part!" set "imgPath=%%B"
    )

    if exist "%imgDir%\IMAGES\!part!\" (
        for /f "delims=" %%F in ('dir /b /a-d "%imgDir%\IMAGES\!part!\*.img" 2^>nul') do (
            set "imgPath=%imgDir%\IMAGES\!part!\%%F"
        )
    )

    echo.
    echo. >> "%logFile%"
    echo ----------------------------------------------------------------------------------
    echo ---------------------------------------------------------------------------------- >> "%logFile%" 
    echo [!cur!/!total!]: 刷写!part!分区
    echo [!cur!/!total!]: 刷写!part!分区 >> "%logFile%" 
    if "!isDynamic!"=="1" (        
            "%fastbootPath%" delete-logical-partition "!part!_a-cow" 2>nul
            if errorlevel 1  call :log "删除 !part!_a-cow失败（可能不存在），继续..."
            "%fastbootPath%" delete-logical-partition  "!part!_b-cow"  2>nul 
            if errorlevel 1  call :log "删除 !part!_b-cow失败（可能不存在），继续..."
            if  "%activeSlot%"=="" goto flash
            "%fastbootPath%" create-logical-partition "!part!!Slot!" 4096 2>nul
            if errorlevel 1 call :log "修复创建分区:!part!!Slot!失败（可能已存在），继续...  "     
    )  
    :flash
    if not defined imgPath (
    if defined imagesDir (
        if exist "%imagesDir%system\!part!.img" (
            set "imgPath=%imagesDir%system\!part!.img"
            echo 启用备用文件: %imagesDir%system\!part!.img
            call :log "启用备用文件: %imagesDir%system\!part!.img"
        )
    )
)
if not defined imgPath (
    echo 缺失文件: !part!.img
    call :log "!part!.img 文件缺失，跳过刷写"
    echo 备用文件 %imagesDir%system\!part!.img 不存在，跳过刷写
    set /a skipped+=1
    echo !part! >> "%skippedList%"
    set "skip=1"
)
    if !skip! equ 0 (
         call :log "执行刷写: fastboot flash !part! !imgPath!"
         echo fastboot flash !part!!Slot! !imgPath!
        "%fastbootPath%" flash "!part!!Slot!" "!imgPath!"  
        if errorlevel 1 (
            set /a failure+=1
            echo 分区 !part! 刷写失败 
            call :log "刷写 !part!!Slot! 失败."
            echo !part! >> "%failureList%"
        ) else (
            set /a success+=1 
             set /a ing=!cur!*100/!total!
            echo !part! 刷写成功[ !ing!%%]
            call :log "刷写 !part!!Slot! 成功."
        )
    )
)
echo.
echo 总计处理: !cur! 个分区
echo 刷写成功: !success! 个
echo 刷写失败: !failure! 个

echo ====== 刷写汇总 ====== >> "%logFile%"
echo 总计处理: !cur! 个分区 >> "%logFile%"
echo 刷写成功: !success! 个 >> "%logFile%"
echo 刷写失败: !failure! 个 >> "%logFile%"
echo ====================== >> "%logFile%"

if exist "%failureList%" (
    echo 失败分区列表：
    type "%failureList%"
    echo ====== 失败分区 ====== >> "%logFile%"
    type "%failureList%" >> "%logFile%"
    echo ========================== >> "%logFile%"
)
echo 跳过（镜像不存在）: !skipped! 个
if exist "%skippedList%" (
    echo 跳过分区列表：
    type "%skippedList%"
    echo ====== 跳过分区 ====== >> "%logFile%"
    type "%skippedList%" >> "%logFile%"
    echo ========================== >> "%logFile%"
)
echo.
echo 注意: 个别分区失败，可考虑手动补刷。
echo 文件缺失如果无法开机请禁用vb2.0或者补刷 [具体看日志文件"%logFile%"]
echo ============================================
del "%filtered%" 2>nul
del "!imgIndex!" 2>nul
timeout /t 5
exit /b 0
:param_error
echo %~nx0脚本参数错误。
pause
exit /b 1
:log
echo %time% %~1 >> "%logFile%"
goto :eof