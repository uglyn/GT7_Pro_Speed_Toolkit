@echo off
chcp 936 >nul
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

call :log "调用 build_img_index 建立索引，根目录: %imgDir%"
call "%modulesDir%build_img_index.bat" "%imgDir%" "imgIndex" "!filed!"


:start_flash
rem ===== 【新增】一次性读取索引，生成变量 =====
for /f "usebackq tokens=1,* delims=|" %%A in ("!imgIndex!") do (
    set "idx_%%A=%%B"
)
rem ==========================================

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

  rem ===== 【修改】直接通过变量取值，不再遍历 imgIndex =====
  if defined idx_%%i set "imgPath=!idx_%%i!"
  rem ======================================================

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

  rem ===== 【删除】原来的 file_fallback 调用，已不需要 =====
  rem if not defined imgPath (
  rem   call "%modulesDir%file_fallback.bat" "!part!.img" "imgPath"
  rem )

  if not defined imgPath (
    echo 缺失文件: !part!.img
    call :log "!part!.img 文件缺失，跳过刷写"
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