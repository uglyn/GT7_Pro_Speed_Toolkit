@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call :log "========== 打包 super.img 启动 =========="
call "%modulesDir%header.bat" "%~nx0" "%lpmakep%"  "cls"

set "partList="
set "missingList="
set "hasMissing=0"
set "SUPER_SIZE=15569256448"

set "configFile=%configDir%super.txt"
set "superImg=%pd0Dir%super.img"

set "partInfoFile=%tempDir%part_sizes_%RANDOM%.tmp"

type nul > "%partInfoFile%" 2>nul || goto error_exit



if exist "!superImg!" (
    echo 检测到已存在 super.img，跳过打包。
    call :log "检测到已存在 super.img，跳过打包"
    echo 只允许活动卡槽 A 刷写
    pause
    exit /b 1
)

call :log "卡刷包img目录"
call "%modulesDir%choose_source.bat" "imgDir" "imglist" "  卡刷包.img  " || exit /b 1


for /f "usebackq delims=" %%a in ("%configFile%") do (
    if not "%%a"=="" set "partList=!partList! %%a"
)

echo -----------------------------------------------------------------------------
call :log "需要打包的分区列表: %partList%"

set "lpmakeCmd="%lpmakep%" --device-size %SUPER_SIZE% --metadata-size 65536 --metadata-slots 2 --super-name super --group qti_dynamic_partitions:%SUPER_SIZE% --sparse"

for %%p in (%partList%) do (

    set "fileExists=0"
    set "imgFile=%imgDir%\%%p.img"   
    if exist "!imgFile!" set "fileExists=1"
    
    if !fileExists!==1 (
        :: 文件存在，处理大小和命令
        for %%a in ("!imgFile!") do set "imgSize=%%~za"
        if "!imgSize!"=="" set "imgSize=0"
        set "size_a=!imgSize!"
        set "size_b=0"
        echo %%p_a !size_a! >> "%partInfoFile%"
        echo %%p_b !size_b! >> "%partInfoFile%"
        set "lpmakeCmd=!lpmakeCmd! --partition %%p_a:readonly:!size_a!:qti_dynamic_partitions"
        set "lpmakeCmd=!lpmakeCmd! --partition %%p_b:readonly:!size_b!:qti_dynamic_partitions"
        set "lpmakeCmd=!lpmakeCmd! --image=%%p_a=!imgFile!"

    ) else (
        set "hasMissing=1"
        set "missingList=!missingList! %%p.img"
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
    goto error 
)
set "lpmakeCmd=!lpmakeCmd! --output %superImg%"
cls
echo.
echo.
echo.
echo super各分区列表及大小：
type "%partInfoFile%"
del "%partInfoFile%" 2>nul
echo.
echo super.img 总大小为 %SUPER_SIZE% 字节 %pd0Dir% 至少保留 15GB 以上
echo -----------------------------------------------------------------------------
set /p confirm=确认开始打包？输入 n 取消，任意键继续: 
if /i "%confirm%"=="n" (
    echo 用户取消
    call :log "用户取消"
    goto error 
)


cmd /c "!lpmakeCmd!"
if errorlevel 1 (
    echo 打包失败！
    call :log "打包失败"
    goto error 
) 
echo -----------------------------------------------------------------------------
echo.
echo 打包成功！生成 %pd0Dir%super.img
call :log "打包成功，输出 %pd0Dir%super.img"
echo.
echo 只允许活动卡槽 A 刷写 super.img
echo.
echo -----------------------------------------------------------------------------
:error
echo 操作失败，按任意键退出...
exit /b 1

:log
echo %time% %~1 >> "%logFile%"
goto :eof