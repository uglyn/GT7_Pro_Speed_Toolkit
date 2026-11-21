@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0"   "cls"

:menu
cls
echo(============================================
echo(请选择要打包的 super 分区大小：
echo.
echo(  1 - 14.5G   官方大小  默认
echo.
echo(  2 -  25G    双系统专用   
echo(============================================
choice /c 12 /t 10 /d 1 /n /m " 请输入数字 [1/2]: "
if errorlevel 2 goto size_25
if errorlevel 1 goto size_14_5

:size_25
set "superSize=26843545600"
set "groupSize=26839351296"
set "sizeName=25G"
goto start_pack

:size_14_5
set "superSize=15569256448"
set "groupSize=15565062144"
set "sizeName=14.5G"
goto start_pack

:start_pack
cls
:: ========= 公共变量在这里统一设置，不用重复写 =========
set "superImg=%pd0Dir%super_!sizeName!.img"
set "missingList="
set "hasMissing=0"
set "partInfoFile=%tempDir%part_sizes.txt"
type nul > "!partInfoFile!" 2>nul  
:: =======================================================

if exist "!superImg!" (
    echo(检测到已存在 !superImg!，跳过打包。
    call "%modulesDir%logger.bat" "%~nx0"  "检测到已存在 !sizeName! super.img，跳过打包"
    echo(只允许手机活动卡槽 A 刷写 super.img
    goto exitb1
)

call "%modulesDir%choose_source.bat" "imgDir" "imglist" "卡刷包.img" || exit /b 1
set "imgDir=!imgDir:"=!"
call "%modulesDir%logger.bat" "%~nx0"  "卡刷包img目录:%imgDir%" 

call "%modulesDir%logger.bat" "%~nx0"  "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" || exit /b 1

call "%modulesDir%logger.bat" "%~nx0"  " 建立索引，根目录: %imgDir% 配置:!superParts!"
call "%modulesDir%build_img_index.bat" "%imgDir%" "imgIndex" "!superParts!" || exit /b 1

for /f "usebackq tokens=1,* delims=|" %%A in ("!imgIndex!") do (
    set "idx_%%A=%%B"
)

set "lpmakeCmd=!lpmakep! --device-size !superSize! --metadata-size 65536 --metadata-slots 3 --virtual-ab --super-name super --group qti_dynamic_partitions_a:!groupSize! --group qti_dynamic_partitions_b:!groupSize!"

for /f "usebackq delims=" %%p in ("!superParts!") do (
    set "pName=%%p"
    set "pName=!pName: =!"
    set "pName=!pName:	=!"
    
    if not "!pName!"=="" (
        set "fileExists=0"
        set "imgFile="

        for %%V in (!pName!) do set "imgFile=!idx_%%V!"
        if defined imgFile if exist "!imgFile!" set "fileExists=1"

        if !fileExists!==1 (
            for %%a in ("!imgFile!") do set "imgSize=%%~za"
            if "!imgSize!"=="" set "imgSize=0"
            set "size_a=!imgSize!"
            set "size_b=0"
            
            >> "%partInfoFile%" echo(!pName!_a !size_a!		!pName!_b !size_b!
            set "lpmakeCmd=!lpmakeCmd! --partition !pName!_a:readonly:!size_a!:qti_dynamic_partitions_a --partition !pName!_b:readonly:!size_b!:qti_dynamic_partitions_b"
        )

        if !fileExists!==0 (
            set "hasMissing=1"
            set "missingList=!missingList! !pName!.img"
        )
    )
)

if !hasMissing!==1 (
    echo(-----------------------------------------------------------------------------
    echo(错误：以下分区镜像文件不存在：
    echo(!missingList!
    echo.
    echo(请将对应的 .img 文件放入以下目录:
    echo(  主目录: %imgDir%
    echo(-----------------------------------------------------------------------------
    call "%modulesDir%logger.bat" "%~nx0"  "缺失镜像文件: !missingList!"
    goto exitb1
)

set "lpmakeCmd=!lpmakeCmd! --output "!superImg!""
cls
echo.
echo.
echo.
echo(super    各分区                   大小：
type "%partInfoFile%"
echo(---------------------------------------------------------------------------------
echo.
echo(        super.img 总大小为 !superSize! 字节 ( !sizeName! )
echo.
echo(        %pd0Dir% 至少保留 25GB 以上
echo(      -----------------------------------------------------------------------------
echo.
choice /c YN /t 10 /d N /m "按 Y 开始打包super，按 N 立即取消（10秒无操作自动取消）: "
if errorlevel 2 (
    echo(用户取消
    call "%modulesDir%logger.bat" "%~nx0"  "用户取消"
    exit /b 0
)
cls
echo.
echo(!lpmakeCmd!
!lpmakeCmd!
if errorlevel 1 (
    echo(打包失败！
    call "%modulesDir%logger.bat" "%~nx0"  "打包失败"
    goto exitb1
) 
call "%modulesDir%logger.bat" "%~nx0"  "打包成功，输出 !superImg!"
echo(    -----------------------------------------------------------------------------
echo.
echo(    打包成功！已生成 "!superImg!"
echo.
echo(    只允许手机活动卡槽为:A   刷写 super.img
echo.
echo(    -----------------------------------------------------------------------------
del "!imgIndex!" 2>nul
del "%partInfoFile%" 2>nul
exit /b 1

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1