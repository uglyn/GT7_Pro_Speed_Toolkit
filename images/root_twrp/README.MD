# TWRP recovery.img 对应源码说明

本 recovery.img 由原作者 [kmiit](https://github.com/kmiit) 移植编译，适用于 oplus/sm87xx 设备（如 OnePlus 13T 等）。

## 源码来源（GPLv3 对应）

- **TWRP 核心源码（Manifest）**：  
  `https://github.com/TWRP-Test/platform_manifest_twrp_aosp`  
  分支：`twrp-16.0`

- **设备树源码（Device Tree）**：  
  `https://github.com/kmiiit/twrp_device_oplus_sm87xx`  
  分支：`twrp-16.0`

## 编译信息（来自原作者 Release）

- 设备路径：`oplus/sm87xx`
- 设备名称：`sm87xx`
- 构建目标：`recovery.img`
- 构建日期：`Sun Mar 22 08:49:21 UTC 2026`

## 如何获取完整源码并编译

请参照 TWRP 官方文档：https://twrp.me 或 AOSP 编译指南。

使用以下命令同步代码：
```bash
repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp -b twrp-16.0
repo sync
# 将设备树放入 device/oplus/sm87xx 目录
source build/envsetup.sh
lunch twrp_sm87xx-eng
make recoveryimage