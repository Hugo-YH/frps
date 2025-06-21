#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 字体颜色定义
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
# 字体颜色定义结束

# 变量定义
WORK_PATH=$(dirname $(readlink -f $0))
FRP_NAME=frps
FRP_VERSION=0.62.1
FRP_PATH=/usr/local/frp

# 停止frps服务
sudo systemctl stop ${FRP_NAME}
sudo systemctl disable ${FRP_NAME}
# 删除frps安装目录及文件
rm -rf ${FRP_PATH}
# 删除frps的systemd服务文件
rm -rf /lib/systemd/system/${FRP_NAME}.service
# 重新加载systemd配置
sudo systemctl daemon-reload
# 删除本卸载脚本
rm -rf ${FRP_NAME}_linux_uninstall.sh

# 输出卸载成功提示
echo -e "${Green}============================${Font}"
echo -e "${Green}卸载成功,相关文件已清理完毕!${Font}"
echo -e "${Green}============================${Font}"
