@echo off
setlocal
call "%modulesDir%header.bat" "%~nx0"  "" ""

if not "%~1"=="" if not "%~2"=="" goto params_ok
echo 错误:  "文件名字变量" "文件类型" 
exit /b 1

:params_ok
set "_outVar=%~1"

:loop
echo -----------------------------------------------------------------------------
echo [win11]请先复制%~2文件，按shift 然后在cmd窗口右键粘贴（或直接拖入文件）
echo.
echo 请将%~2文件拖入此处下方（或手动输入完整路径）
echo -----------------------------------------------------------------------------
set /p "chosenFile=输入%~2文件的路径[之后按回车]:"
choice /c x /n /t 1 /d x /m "输入已接收，正在继续..."
set "chosenFile=%chosenFile:"=%"  
if exist "%chosenFile%" (
    endlocal & set "%_outVar%=%chosenFile%"
    exit /b 0
)
echo 文件不存在，请重新输入。
goto loop