@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

if "%~1"=="" goto exitb1
if "%~2"=="" goto exitb1

set "_outVar=%~1"

call "%modulesDir%logger.bat" "%~nx0"  "拦截手速太快的"
choice /c x /n /t 1 /d x /m " 正在继续...  丢失焦点会卡住 请手动按 x 继续..."

:loop
if "%_outVar%"=="qq11066851"   (
:timeout
echo(   *******请拖入正确的文件******** 
call "%modulesDir%logger.bat" "%~nx0"  "请输入拖入正确的文件路径:%chooseFile%"
call "%modulesDir%usertimeout.bat" "%chooseFile%"
)
cls
echo.
echo.
echo(     ---------------------------- 拖入 [%~2]  文件------------------------ 
echo.       
echo(      [0] win11 如果无法拖入 请先复制%~2文件，按shift 然后在cmd窗口右键粘贴
echo.
echo(      [1]请将%~2文件拖入此处下方（或手动输入完整路径）
echo.
echo(      [2]只能拖入 %~2 文件 不要拖入奇奇怪怪的文件
echo.
echo(      [3]这个工具箱  一般只用到.bin  .zip  .img 文件
echo.
echo(      [4]输入%~2文件的路径:
echo(----------------------------------------------------------------------------------------------
set "chooseFile=qq11066851"
set /p "chooseFile=      .[拖入之后按回车]:"
echo.
echo(-------------------------------------------------------------------------
set "chooseFile=%chooseFile:"=%"
if "%chooseFile%"=="" goto timeout
if not "%chooseFile:~1,1%"==":" goto timeout
if not exist "%chooseFile%"  goto timeout
if /i "%chooseFile:~-4%"==".lnk" (
	echo(   *******不支持快捷方式呀******** 
                call "%modulesDir%logger.bat" "%~nx0"  "不支持快捷方式:%userDir%"
                goto timeout
)

rem 3. 提取属性，判断是否为文件 
set "attr="
for %%I in ("%chooseFile%") do set "attr=%%~aI"
if /I "%attr:~0,1%"=="d" (
    call "%modulesDir%logger.bat" "%~nx0"  "拦截文件夹:[%chooseFile%]"
    echo(   *******请不要拖入文件夹********
    goto timeout
)

echo.
call "%modulesDir%usertimeout.bat" "你选择的文件:%chooseFile%"
call "%modulesDir%logger.bat" "%~nx0"  "使用%chooseFile%"
endlocal & set "%_outVar%=%chooseFile%"
exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "异常退出"
exit /b 1

