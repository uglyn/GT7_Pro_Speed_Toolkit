@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "%lpmakep%"  "cls"

set "missingList="
set "hasMissing=0"
set "superSize=15569256448"
set "groupSize=15565062144"

set "superImg=%pd0Dir%super.img"

set "partInfoFile=%tempDir%part_sizes.txt"
type nul > "!partInfoFile!" 2>nul  

if exist "!superImg!" (
    echo 检测到已存在 super.img，跳过打包。
    call :log "检测到已存在 super.img，跳过打包"
    echo 只允许活动卡槽 A 刷写
    pause
    exit /b 1
)

call :log "卡刷包img目录"
call "%modulesDir%choose_source.bat" "imgDir" "imglist" " 解压过的卡刷包 img  " || exit /b 1
call :log "获取动态分区"
call "%modulesDir%get_dynamic_partitions.bat" "superParts" "%imgDir%" "dySuperSize" || exit /b 1

if defined dySuperSize (
    set "groupSize=!dySuperSize!"
    echo 已经重新修改groupSize大小 :!dySuperSize!
    echo 警告: 如果改了大小，请手动核对脚本顶部的 groupSize 变量是否匹配（当前为 %groupSize%）
)

call :log "需要打包的分区来自: "
call :log " 建立索引，根目录: %imgDir% 配置:!superParts!"
call "%modulesDir%build_img_index.bat" "%imgDir%" "imgIndex" "!superParts!" || exit /b 1

rem ===== 【新增】一次性读取索引，生成变量 =====
for /f "usebackq tokens=1,* delims=|" %%A in ("!imgIndex!") do (
    set "idx_%%A=%%B"
)
rem ==========================================

set "lpmakeCmd=!lpmakep! --device-size %superSize% --metadata-size 65536 --metadata-slots 3 --virtual-ab --super-name super --group qti_dynamic_partitions_a:%groupSize% --group qti_dynamic_partitions_b:%groupSize% --sparse"

for /f "usebackq delims=" %%p in ("!superParts!") do (
    set "pName=%%p"
    set "pName=!pName: =!"
    set "pName=!pName:	=!"
    
    if not "!pName!"=="" (
        set "fileExists=0"
        set "imgFile="

        rem ===== 【修改】直接通过变量取值，不再遍历 imgIndex 和调 fallback =====
        call set "imgFile=%%idx_!pName!%%"
        rem ==================================================================

        if defined imgFile if exist "!imgFile!" set "fileExists=1"

        if !fileExists!==1 (
            for %%a in ("!imgFile!") do set "imgSize=%%~za"
            if "!imgSize!"=="" set "imgSize=0"
            set "size_a=!imgSize!"
            set "size_b=0"
            echo !pName!_a !size_a! >> "%partInfoFile%"
            echo !pName!_b !size_b! >> "%partInfoFile%"
            set "lpmakeCmd=!lpmakeCmd! --partition !pName!_a:readonly:!size_a!:qti_dynamic_partitions_a --partition !pName!_b:readonly:!size_b!:qti_dynamic_partitions_b"
            set "lpmakeCmd=!lpmakeCmd! --image=!pName!_a=!imgFile!"
        )

        if !fileExists!==0 (
            set "hasMissing=1"
            set "missingList=!missingList! !pName!.img"
        )
    )
)

if !hasMissing!==1 (
    echo -----------------------------------------------------------------------------
    echo 错误：以下分区镜像文件不存在：
    echo !missingList!
    echo.
    echo 请将对应的 .img 文件放入以下目录:
    echo   主目录: %imgDir%
    echo -----------------------------------------------------------------------------
    call :log "缺失镜像文件: !missingList!"
    del "%partInfoFile%" 2>nul
    del "%imgIndex%" 2>nul
    goto :error 
)

set "lpmakeCmd=!lpmakeCmd! --output "!superImg!""
cls
echo.
echo.
echo.
echo super各分区列表及大小：
type "%partInfoFile%"
echo.
echo super.img 总大小为 %superSize% 字节 %pd0Dir% 至少保留 25GB 以上
echo -----------------------------------------------------------------------------
echo.
choice /c YN /t 10 /d N /m "按 Y 开始打包super，按 N 立即取消（10秒无操作自动取消）: "
if errorlevel 2 (
    echo 用户取消
    call :log "用户取消"
    exit /b 1
)
cls
echo.
echo.
cmd /c "!lpmakeCmd!"
if errorlevel 1 (
    echo 打包失败！
    call :log "打包失败"
    goto :error 
) 
echo -----------------------------------------------------------------------------
echo.
echo 打包成功！生成 %pd0Dir%super.img
call :log "打包成功，输出 %pd0Dir%super.img"
echo.
echo 只允许活动卡槽 A 刷写 super.img
echo.
echo -----------------------------------------------------------------------------
del "!partInfoFile!" 2>nul
del "!imgIndex!" 2>nul
timeout /t 1
exit /b 0

:error
echo 按任意键退出...
pause
exit /b 1

:log
echo %time% %~1 >> "%logFile%"
goto :eof