@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" 

:add_proj
cls
echo.
echo ================== [ 添加新工程 ] ==================
echo   提示: 建议使用英文或数字命名，避免特殊符号
echo.
set "newProj=qq11066851"
set /p "newProj=请输入工程名称: "
echo.
set "newProj=%newProj:"=%"
if "!newProj!"=="" goto timeout
if "!newProj!"=="qq11066851" goto timeout
:: 检查是否已经存在同名文件夹
if exist "!workDir!!newProj!\" (
    echo [错误] 工程 "!newProj!" 已存在，请换个名字！
    goto timeout
)

:: 创建文件夹
mkdir "!workDir!!newProj!" 2>nul

if errorlevel 1 (
    echo [错误] 创建失败！可能是名称包含非法字符
    goto add_proj
)
echo.
echo [成功] 工程 "!newProj!" 已创建！
call "%modulesDir%logger.bat" "%~nx0" "添加项目成功"
call "%modulesDir%usertimeout.bat"
exit /b 0

:timeout
call "%modulesDir%logger.bat" "%~nx0" "添加项目:!newProj!"
call "%modulesDir%usertimeout.bat" "请输入正确的工程名"
goto add_proj