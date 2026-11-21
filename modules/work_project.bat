@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0"  "cls"
type nul > "%tempDir%toolbox_busy.unlock" 2>nul

:menu_main
cls
echo.
echo ================== [ 工程管理 ] ==================
echo.
set "projCount=0"

:: 扫描 work 目录下的子文件夹
for /d %%d in ("!workDir!*") do (
    set /a projCount+=1
    set "projName[!projCount!]=%%~nxd"
)

echo 可用项目:
echo(----------
for /l %%i in (1,1,!projCount!) do (
    echo(        %%i. !projName[%%i]!
)
echo.
echo(----菜单: 
echo.
echo(   [P]. 打开所有工程所在的文件夹
echo(   [A]. 添加工程 (新建文件夹)
echo(   [D]. 删除工程
echo(   [B]. 返回主菜单
echo ==================================================
set "ch=qq11066851"
set /p "ch=请输入序号进入项目: "
echo.
set "ch=%ch:"=%"
if "!ch!"=="qq11066851" goto timeout
if "!ch!"=="" goto timeout
if /i  "!ch!"=="P" goto open_dir
if /i   "!ch!"=="A" goto call_add
if /i   "!ch!"=="D" goto call_del
if /i   "!ch!"=="B" exit /b 0

:: 输入必须为纯数字
for /f "delims=0123456789" %%a in ("!ch!") do goto timeout

:: 序号必须存在
if not defined projName[!ch!] goto timeout

:: 合法序号，进入项目（内层用 %ch% 提前展开，避免嵌套 !）
set "currentProj=!workDir!!projName[%ch%]!"
set "currentProjName=!projName[%ch%]!"
goto call_unpack

:timeout
call "%modulesDir%logger.bat" "%~nx0" "输入不合法:!ch!"
call "%modulesDir%usertimeout.bat" "输入不合法:!ch!"
goto menu_main

:open_dir
start "" "!workDir!"
goto menu_main

:call_add
call "%modulesDir%add_project.bat"
goto menu_main

:call_del
call "%modulesDir%del_project.bat"
goto menu_main

:call_unpack
call "%modulesDir%work_unpack.bat" "!currentProj!" "!currentProjName!"
if errorlevel 99 exit /b 99
if errorlevel 20 goto call_pack
goto menu_main

:call_pack
call "%modulesDir%work_pack.bat" "!currentProj!" "!currentProjName!"
if errorlevel 99 exit /b 99
if errorlevel 20 goto call_unpack
goto menu_main