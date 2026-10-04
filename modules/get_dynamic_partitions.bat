@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

if not "%~1"=="" goto params_ok
echo 错误：未指定输出变量名
echo 用法：%~nx0 [变量名] [包根目录] [大小变量名(可选)]
exit /b 1

:params_ok
set "_outVar=%~1"
set "_pkgDir=%~2"
set "_sizeVar=%~3"

rem ====== 初始化临时文件与变量 ======
set "infoFile=%tempDir%getvar_all.txt"
type nul > "%infoFile%"
set "superParts=%tempDir%dynamic_list.txt"
type nul > "%superParts%"
set "rawFile=%tempDir%dynamic_raw.txt"
type nul > "%rawFile%"
set "valid=0"
set "superSize="
set "groupName="

if defined _pkgDir (
    if exist "!_pkgDir!\META\dynamic_partitions_info.txt" (
        echo 正在从包内 dynamic_partitions_info.txt 提取动态分区...
        type nul > "%superParts%"
        for /f "usebackq tokens=1,* delims==" %%A in ("!_pkgDir!\META\dynamic_partitions_info.txt") do (
            rem 动态获取组名（如 qti_dynamic_partitions）
            if /i "%%A"=="super_partition_groups" set "groupName=%%B"
            
            rem 提取动态分区列表
            if /i "%%A"=="dynamic_partition_list" (
                for %%P in (%%B) do (
                    set "p=%%P"
                    echo !p!>> "%superParts%"
                    set "valid=1"
                )
            )
            
            rem 动态拼接组名和 _size，获取 super 总大小
            if defined groupName (
                if /i "%%A"=="!groupName!_size" set "superSize=%%B"
            )
        )
        if defined superSize set "superSize=!superSize: =!"
        
        if !valid!==1 echo 已从包内 dynamic_partitions_info.txt 获取动态分区
        if !valid!==1 call :log "已从包内 dynamic_partitions_info.txt 获取动态分区，大小: !superSize!"
    )
)

rem ============================================================
rem 第二优先级：设备读取
rem ============================================================
if !valid!==0 (
    echo 包内未找到，尝试从设备读取...
    call :log "包内未找到，转向设备读取"

    rem ====== 新增：先检测有没有 fastboot 设备，没有就直接跳过，防止卡死 ======
    "%fastbootp%" devices 2>nul | findstr /i "fastboot" >nul
    if errorlevel 1 goto :after_device_read
    rem =====================================================================

    rem 1. 抓取 getvar all
    "%fastbootp%" getvar all > "%infoFile%" 2>&1
    if not errorlevel 1 (
        for %%F in ("%infoFile%") do if %%~zF LSS 100 (
            echo 设备未返回有效分区信息，请检查连接！
            call :log "getvar all 返回为空或过小"
        )
    )

    rem 2. 提取 is-logical:yes 的分区名，写入 rawFile
    findstr /i "is-logical:.*:yes" "%infoFile%" >nul
    if not errorlevel 1 (
        for /f "usebackq tokens=2 delims=:" %%a in (`findstr /i "is-logical:.*:yes" "%infoFile%"`) do (
            set "part=%%a"
            set "part=!part: =!"
            set "part=!part:	=!"
            if not "!part!"=="" echo !part!>> "%rawFile%"
        )
    )

    rem 3. 清洗并查文件去重
    type nul > "%superParts%"
    for /f "usebackq delims=" %%a in ("%rawFile%") do (
        set "curr=%%a"
        
        rem 去掉 _a 和 _b 后缀
        if "!curr:~-2!"=="_a" set "curr=!curr:~0,-2!"
        if "!curr:~-2!"=="_b" set "curr=!curr:~0,-2!"
        
        rem 过滤 _cow 虚拟分区
        echo !curr! | findstr /i "_cow -cow" >nul
        if errorlevel 1 (
            rem 查已经写入的 superParts，如果不存在才写入（加 /x 防止 system 匹配到 system_ext）
            findstr /x /i "!curr!" "%superParts%" >nul
            if errorlevel 1 (
                echo !curr!>> "%superParts%"
                set "valid=1"
            )
        )
    )

    rem 清理 rawFile
    del "%rawFile%" 2>nul 
    if !valid!==1 echo 已从设备中获取动态分区
    if !valid!==1 call :log "从设备获取动态分区成功"
)

:after_device_read

if !valid!==0 (
    set "superFile=%configDir%super.txt"
    if exist "!superFile!" (
        copy "!superFile!" "%superParts%" >nul
        echo 使用内置配置文件...
        set "valid=1"
        call :log "已使用内置备用配置文件"
    )
)

if !valid!==0 (
    echo 错误：无法获取有效的动态分区列表
    call :log "无法获取有效的动态分区列表"
    pause
    exit /b 1
)

set "count=0"
echo.
for /f "usebackq delims=" %%a in ("%superParts%") do set /a count+=1
echo 找到 !count! 个动态分区，已保存到 !superParts!   
call :log "找到 !count! 个动态分区，已保存到 !superParts!"


echo 返回 动态列表:%superParts%
if not "!superSize!"=="" (
    echo.
    echo 返回动态分区大小 %superSize%
    endlocal & set "%_outVar%=%superParts%" & set "%_sizeVar%=%superSize%"
) else (
    endlocal & set "%_outVar%=%superParts%"
)

timeout /t 2
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof