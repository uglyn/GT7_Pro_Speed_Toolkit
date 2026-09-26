@echo off
call "%modulesDir%header.bat" "%~nx0" "" "cls"
set "slotInfo=%tempDir%slot_info.txt"

rem 分别获取 current-slot 和 slot-count，各自检查
"%fastbootPath%" getvar current-slot > "%slotInfo%" 2>&1
if errorlevel 1 goto param_error

"%fastbootPath%" getvar slot-count >> "%slotInfo%" 2>&1
if errorlevel 1 goto param_error

set "activeSlot="
for /f "tokens=2 delims=:" %%a in ('type "%slotInfo%" ^| findstr /i "current-slot"') do (
    set "activeSlot=%%a"
)

rem 核心报警：拿不到 activeSlot 直接终止
set "activeSlot=%activeSlot: =%"
if "%activeSlot%"=="" (
    echo [错误] 无法获取当前活动卡槽，请检查设备是否在 Fastboot 模式！
    pause
    exit /b 1
)

set "slotCount="
for /f "tokens=2 delims=:" %%a in ('type "%slotInfo%" ^| findstr /i "slot-count"') do (
    set "slotCount=%%a"
)
if "%slotCount%"=="" set "slotCount=2"
set "slotCount=%slotCount: =%"

set "inActiveSlot=%activeSlot%"
if %slotCount% geq 2 (
    if "%activeSlot%"=="a" set "inActiveSlot=b"
    if "%activeSlot%"=="b" set "inActiveSlot=a"
)

set "inSlot=%activeSlot%"

del "%slotInfo%" 2>nul
echo 活动槽位: %activeSlot%, 闲置槽位: %inActiveSlot%, 原始槽位: %inSlot% (槽位数量: %slotCount%)
exit /b 0

:param_error
echo.
echo [错误] 获取设备卡槽信息失败！
pause
exit /b 1