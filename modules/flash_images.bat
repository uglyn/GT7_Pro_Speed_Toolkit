@echo off
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0"  "fastboot" "cls"  

set "imgDir=%~1"
set "flashListFile=%~2"
set "excludeFile=%~3"
set "isDynamic=%~4"
set "extraParam="
set "Slot="
if not "%activeSlot%"=="" set "Slot=_%activeSlot%"
if "!isDynamic!"=="2" set "extraParam=--disable-verity --disable-verification"


set "filed=%tempDir%filed.txt"
type nul > "!filed!" 2>nul

set "failureList=%tempDir%failure_list.txt"
del "!failureList!" 2>nul

set "skippedList=%tempDir%skipped_list.txt"
del "!skippedList!" 2>nul


if not exist "%imgDir%"=="" goto param_error
if not exist "%flashListFile%" goto param_error

set "flashListFile2=%tempDir%flashListFile2.txt"
type nul > "!flashListFile2!" 2>nul

for /f "usebackq delims=" %%A in ("!flashListFile!") do (
    set "line=%%A"
    set "line=!line: =!"
    set "line=!line:	=!"
    if not "!line!"=="" echo !line!>> "!flashListFile2!"
)

copy "!flashListFile2!" "!filed!" >nul

if   exist "!excludeFile!" (
call :log "!excludeFile!空白跳转start"
for %%A in ("!excludeFile!") do if %%~zA equ 0 goto start

set "excludeFile2=%tempDir%excludeFile2.txt"
type nul > "!excludeFile2!" 2>nul

for /f "usebackq delims=" %%A in ("!excludeFile!") do (
    set "line=%%A"
    set "line=!line: =!"
    set "line=!line:	=!"
    if not "!line!"=="" echo !line!>> "!excludeFile2!"
)
cls
echo.
echo.
echo.
echo 跳过的分区：
type "!excludeFile2!"
echo 跳过的分区： >> "%logFile%"
type "!excludeFile!" >> "%logFile%"
echo  !flashListFile2!
echo  !excludeFile2!
echo  !filed!
findstr /v /i /x /g:"!excludeFile2!" "!flashListFile2!">"!filed!"
echo 过滤后的分区: >> "%logFile%"
type "!filed!" >> "%logFile%"
echo 过滤后的分区:
type "!filed!"
del "!excludeFile2!" 2>nul

)
:start
del "!flashListFile2!" 2>nul
set "imgIndex=%tempDir%img_index.txt"
type nul > "%imgIndex%"

for /f "delims=" %%f in ('dir /s /b /a-d "%imgDir%\*.img" 2^>nul') do (
  for /f "tokens=1 delims=." %%A in ("%%~nf") do (
    echo %%A^|%%f>>"!imgIndex!"
  )
)


:start_flash
set "total=0"
for /f "usebackq delims=" %%i in ("!filed!") do set /a total+=1

if "!total!"=="0" (
  call :log "警告：没有需要刷写的分区"
  echo  警告：没有需要刷写的分区
  goto error
)

echo.
cls
if "!isDynamic!"=="0" echo 正在刷写物理分区
if "!isDynamic!"=="1" echo 正在刷写super分区
if "!isDynamic!"=="2" echo 正在禁用开机校验
if "!isDynamic!"=="3" echo 正在刷写特殊分区
echo.
echo 共计刷写 !total! 个分区到卡槽:%activeSlot%
call :log "需要刷写 !total! 个分区到槽位 %activeSlot%"
timeout /t 1
set "cur=0"
set "failure=0"
set "success=0"
set "skipped=0"

for /f "usebackq delims=" %%i in ("%filed%") do (
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
  call :log "echo."
  echo [!cur!/!total!]: 刷写!part!分区 文件:!imgPath!
  echo [!cur!/!total!]: 刷写!part!分区 >> "%logFile%"
  if "!isDynamic!"=="1" (
    "%fastbootPath%" delete-logical-partition "!part!_a-cow" 2>nul
    if errorlevel 1  call :log "删除 !part!_a-cow失败（可能不存在），继续..."
    "%fastbootPath%" delete-logical-partition  "!part!_b-cow"  2>nul
    if errorlevel 1  call :log "删除 !part!_b-cow失败（可能不存在），继续..."
    if not "%activeSlot%"=="" (
      "%fastbootPath%" create-logical-partition "!part!!Slot!" 4096 2>nul
      if errorlevel 1 call :log "修复创建分区:!part!!Slot!失败（可能已存在），继续..."
    )
  )

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
    call :log "执行刷写:  %fastbootp% !extraParam! flash !part!!Slot! !imgPath!"
    echo %fastbootp% !extraParam! flash !part!!Slot! !imgPath!
    "%fastbootp%" !extraParam! flash "!part!!Slot!" "!imgPath!"
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
echo 总计处理: !cur! 个分区 >> "%logFile%"
echo 刷写成功: !success! 个 >> "%logFile%"
echo 刷写失败: !failure! 个 >> "%logFile%"

if exist "%failureList%" (
  echo 失败分区列表：
  type "%failureList%"
  echo  失败分区:>> "%logFile%"
  type "%failureList%" >> "%logFile%"
)

if exist "%skippedList%" (
  echo 跳过（镜像不存在）: !skipped! 个
  type "%skippedList%"
  echo 跳过分区: >> "%logFile%"
  type "%skippedList%" >> "%logFile%"
)
echo.
echo 注意: 个别分区失败，可考虑手动补刷。  [具体看日志文件"%logFile%"]
echo.
del "%filed%" 2>nul
del "%failureList%" 2>nul
del "%skippedList%" 2>nul
del "%imgIndex%" 2>nul
timeout /t 5
exit /b 0

:error
echo %~nx0脚本参数错误。
pause
exit /b 1

:log
echo %time% %~1 >> "%logFile%"
goto :eof