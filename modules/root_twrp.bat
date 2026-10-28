@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" "cls"

set "root_twrpFile=%configDir%root_twrp.txt"
if not exist "%root_twrpFile%" (
	echo(找不到%root_twrpFile%文件
	goto exitb1
)
set "excludeFile=%tempDir%exclude_initboot.txt"
type nul > "%excludeFile%" 2>nul

set "initBootImg=%imagesDir%root_twrp\init_boot.img"
set "KO_DIR=%toolsDir%kernelsu"

echo.
echo(    -----------------------------------------------------------------------------------
echo(    请选择刷写模式：
echo.
echo(    [1] 只刷Root   修补并刷入 init_boot 
echo.
echo(    [2] 只刷TWRP   
echo.
echo(    [3] 刷写TWRP Root  修补并刷入 init_boot  内置TWRP
echo.
echo(    -----------------------------------------------------------------------------------

choice /c 123 /n /m "请选择 [1/2/3]:"
set "sel=!errorlevel!"
echo.
echo(你的选择!sel! 
echo.
if "!sel!"=="1" (
    echo([1] 已选择：只 Root  
    >"%excludeFile%" echo(recovery
)

if "!sel!"=="2" (
    echo([2] 已选择：只刷 TWRP
    >"%excludeFile%" echo(init_boot
    goto :do_flash
)
if "!sel!"=="3" (
    echo([3] 已选择：刷 TWRP 和 Root
)
if exist "%initBootImg%" (
    echo([*] 检测到已有 init_boot.img，视为已修补，跳过修补步骤，直接刷写。
    goto :do_flash
)

call "%modulesDir%choose_file.bat" "userImg" "原版init_boot.img"

:manual_kmi
cls
echo.
echo.
echo.
echo(    -----------------------------------------------------------------------------------
echo(    [1]请选择 KernelSU KMI 版本
echo(    [2]不同型号的内核版本可能不同，请根据实际显示选择对应的 KMI。
echo(    [3]例如：内核版本为 6.6.66-android15-8-... 则 KMI 为 android15-6.6
echo(    -----------------------------------------------------------------------------------
set "index=0"

for %%f in ("%KO_DIR%\*.ko") do (
    set /a index+=1
    set "filename=%%~nf"
    set "kmi=!filename:_kernelsu=!"
    
    echo([!index!] !kmi!       
    set "kmi_!index!=!kmi!"
    set "ko_!index!=%%f"
)
set "total=!index!"

echo.
echo([*] 温馨提示：真我GT7 Pro 竞速版 请选择 [*] android15-6.6

if !total! equ 0 (
    echo([错误] 未找到任何 .ko 文件！
    goto exitb1
)

echo([*] 请按数字键选择对应的 KMI。
echo([*] 只支持aarch64
echo.

rem 动态拼接 choice 的选项（1 到 total），由于 choice 最多支持单字符，要求 ko 文件不超过 9 个
set "choice_options="
for /l %%i in (1,1,!total!) do set "choice_options=!choice_options!%%i"

choice /c !choice_options! /n /m "请按数字键选择 [1-!total!]: "

rem 直接把 errorlevel 当作用户按下的数字
set "choice=!errorlevel!"

for %%a in (!choice!) do (
    set "KMI=!kmi_%%a!"
    set "KO_FILE=!ko_%%a!"
)

:kmi_done
echo([*] 使用 KMI：!KMI!
echo([*] 匹配到内核模块: !KO_FILE!
echo([*] 如果选错了内核 重新修补 使用脚本修补即可
echo.
timeout /t 5

echo([*] 正在修补 !userImg! ...
"%ksudp%" boot-patch -b "!userImg!" --kmi !KMI! --module "!KO_FILE!" --out-name "%initBootImg%"
if errorlevel 1 (
    echo([错误] 修补失败！
    call "%modulesDir%logger.bat" "%~nx0"  "修补失败"
    if exist "%initBootImg%" del "%initBootImg%" >nul   
    goto exitb1
)
echo.
call "%modulesDir%logger.bat" "%~nx0"  "修补完成，已输出到 %initBootImg%"
echo([*] 修补完成，输出文件：%initBootImg%


:do_flash
call "%modulesDir%logger.bat" "%~nx0"  "重启到bootloader  "
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  "刷写root twrp"
call "%modulesDir%flash_images.bat" "%imagesDir%root_twrp" "%root_twrpFile%" "%excludeFile%" 0  || exit /b 1

 
if exist "!excludeFile!" del "!excludeFile!" >nul

if "!sel!"=="2" (
    "%fastbootp%" reboot recovery 
     exit /b 0
) 
move /y "!initBootImg!" "%imagesDir%root_twrp\ksu_patch_%today%.img" 

echo(    --------------------------------------------------------------------------------------------
echo.
echo(    已刷入 Root！请手动在手机上安装 KSU apk
exit /b 11

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

