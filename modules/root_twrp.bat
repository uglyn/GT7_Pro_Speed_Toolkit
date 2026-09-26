@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"
call :log "========== 一键刷写 TWRP + (可选) Root =========="
set "root_twrpFile=%configDir%root_twrp.txt"
set "excludeFile=%tempDir%exclude_initboot.txt"
set "initBootImg=%imagesDir%root_twrp\init_boot.img"
set "KO_DIR=%toolsDir%kernelsu"

:: ---------- 选择刷写模式 ----------
echo.
echo ============================================================
echo 请选择刷写模式：
echo [1] 只 Root (仅修补并刷入 init_boot，不刷 TWRP)
echo [2] 只刷 TWRP (跳过 Root 修补，刷入 TWRP)
echo [3] 刷 TWRP + Root (修补并刷入 init_boot 和 TWRP) - 默认
echo ============================================================
set "action="
set /p "action=请输入 [1/2/3] (直接回车或输入其他均默认为 3): "

:: 核心逻辑：只要不是 1 和 2，统统强制赋值为 3
if "!action!" neq "1" if "!action!" neq "2" set "action=3"

if "!action!"=="1" (
    echo [*] 已选择：只 Root (不刷 TWRP，不重启到 Recovery)
    echo recovery>"%excludeFile%"
)
if "!action!"=="2" (
    echo [*] 已选择：只刷 TWRP
    echo init_boot>"%excludeFile%"
    goto :do_flash
)
if "!action!"=="3" (
    echo [*] 已选择：刷 TWRP + Root
    if exist "%excludeFile%" del "%excludeFile%" >nul
)

:: ---------- 检测到已有 init_boot.img → 视为已修补，直接刷写 ----------
if exist "%initBootImg%" (
    echo [*] 检测到已有 init_boot.img，视为已修补，跳过修补步骤，直接刷写。
    goto :do_flash
)

:: ---------- 不存在 → 让用户选择文件 ----------
echo.
call "%modulesDir%choose_file.bat" "userImg" "原版init_boot.img"

:: ==============================================================
:: 以下为 KMI 选择菜单（含自动解析选项）
:: ==============================================================
:manual_kmi
echo.
echo ============================================================
echo 请选择 KernelSU KMI 版本，或自动从 boot.img 解析
echo 不同型号的内核版本可能不同，请根据实际显示选择对应的 KMI。
echo 例如：内核版本为 6.6.66-android15-8-... 则 KMI 为 android15-6.6
echo ============================================================
echo.

set "index=0"
echo [0] 自动从 boot.img 解析 KMI（需拖入 boot.img 文件）
for %%f in ("%KO_DIR%\*.ko") do (
    set /a index+=1
    set "filename=%%~nf"
    set "kmi=!filename:_kernelsu=!"
    
    :: 针对特定机型添加备注
    if "!kmi!"=="android15-6.6" (
        echo [!index!] !kmi! [真我GT7 Pro 竞速版]  选这个
    ) else (
        echo [!index!] !kmi!
    )
    
    set "kmi_!index!=!kmi!"
    set "ko_!index!=%%f"
)
set "total=!index!"

if !total! equ 0 (
    echo [错误] 未找到任何 .ko 文件！
    pause
    exit /b 1
)

echo.
echo [*] 请手动输入序号选择对应的 KMI。
echo [*] 如果直接按回车，将默认选择 [0] 自动解析。
echo [*] 只支持aarch64
echo.

set "choice="
set /p "choice=请输入序号 [0-%total%]: "

:: 移除硬编码默认值，如果用户没输入直接回车，则安全地默认为 0（自动解析）
if "!choice!"=="" set "choice=0"

:: 验证输入（严格限定只能是 0-9 之间的单个数字）
echo !choice!| findstr /r "^[0-9]$" >nul
if errorlevel 1 (
    echo [错误] 请输入有效序号（必须是 0-9 之间的数字）！
    timeout /t 3 >nul
    goto manual_kmi
)

:: 验证是否超出总数量（比如总共只有6个选项，输入了8）
if !choice! gtr !total! (
    echo [错误] 序号不能大于 !total!！
    timeout /t 3 >nul
    goto manual_kmi
)

