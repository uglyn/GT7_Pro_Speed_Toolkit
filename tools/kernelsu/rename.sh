#!/system/bin/sh
# 切换到当前脚本所在目录
cd "$(dirname "$0")" || exit 1

echo "正在处理 .ko 文件..."
for file in lkm-aarch64-*.ko; do
    [ -e "$file" ] || continue
    new_file="${file#lkm-aarch64-}"
    mv -v "$file" "$new_file"
done

echo "正在处理 ksuinit..."
[ -f "ksuinit-aarch64.bin" ] && mv -v "ksuinit-aarch64.bin" "ksuinit"

echo "正在处理 ksud.exe..."
[ -f "ksud-x86_64-pc-windows-gnu.exe" ] && mv -v "ksud-x86_64-pc-windows-gnu.exe" "ksud.exe"

echo "全部处理完毕！"