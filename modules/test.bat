@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
call "%modulesDir%header.bat" "%~nx0" "cls"


exit /b 0

:exitb1
call "%modulesDir%logger.bat" "%~nx0"  "Òì³£ÍË³ö"
exit /b 1