:: ---------- 处理自动解析选项 ----------
if "!choice!"=="0" (
    call "%modulesDir%choose_file.bat" "bootImgFile" "原版boot.img"
    if errorlevel 1 (
        echo 用户取消选择，返回菜单。
        goto manual_kmi
    )

    echo [*] 正在从 boot.img 解析 KMI...
    :: 使用 find 命令替代 findstr，提高 Windows 下二进制文件搜索成功率
    find "Linux version" < "!bootImgFile!" > "%tempDir%_kmi_raw.txt" 2>nul
    for %%a in ("%tempDir%_kmi_raw.txt") do if %%~za gtr 0 (
        for /f "usebackq tokens=3 delims= " %%a in ("%tempDir%_kmi_raw.txt") do set "KERNEL_STR=%%a"
    )
    del "%tempDir%_kmi_raw.txt" 2>nul

    if not defined KERNEL_STR (
        echo [错误] 无法从 boot.img 中解析到内核版本！
        echo 请确认该文件是有效的 boot.img。
        goto manual_kmi
    )

    echo [*] 内核版本原串：!KERNEL_STR!
    for /f "tokens=1,2,3 delims=-" %%b in ("!KERNEL_STR!") do (
        set "PART1=%%b"
        set "PART2=%%c"
        set "PART3=%%d"
    )
    for /f "tokens=1,2 delims=." %%x in ("!PART1!") do set "KMI_MAJOR=%%x.%%y"
    set "AUTO_KMI=!KMI_MAJOR!-!PART2!-!PART3!"
    for /f "tokens=1,2,3 delims=-" %%a in ("!AUTO_KMI!") do set "KO_VER=%%b-%%a"
    set "AUTO_KO=%KO_DIR%\!KO_VER!_kernelsu.ko"

    if exist "!AUTO_KO!" (
        echo [*] 自动解析到 KMI: !AUTO_KMI!，匹配模块: !AUTO_KO!
        set "KMI=!AUTO_KMI!"
        set "KO_FILE=!AUTO_KO!"
        goto kmi_done
    ) else (
        echo [警告] 解析到 KMI !AUTO_KMI!，但未找到对应的 .ko 文件！
        echo 请检查 tools\kernelsu\ 目录下是否存在 !KO_VER!_kernelsu.ko
        pause
        goto manual_kmi
    )
)

:: ---------- 手动选择 ----------
for %%a in (!choice!) do (
    set "KMI=!kmi_%%a!"
    set "KO_FILE=!ko_%%a!"
)

:kmi_done
echo [*] 使用 KMI：%KMI%
echo [*] 匹配到内核模块: %KO_FILE%

:: ---------- 执行修补（直接读取用户文件，输出到 imgDir） ----------
echo [*] 正在修补 !userImg! ...
"%toolsDir%kernelsu\ksud.exe" boot-patch -b "!userImg!" --kmi %KMI% --module "%KO_FILE%" --out-name "%initBootImg%"

if errorlevel 1 (
    echo [错误] 修补失败！
    if exist "%initBootImg%" del "%initBootImg%" >nul   
    pause
    exit /b 1
)
call :log "修补完成，已输出到 %initBootImg%"
echo [*] 修补完成，输出文件：%initBootImg%

:: ---------- 统一刷写 ----------
:do_flash
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1
call :log "[*] 开始刷写..."
call "%modulesDir%flash_images.bat" "%imagesDir%root_twrp" "%root_twrpFile%" "%excludeFile%" 0
call :log "刷写流程结束，请查看上方日志。"

if exist "%excludeFile%" del "%excludeFile%" >nul

:: 根据 action 决定重启去向：选 1 进系统，选 2 和 3 进 Recovery
if "!action!" neq "1" (
    echo [*] 正在重启到 Recovery 模式...
    %fastbootPath% reboot recovery
) else (
    echo [*] 正在重启到系统...
    %fastbootPath% reboot
)

echo ============================================================
:: 只有选 2（只刷 TWRP）不提示安装 APK
if "!action!" neq "2" (
    echo 已刷入 Root！请手动在手机上安装 KSU APK 目录: %apkDir%
    start "" "%apkDir%"
    exit /b 0
)
echo 已跳过 Root，仅刷 TWRP。
:log
echo %time% %~1 >> "%logFile%"
goto :eof