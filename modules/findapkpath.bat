@echo off
chcp 936 >nul
setlocal enabledelayedexpansion
title 系统APP真实路径查询
call "%modulesDir%logger.bat" "%~nx0"  "脚本启动"
cls
call "%modulesDir%wait_fastboot_device.bat" adb || exit /b 1
echo.
echo 正在检测 Root 权限...
:: 检测 su 权限，静默执行
%adbp% shell "su -c ""id""" 2>nul | findstr "uid=0" >nul
if errorlevel 1 (
    echo [警告] 未获取 Root 权限！第 2 步暴力搜索可能失败。
    echo 请在手机root管理器授权 shell Root 权限
    call "%modulesDir%usertimeout.bat" 
)

:input_pkg
cls

echo --------------------------------------------------------------------------------------
echo.
echo(MT管理器 已安装应用--找到包名 类似:com.coloros.securepay
echo.
echo --------------------------------------------------------------------------------------
set "pkg=qq11066851"
set /p "pkg=请输入要查询原厂路径的包名 (如 com.heytap.market): "
echo.
set "pkg=%pkg:"=%"
if "!pkg!"=="" goto input_pkg
if "!pkg!"=="qq11066851" goto input_pkg

echo.
echo [1/2] 正在查询底层路径记录 (dumpsys)...
%adbp% shell dumpsys package !pkg! | findstr /i /C:"codePath" /C:"resourcePath" /C:"legacyPath"
echo.

echo [2/2] 尝试在系统分区中暴力搜索 (需要Root)...
:: 提取包名最后的关键词，比如 com.heytap.market -> market
set "keyword=!pkg:.=!"
set "keyword=!keyword:com=!"
set "keyword=!keyword:heytap=!"
set "keyword=!keyword:oppo=!"
set "keyword=!keyword:coloros=!"

echo 正在搜索包含 [ !keyword! ] 字样的文件夹...
%adbp% shell "su -c 'find /my_stock /my_product /system_ext /system /product -type d -iname \"*!keyword!*\" 2>/dev/null'"
echo.

echo ===================================================
echo 查询完毕！
echo ===================================================
echo 按任意键继续查询下一个，或直接关闭窗口退出...
del "%pd0Dir%toolbox_busy.lock" 2>nul
pause >nul
goto input_pkg