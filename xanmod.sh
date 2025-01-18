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

# 5. 检查 CPU 支持的 x86-64 ABI
echo "5. 检查 CPU 支持的 x86-64 ABI..."

cpu_abi_check() {
  local awk_script='BEGIN { while (!/flags/) if (getline < "/proc/cpuinfo" != 1) exit 1;
    if (/lm/ && /cmov/ && /cx8/ && /fpu/ && /fxsr/ && /mmx/ && /syscall/ && /sse2/) level = 1;
    if (level == 1 && /cx16/ && /lahf/ && /popcnt/ && /sse4_1/ && /sse4_2/ && /ssse3/) level = 2;
    if (level == 2 && /avx/ && /avx2/ && /bmi1/ && /bmi2/ && /fma/ && /movbe/ && /xsave/ && /xsaveopt/) level = 3;
    if (level == 3 && /avx512f/ && /avx512cd/ && /avx512dq/ && /avx512bw/ && /avx512vl/) level = 4;
    if (level > 0) { print "CPU supports x86-64-v" level; exit level + 1 }
    exit 1 }'
  awk "$awk_script"
}

cpu_abi_output=$(cpu_abi_check)
cpu_abi_level=$(echo "$cpu_abi_output" | grep -o '[0-9]$')

echo "CPU ABI 检测结果："
echo "$cpu_abi_output"
echo "提取的 ABI Level: $cpu_abi_level"

# 在这里暂停执行
read -p "按 Enter 继续安装内核..."

# 6. 根据 CPU 支持安装相应的 XanMod 内核
echo "6. 根据 CPU 支持安装 XanMod 内核..."
case "$cpu_abi_level" in
  4)
    echo "CPU 支持 x86-64-v4，安装 linux-xanmod-x64v4"
    sudo apt install -y linux-xanmod-x64v4
    ;;
  3)
    echo "CPU 支持 x86-64-v3，安装 linux-xanmod-x64v3"
    sudo apt install -y linux-xanmod-x64v3
    ;;
  2)
    echo "CPU 支持 x86-64-v2，安装 linux-xanmod-x64v2"
    sudo apt install -y linux-xanmod-x64v2
    ;;
  *)
    echo "CPU 不支持 x86-64-v4/v3/v2，无法安装 XanMod 内核。"
    echo "请检查 CPU 支持并手动选择合适的内核。"
    exit 1
    ;;
esac

# 7. 清理临时文件
echo "7. 清理临时文件..."
#rm check_x86-64_psabi.sh # No such file

echo "XanMod 内核安装完成！请重启系统以使用新内核。"
