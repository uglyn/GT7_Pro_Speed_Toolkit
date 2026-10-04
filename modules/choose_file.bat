@echo      off
chcp 936 >nul
setlocal enableDelayedExpansion
call "%modulesDir%header.bat" "%~nx0" "" ""

if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set "_outVar=%~1"

call :log "拦截手速太快的"
choice /c x /n /t 1 /d x /m "输入已接收，正在继续..."
:loop
cls
echo.
echo      ---------------------------- 拖入 %~2 文件 ------------------------ 
echo.       
echo       [0] win11 如果无法拖入 请先复制%~2文件，按shift 然后在cmd窗口右键粘贴
echo.
echo       [1]请将%~2文件拖入此处下方（或手动输入完整路径）
echo.
echo       [2]只能拖入 %~2 文件 不要拖入奇奇怪怪的文件
echo      ------------------------------------------------------------------------------------
echo      输入%~2文件的路径:
echo      ------------------------------------------------------------------------------------
set "chosenFile="
set /p "chosenFile=.     .[拖入之后按回车]:"

set "chosenFile=!chosenFile:"=!"
call :log "goto loop"
if "!chosenFile!"== "" goto  loop
if "!chosenFile!"== "\" goto  loop
if not exist "!chosenFile!" goto  loop
if   exist "!chosenFile!\" goto  loop


echo.
echo 已使用文件:!chosenFile!
call :log "使用!chosenFile! "
echo.
endlocal & set "%_outVar%=%chosenFile%"
timeout /t 1
exit /b 0

:usage
echo      错误:  "文件名字变量" "文件类型"
exit /b 1

:log
echo      %time% %~1>> "%logFile%"
goto :eof
