@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

set "root_twrpFile=%configDir%root_twrp.txt"
if not exist "%root_twrpFile%" (
	echo 找不到%root_twrpFile%文件
	pause
	exit /b 1
)
set "excludeFile=%tempDir%exclude_initboot.txt"
type nul > "!excludeFile!" 2>nul

set "initBootImg=%imagesDir%root_twrp\init_boot.img"
set "KO_DIR=%toolsDir%kernelsu"

echo.
echo     -----------------------------------------------------------------------------------
echo     请选择刷写模式：
echo.
echo     [1] 只刷Root   修补并刷入 init_boot 
echo.
echo     [2] 只刷TWRP   
echo.
echo     [3] 刷写TWRP Root  修补并刷入 init_boot  内置TWRP
echo.
echo     -----------------------------------------------------------------------------------

choice /c 123 /n /m "请选择 [1/2/3]:"
set "sel=!errorlevel!"
echo.
echo 你的选择!sel! 
echo.
if "!sel!"=="1" (
    echo [1] 已选择：只 Root  
    echo recovery>"%excludeFile%"
)

if "!sel!"=="2" (
    echo [2] 已选择：只刷 TWRP
    echo init_boot>"%excludeFile%"
    goto :do_flash
)
if "!sel!"=="3" (
    echo [3] 已选择：刷 TWRP 和 Root
)
if exist "%initBootImg%" (
    echo [*] 检测到已有 init_boot.img，视为已修补，跳过修补步骤，直接刷写。
    goto :do_flash
)

call "%modulesDir%choose_file.bat" "userImg" " 原版init_boot.img  "

:manual_kmi
cls
echo.
echo.
echo.
echo     -----------------------------------------------------------------------------------
echo     [1]请选择 KernelSU KMI 版本，或自动从 boot.img 解析
echo     [2]不同型号的内核版本可能不同，请根据实际显示选择对应的 KMI。
echo     [3]例如：内核版本为 6.6.66-android15-8-... 则 KMI 为 android15-6.6
echo     -----------------------------------------------------------------------------------
set "index=0"
set "has_special=0"
for %%f in ("%KO_DIR%\*.ko") do (
    set /a index+=1
    set "filename=%%~nf"
    set "kmi=!filename:_kernelsu=!"
    
    echo [!index!] !kmi!
    
    if "!kmi!"=="android15-6.6" set "has_special=1"
    
    set "kmi_!index!=!kmi!"
    set "ko_!index!=%%f"
)
set "total=!index!"
set /a "auto_option=total+1"

rem 把自动解析放到最后一行
echo [!auto_option!] 自动从 boot.img 解析 KMI（需拖入 boot.img 文件）

echo.
if !has_special!==1 (
    echo * 温馨提示：真我GT7 Pro 竞速版 请选择 [*] android15-6.6
)
if !total! equ 0 (
    echo [错误] 未找到任何 .ko 文件！
    pause
    exit /b 1
)

echo [*] 请按数字键选择对应的 KMI。
echo [*] 只支持aarch64
echo.

rem 动态拼接 choice 的选项（1 到 auto_option），由于 choice 最多支持单字符，要求 ko 文件不超过 8 个
set "choice_options="
for /l %%i in (1,1,!auto_option!) do set "choice_options=!choice_options!%%i"

choice /c !choice_options! /n /m "请按数字键选择 [1-!auto_option!]: "

rem 直接把 errorlevel 当作用户按下的数字
set "choice=!errorlevel!"
if "!choice!"=="!auto_option!" (
    call "%modulesDir%choose_file.bat" "bootImgFile" " 原版boot.img "

    echo [*] 正在从 boot.img 解析 KMI...
    find "Linux version" < "!bootImgFile!" > "%tempDir%_kmi_raw.txt" 2>nul
    for %%a in ("%tempDir%_kmi_raw.txt") do if %%~za gtr 0 (
        for /f "usebackq tokens=3 delims= " %%a in ("%tempDir%_kmi_raw.txt") do set "KERNEL_STR=%%a"
    )
    del "%tempDir%_kmi_raw.txt" 2>nul

    if not defined KERNEL_STR (
        echo [错误] 无法从 boot.img 中解析到内核版本！
        echo 请确认该文件是有效的 官方原版boot.img 
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
        goto manual_kmi
    )
)

for %%a in (!choice!) do (
    set "KMI=!kmi_%%a!"
    set "KO_FILE=!ko_%%a!"
)

:kmi_done
echo [*] 使用 KMI：%KMI%
echo [*] 匹配到内核模块: %KO_FILE%
echo [*] 如果选错了内核 重新修补 使用脚本修补即可
echo.
timeout /t 5

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


:do_flash
call :log "重启到bootloader  "
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

call :log "刷写root twrp"
call "%modulesDir%flash_images.bat" "%imagesDir%root_twrp" "%root_twrpFile%" "%excludeFile%" 0


if "!sel!"=="2" (
    %fastbootp% reboot recovery 
     exit /b 0
) 
del "!excludeFile!" >nul
move /y "!initBootImg!" "%imagesDir%root_twrp\ksu_patch_%today%.img" 

echo.
echo 已刷入 Root！请手动在手机上安装 KSU APK（目录: %apkDir%）
echo.
%fastbootp% reboot
exit /b 0

:log
echo %time% %~1 >> "%logFile%"
goto :eof