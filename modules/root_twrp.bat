@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "cls"

set "initBootImg=%imagesDir%root_twrp\init_boot.img"
set "KO_DIR=%toolsDir%kernelsu"

echo.
echo(    ------------------------------------请选择-----------------------------------------
echo.
echo(    [1] 只刷Root   修补并刷入 init_boot 
echo.
echo(    [2] 刷写Root和TWRP    
echo.
echo(    [3] 只刷Rec   刷入TWRP
echo.
echo(    ------------------------------------请选择-----------------------------------------

choice /c 123 /n /m "请选择 [1/2/3]:"
set "sel=!errorlevel!"
echo.
echo(你的选择!sel! 
echo.

if "!sel!"=="1" set "root_twrpFile=%configDir%init_boot.txt"
if "!sel!"=="2" set "root_twrpFile=%configDir%root_twrp.txt"
if "!sel!"=="3" set "root_twrpFile=%configDir%recovery.txt"
if not exist "!root_twrpFile!" (
    echo(找不到刷写配置文件: !root_twrpFile!
    call "%modulesDir%logger.bat" "%~nx0"  "缺失配置文件: !root_twrpFile!"
    goto exitb1
)

if "!sel!"=="3" goto do_flash
if exist "%initBootImg%" (
    echo(检测到已有 init_boot.img，跳过修补步骤
    goto do_flash
)

call "%modulesDir%choose_file.bat" "userImg" "原版init_boot.img"
set "userImg=!userImg:"=!"

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

if !index! equ 0 (
    echo([错误] 未找到任何 .ko 文件！
    goto exitb1
)
echo.
echo([*] 温馨提示：真我GT7 Pro 竞速版 请选择 [*] android15-6.6
echo([*] 请按数字键选择对应的 KMI 别选错了
echo([*] 只支持手机 不支持平板和电视

rem 动态拼接 choice 的选项（1 到 index），由于 choice 最多支持单字符，要求 ko 文件不超过 9 个
set "choice_options="
for /l %%i in (1,1,!index!) do set "choice_options=!choice_options!%%i"

choice /c !choice_options! /n /m "请按数字键选择 [1-!index!]: "

rem 直接把 errorlevel 当作用户按下的数字
set "choice=!errorlevel!"

for %%a in (!choice!) do (
    set "KMI=!kmi_%%a!"
    set "KO_FILE=!ko_%%a!"
)

:kmi_done
call "%modulesDir%usertimeout.bat" "使用 KMI：!KMI!" "内核模块: !KO_FILE!"
echo.
echo([*] 正在修补 !userImg! ...
"%ksudp%" boot-patch -b "!userImg!" --kmi !KMI! --module "!KO_FILE!" --out-name "%initBootImg%"
call "%modulesDir%logger.bat" "%~nx0"  "%ksudp% boot-patch -b !userImg! --kmi !KMI! --module !KO_FILE! --out-name %initBootImg%"

if errorlevel 1 (
    echo([错误] 修补失败！
    call "%modulesDir%logger.bat" "%~nx0"  "!userImg!修补失败"
    if exist "%initBootImg%" del "%initBootImg%" >nul   
    goto exitb1
)
echo.
call "%modulesDir%logger.bat" "%~nx0"  "修补完成，已输出到 %initBootImg%"
echo([*] 修补完成，输出文件：%initBootImg%


:do_flash
call "%modulesDir%logger.bat" "%~nx0"  "重启到bootloader  "
call "%modulesDir%wait_fastboot_device.bat" bootloader || exit /b 1

call "%modulesDir%flash_images.bat" "%imagesDir%root_twrp" "%root_twrpFile%" "" 0  || exit /b 1
call "%modulesDir%logger.bat" "%~nx0"  "刷写root twrp"
 
if "!sel!"=="3" (
    "%fastbootp%" reboot recovery 
     exit /b 0
) 

move /y "!initBootImg!" "%imagesDir%root_twrp\ksu_patch_%today%.img" 

cls
echo.
echo(    -------------------------------------已刷入Root-------------------------------------
echo.
echo(    已刷入 Root！请手动在手机上安装 KSU apk
exit /b 11

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1