# GT7_Pro_Speed_Toolkit
一、工具箱简介

本工具箱是为真我 GT7 Pro 竞速版 开发的玩机辅助工具，主要用于刷机、Root、分区管理等功能。

二、主要功能

1. 一键 Root（KernelSU LKM 模式）
2. 手动刷写分区
3. 修复 fastbootD 模式
4. 打包 super.img
5. 刷写 super 分区
6. 从 payload.bin 提取分区
7. 卡刷包线刷
8. 刷写空白 super.img
9. 驱动状态检测

三、免责声明

刷机、修改系统分区等操作具有极高风险，可能导致设备变砖、数据丢失或保修失效。
使用本工具即表示您已阅读并同意自行承担一切操作后果。
作者不对任何设备损坏、数据丢失或其它损失负责。

四、文件配置说明


本工具箱只包含脚本和配置文件，所有二进制工具和镜像文件需要您自行准备并放在正确的位置。

一、工具存放位置（tools文件夹）

adb.exe 和 fastboot.exe
下载自 Google Platform Tools
放置到 tools\platform-tools\ 文件夹中

ksud.exe
从 KernelSU 的 GitHub Actions 页面获取
放置到 tools\kernelsu\ 文件夹中

kernelsu.ko
从 KernelSU 的 GitHub Actions 页面获取对应您手机KMI的版本
放置到 tools\kernelsu\ 文件夹中

payload-dumper-go.exe
从 GitHub Releases 下载 windows_amd64 版本
放置到 tools\payload-dumper-go\ 文件夹中

lpmake.exe
从 tools\thka2016\ 文件夹中复制一份
放置到 tools\lpmake\ 文件夹中
也可以直接使用 thka2016 文件夹中的 lpmake.exe，脚本会自动找到

二、镜像文件存放位置（images文件夹）

recovery.img
您使用的 TWRP 或其他 Recovery 镜像
必须命名为 recovery.img
放置在 images\root_twrp\ 文件夹中



其他镜像文件
my_preload.img 和my_company.img
存放 images\system\ 文件夹中

三、配置文件说明（config文件夹）
一般为固定的一些信息。
root_twrp.txt
每行一个分区名，不带 .img 后缀
默认内容为：
recovery
init_boot

super.txt
每行一个子分区名，不带 .img 后缀
用于打包 super.img

四、其他文件夹

apk 文件夹用于存放 KernelSU 的 APK 安装包
drivers 文件夹用于存放 USB 驱动
logs 和 temp 文件夹由脚本自动生成，无需手动创建

完成以上配置后，运行 点我打开工具箱.bat 即可使用。