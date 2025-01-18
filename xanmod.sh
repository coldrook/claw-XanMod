#!/bin/bash

set -e # 脚本出错时立即退出

echo "开始安装 XanMod 内核..."

# 1. 安装 gpg
echo "1. 安装 gpg..."
sudo apt-get update
sudo apt-get install -y gpg

# 2. 添加 XanMod GPG 密钥
echo "2. 添加 XanMod GPG 密钥..."
wget -qO - https://github.com/yumaoss/xanmod_tools/raw/refs/heads/main/archive.key | sudo gpg --dearmor -vo /usr/share/keyrings/xanmod-archive-keyring.gpg

# 3. 添加 XanMod 仓库
echo "3. 添加 XanMod 仓库..."
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list

# 4. 更新 apt 仓库列表
echo "4. 更新 apt 仓库列表..."
sudo apt update

# 5. 下载并执行 CPU 检查脚本
echo "5. 检查 CPU 支持的 x86-64 ABI..."
wget https://raw.githubusercontent.com/yumaoss/xanmod_tools/refs/heads/main/check_x86-64_psabi.sh
chmod +x check_x86-64_psabi.sh
OUTPUT=$(./check_x86-64_psabi.sh)

# 6. 根据 CPU 支持安装相应的 XanMod 内核
echo "6. 根据 CPU 支持安装 XanMod 内核..."
if grep -q "CPU supports x86-64-v4" <<< "$OUTPUT"; then
  echo "CPU 支持 x86-64-v4，安装 linux-xanmod-x64v4"
  sudo apt install -y linux-xanmod-x64v4
elif grep -q "CPU supports x86-64-v3" <<< "$OUTPUT"; then
  echo "CPU 支持 x86-64-v3，安装 linux-xanmod-x64v3"
  sudo apt install -y linux-xanmod-x64v3
elif grep -q "CPU supports x86-64-v2" <<< "$OUTPUT"; then
  echo "CPU 支持 x86-64-v2，安装 linux-xanmod-x64v2"
  sudo apt install -y linux-xanmod-x64v2
else
  echo "CPU 不支持 x86-64-v4/v3/v2，无法安装 XanMod 内核。"
  echo "请检查 CPU 支持并手动选择合适的内核。"
  exit 1
fi

# 7. 清理临时文件
echo "7. 清理临时文件..."
rm check_x86-64_psabi.sh

echo "XanMod 内核安装完成！请重启系统以使用新内核。"
