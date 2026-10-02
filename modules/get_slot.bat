:start
set /a "waitNo+=1"
"%adbp%" devices 2>nul | findstr /i "device$" >nul
if not errorlevel 1 (
    call :log "找到adb设备"
    for /f "delims=" %%a in ('"%adbp%" shell getprop ro.boot.slot_suffix 2^>nul') do set "activeSlot=%%a"
)

"%fastbootp%" devices 2>nul | findstr /i "fastboot" >nul
if not errorlevel 1 (
    call :log "找到fastboot设备"
    for /f "tokens=2 delims=:" %%a in ('%fastbootp% getvar current-slot 2^>^&1 ^| findstr /i "current-slot"') do (
        set "temp_slot=%%a"
        for /f "tokens=* delims= " %%b in ("!temp_slot!") do set "activeSlot=%%b"
        call :log "找到卡槽：temp_slot"
    )
    
    for /f "tokens=2 delims=:" %%a in ('%fastbootp% getvar slot-count 2^>^&1 ^| findstr /i "slot-count"') do (
        set "temp_count=%%a"
        for /f "tokens=* delims= " %%b in ("!temp_count!") do set "slotCount=%%b"
                call :log "卡槽数量：!temp_count!"
    )
)

if "!activeSlot!"=="_a" goto end
if "!activeSlot!"=="a" goto end
if "!activeSlot!"=="_b" goto end
if "!activeSlot!"=="b" goto end

timeout /t 5 /nobreak >nul
if !waitNo! geq 2 echo  已等待  !waitNo!*5  秒.....
if !waitNo! geq 4 (
    echo 等待时间太久 无法获取卡槽 确保手机正确连接
    pause
    exit /b 1
)
goto start

:end
if "!activeSlot!"=="_a" set "activeSlot=a"
if "!activeSlot!"=="a" set "inActiveSlot=b"

if "!activeSlot!"=="_b" set "activeSlot=b"
if "!activeSlot!"=="b" set "inActiveSlot=a"

set "inSlot=!activeSlot!"
echo 活动槽位: !activeSlot! 
echo 闲置槽位: !inActiveSlot! 
echo 原始槽位: !inSlot! 
echo 卡槽数量：!slotCount!
endlocal & set "activeSlot=%activeSlot%" & set "inActiveSlot=%inActiveSlot%" & set "inSlot=%inSlot%" & set "slotCount=%slotCount%"
timeout /t 1
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof