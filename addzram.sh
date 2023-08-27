#!/bin/bash
#From https://github.com/spiritLHLS/addzram
#Channel: https://t.me/vps_reviews
#2023.08.27

utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
  echo "No UTF-8 locale found"
else
  export LC_ALL="$utf8_locale"
  export LANG="$utf8_locale"
  export LANGUAGE="$utf8_locale"
  echo "Locale set to $utf8_locale"
fi

# 自定义字体彩色和其他配置
Green="\033[32m"
Font="\033[0m"
Red="\033[31m"
_red() { echo -e "\033[31m\033[01m$@\033[0m"; }
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }
_yellow() { echo -e "\033[33m\033[01m$@\033[0m"; }
_blue() { echo -e "\033[36m\033[01m$@\033[0m"; }
reading() { read -rp "$(_green "$1")" "$2"; }

# 必须以root运行脚本
check_root() {
  [[ $(id -u) != 0 ]] && _red " The script must be run as root, you can enter sudo -i and then download and run again." && exit 1
}

add_zram() {
  _green "Please configure and add zram with the size of half the available memory!"
  _green "请输入需要添加的zram，建议为内存的一半！"
  _green "Please enter the zram value in megabytes (MB) (leave blank and press Enter for default, which is half of the memory):"
  reading "请输入zram数值，以MB计算(留空回车则默认为内存的一半):" zram_size
  if [ -z "$zram_size" ]; then
    total_memory=$(free -m | awk '/^Mem:/{print $2}')
    zram_size=$((total_memory / 2))
  fi
  if ! lsmod | grep -q zram; then
    echo "Loading zram module..."
    modprobe zram
  fi
  if ! command -v zramctl >/dev/null; then
    _yellow "zramctl command not found. Please make sure zramctl is installed."
    exit 1
  fi
  if ! command -v mkswap >/dev/null || ! command -v swapon >/dev/null; then
    _yellow "mkswap or swapon command not found. Please make sure these commands are installed."
    exit 1
  fi
  zramctl /dev/zram0 --algorithm zstd --size "${zram_size}M"
  mkswap /dev/zram0
  swapon --priority 100 /dev/zram0
  echo "ZRAM setup complete. ZRAM device /dev/zram0 with size ${zram_size}M and algorithm zstd is now active as swap."
  echo "ZRAM 设置成功，ZRAM 设备路径为 /dev/zram0 大小为 ${zram_size}M 同时 zstd 已激活成为swap的一部分"
  check_zram
}

del_zram() {
  swapoff /dev/zram0
  zramctl --reset /dev/zram0
  check_zram
}

check_zram() {
  zramctl 2>/dev/null
  swapon --show
}

#开始菜单
main() {
  check_root
  check_zram
  clear
  free -m
  echo -e "—————————————————————————————————————————————————————————————"
  echo -e "${Green}Linux VPS one click add/remove zram script ${Font}"
  echo -e "${Green}1, Add zram${Font}"
  echo -e "${Green}2, Remove zram${Font}"
  echo -e "—————————————————————————————————————————————————————————————"
  while true; do
    _green "Please enter a number"
    reading "请输入数字 [1-2]:" num
    case "$num" in
    1)
      add_zram
      break
      ;;
    2)
      del_zram
      break
      ;;
    *)
      echo "输入错误，请重新输入"
      ;;
    esac
  done
}

main