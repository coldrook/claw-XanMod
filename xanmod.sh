#!/bin/bash

set -e

# 检查是否为 root 用户
if [[ $EUID -ne 0 ]]; then
  echo "请使用 sudo 或 root 用户运行此脚本"
  exit 1
fi

# 安装 gpg
echo "正在安装 gpg..."
apt-get update
apt-get install -y gpg

# 添加 XanMod GPG 密钥
echo "正在添加 XanMod GPG 密钥..."
wget -qO - https://github.com/yumaoss/xanmod_tools/raw/refs/heads/main/archive.key | sudo gpg --dearmor -vo /usr/share/keyrings/xanmod-archive-keyring.gpg

# 添加 XanMod APT 源
echo "正在添加 XanMod APT 源..."
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list

# 更新 APT 索引
echo "正在更新 APT 索引..."
sudo apt update

# 检查 CPU 支持的 x86-64 PSABI
echo "正在检查 CPU 支持的 x86-64 PSABI..."

# 检查是否存在同名脚本，如果存在则删除
if [ -f "check_x86-64_psabi.sh" ]; then
  echo "发现旧的 check_x86-64_psabi.sh 脚本，正在删除..."
  rm "check_x86-64_psabi.sh"
fi

# 下载脚本
wget https://raw.githubusercontent.com/yumaoss/xanmod_tools/refs/heads/main/check_x86-64_psabi.sh

# 检查下载是否成功
if [ $? -ne 0 ]; then
  echo "下载 check_x86-64_psabi.sh 脚本失败，请检查网络连接。"
  exit 1
fi

# 赋予脚本执行权限
chmod +x check_x86-64_psabi.sh

# 执行脚本并捕获输出
PSABI_OUTPUT=$(./check_x86-64_psabi.sh)


# 根据 CPU 支持的 PSABI 安装内核
if echo "$PSABI_OUTPUT" | grep -q "CPU supports x86-64-v4"; then
  echo "CPU 支持 x86-64-v4，安装 linux-xanmod-x64v4 内核..."
  sudo apt install -y linux-xanmod-x64v4
elif echo "$PSABI_OUTPUT" | grep -q "CPU supports x86-64-v3"; then
  echo "CPU 支持 x86-64-v3，安装 linux-xanmod-x64v3 内核..."
  sudo apt install -y linux-xanmod-x64v3
elif echo "$PSABI_OUTPUT" | grep -q "CPU supports x86-64-v2"; then
  echo "CPU 支持 x86-64-v2，安装 linux-xanmod-x64v2 内核..."
  sudo apt install -y linux-xanmod-x64v2
else
  echo "CPU 不支持 x86-64-v2/v3/v4，无法选择最佳 XanMod 内核。将安装默认的 linux-xanmod-x64 内核。"
  sudo apt install -y linux-xanmod-x64
fi

# 清理下载的脚本
rm check_x86-64_psabi.sh

echo "安装完成！请重启系统以使用新的内核。"
