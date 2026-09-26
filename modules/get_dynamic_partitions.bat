@echo off
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

if not "%~1"=="" goto params_ok
echo 错误：未指定输出变量名
echo 用法：%~nx0 [变量名] [包根目录]
exit /b 1

:params_ok
set "_outVar=%~1"
set "_pkgDir=%~2"

set "infoFile=%tempDir%getvar_all.txt"
set "superParts=%tempDir%dynamic_list.txt"
set "rawFile=%tempDir%dynamic_raw.txt"
set "sortedFile=%tempDir%dynamic_sorted.txt"
set "valid=0"

rem ================================================================
rem 第一优先级：包内 META\dynamic_partitions_info.txt
rem ================================================================
if defined _pkgDir (
    if exist "!_pkgDir!\META\dynamic_partitions_info.txt" (
        echo 正在从包内 dynamic_partitions_info.txt 提取动态分区...
        type nul > "%superParts%"
        for /f "usebackq tokens=1,* delims==" %%A in ("!_pkgDir!\META\dynamic_partitions_info.txt") do (
            if /i "%%A"=="dynamic_partition_list" (
                for %%P in (%%B) do (
                    set "p=%%P"
                    if "!p:~-2!"=="_a" set "p=!p:~0,-2!"
                    if "!p:~-2!"=="_b" set "p=!p:~0,-2!"
                    echo !p!>> "%superParts%"
                )
            )
        )
        for /f "usebackq delims=" %%a in ("%superParts%") do set "valid=1"
        if !valid!==1 call :log "已从包内 dynamic_partitions_info.txt 获取动态分区"
    )
)

rem ================================================================
rem 仅在线刷包（有 IMAGES 文件夹）缺少 META 文件时，才打印提示
rem 如果是卡刷包（纯 img 文件夹），则静默跳过，避免误导
rem ================================================================
if !valid!==0 (
    if defined _pkgDir if exist "!_pkgDir!\IMAGES\" (
        echo 包内未找到 dynamic_partitions_info.txt，尝试从设备读取...
        call :log "包内未找到，转向设备读取"
    )
)

rem ================================================================
rem 第二优先级：从设备读取
rem ================================================================
if !valid!==0 (
    "%fastbootPath%" getvar all > "%infoFile%" 2>&1
    if not errorlevel 1 (
        findstr /i "is-logical:.*:yes" "%infoFile%" >nul
        if not errorlevel 1 (
            (for /f "usebackq tokens=2 delims=:" %%a in (`findstr /i "is-logical:.*:yes" "%infoFile%"`) do (
                set "part=%%a"
                set "part=!part: =!"
                set "part=!part:	=!"
                if not "!part!"=="" echo !part!
            )) > "%rawFile%"

            sort "%rawFile%" > "%sortedFile%"

            set "prev="
            (for /f "usebackq delims=" %%a in ("%sortedFile%") do (
                set "curr=%%a"
                if "!curr:~-2!"=="_a" set "curr=!curr:~0,-2!"
                if "!curr:~-2!"=="_b" set "curr=!curr:~0,-2!"

                echo !curr! | findstr /i "_cow -cow" >nul
                if errorlevel 1 (
                    if not "!curr!"=="!prev!" (
                        echo !curr!
                        set "prev=!curr!"
                    )
                )
            )) > "%superParts%"

            del "%rawFile%" "%sortedFile%" 2>nul

            for /f "usebackq delims=" %%a in ("%superParts%") do set "valid=1"
            if !valid!==1 call :log "从设备获取动态分区成功"
        )
    )
)

rem ================================================================
rem 第三优先级：config 默认列表
rem ================================================================
if !valid!==0 (
    echo 设备读取也失败，尝试备用配置文件...
    set "superFile=%configDir%super.txt"
    if exist "%superFile%" (
        copy "%superFile%" "%superParts%" >nul
        set "valid=1"
        call :log "已使用备用配置文件"
    )
)

if !valid!==0 (
    echo 错误：无法获取有效的动态分区列表
    echo 请使用第三方REC_TWRP或者功能8刷写super
    call :log "无法获取有效的动态分区列表"
    timeout /t 5 >nul
    exit /b 1
)
set "count=0"
for /f "usebackq delims=" %%a in ("%superParts%") do set /a count+=1
echo 找到 !count! 个动态分区，已保存到 %superParts%

endlocal & set "%_outVar%=%superParts%"
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof