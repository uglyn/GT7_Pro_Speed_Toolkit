@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

:del_proj
cls
echo.
echo ================== [ 删除现有工程 ] ==================
echo.
set "projCount=0"

:: 遍历并显示带序号的列表
for /d %%d in ("!workDir!*") do (
    set /a projCount+=1
    set "projName[!projCount!]=%%~nxd"
    echo   !projCount!. %%~nxd
)

echo.
echo   0. 取消返回
echo ==================================================
set "delCh=qq11066851"
set /p "delCh=请输入要删除的工程序号: "

:: 去引号
set "delCh=%delCh:"=%"

:: 空输入或 0 直接取消
if "!delCh!"=="" goto timeout
if "!delCh!"=="0" exit /b 0


:: 输入必须为纯数字
for /f "delims=0123456789" %%a in ("!delCh!") do goto timeout

:: 序号必须存在
if not defined projName[!delCh!] goto timeout

:: 查表取值
set "delProjName=!projName[%delCh%]!"

:: 确认环节
echo.
choice /c YN /m "确定要彻底删除工程 !delProjName! 吗"
if errorlevel 2  (
echo 已取消删除。
call "%modulesDir%usertimeout.bat"
goto del_proj
)

:: 执行删除
rd /s /q "!workDir!!delProjName!" 2>nul

:: 不管 errorlevel，直接看文件夹还在不在
if exist "!workDir!!delProjName!\" goto del_fail

:del_success
echo.
echo [成功] 工程 "!delProjName!" 已彻底删除！
call "%modulesDir%logger.bat" "%~nx0" "删除项目成功:!delProjName!"
call "%modulesDir%usertimeout.bat"
goto del_proj

:del_fail
echo.
echo [错误] 删除失败！可能有文件正在被占用，或者权限不足。
call "%modulesDir%logger.bat" "%~nx0" "删除项目失败:!delProjName!"
call "%modulesDir%usertimeout.bat"
goto del_proj

:timeout
call "%modulesDir%logger.bat" "%~nx0" "删除项目输入不合法:!delCh!"
call "%modulesDir%usertimeout.bat" "请输入正确的工程序号"
goto del_proj