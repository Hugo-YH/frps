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
FRP_VERSION=0.62.1
REPO=stilleshan/frps
WORK_PATH=$(dirname $(readlink -f $0))
FRP_NAME=frps
FRP_PATH=/usr/local/frp
PROXY_URL="https://ghfast.top/"

# 检查是否已安装frps
if [ -f "/usr/local/frp/${FRP_NAME}" ] || [ -f "/usr/local/frp/${FRP_NAME}.toml" ] || [ -f "/lib/systemd/system/${FRP_NAME}.service" ];then
    echo -e "${Green}=========================================================================${Font}"
    echo -e "${RedBG}当前已退出脚本.${Font}"
    echo -e "${Green}检查到服务器已安装${Font} ${Red}${FRP_NAME}${Font}"
    echo -e "${Green}请手动确认和删除${Font} ${Red}/usr/local/frp/${Font} ${Green}目录下的${Font} ${Red}${FRP_NAME}${Font} ${Green}和${Font} ${Red}/${FRP_NAME}.toml${Font} ${Green}文件以及${Font} ${Red}/lib/systemd/system/${FRP_NAME}.service${Font} ${Green}文件,再次执行本脚本.${Font}"
    echo -e "${Green}参考命令如下:${Font}"
    echo -e "${Red}rm -rf /usr/local/frp/${FRP_NAME}${Font}"
    echo -e "${Red}rm -rf /usr/local/frp/${FRP_NAME}.toml${Font}"
    echo -e "${Red}rm -rf /lib/systemd/system/${FRP_NAME}.service${Font}"
    echo -e "${Green}=========================================================================${Font}"
    exit 2
fi

# 检查并杀死正在运行的frps进程
while ! test -z "$(ps -A | grep -w ${FRP_NAME})"; do
    FRPSPID=$(ps -A | grep -w ${FRP_NAME} | awk 'NR==1 {print $1}')
    kill -9 $FRPSPID
done

# 检查并安装wget和curl
if type apt-get >/dev/null 2>&1 ; then
    if ! type wget >/dev/null 2>&1 ; then
        apt-get install wget -y
    fi
    if ! type curl >/dev/null 2>&1 ; then
        apt-get install curl -y
    fi
fi

if type yum >/dev/null 2>&1 ; then
    if ! type wget >/dev/null 2>&1 ; then
        yum install wget -y
    fi
    if ! type curl >/dev/null 2>&1 ; then
        yum install curl -y
    fi
fi

# 检查网络连通性
GOOGLE_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "https://www.google.com")
PROXY_HTTP_CODE=$(curl -o /dev/null --connect-timeout 5 --max-time 8 -s --head -w "%{http_code}" "${PROXY_URL}")

# 检查系统架构
if [ $(uname -m) = "x86_64" ]; then
    PLATFORM=amd64
fi

if [ $(uname -m) = "aarch64" ]; then
    PLATFORM=arm64
fi

FILE_NAME=frp_${FRP_VERSION}_linux_${PLATFORM}

# 下载frps及配置文件
if [ ! -f "${WORK_PATH}/${FILE_NAME}.tar.gz" ]; then
    if [ $GOOGLE_HTTP_CODE == "200" ]; then
        wget -P ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
        wget -P ${WORK_PATH} https://raw.githubusercontent.com/${REPO}/master/${FRP_NAME}.toml -O ${FRP_NAME}.toml
    else
        if [ $PROXY_HTTP_CODE == "200" ]; then
            wget -P ${WORK_PATH} ${PROXY_URL}https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
            wget -P ${WORK_PATH} ${PROXY_URL}https://raw.githubusercontent.com/${REPO}/master/${FRP_NAME}.toml -O ${FRP_NAME}.toml
        else
            echo -e "${Red}检测 GitHub Proxy 代理失效 开始使用官方地址下载${Font}"
            wget -P ${WORK_PATH} https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME}.tar.gz -O ${FILE_NAME}.tar.gz
            wget -P ${WORK_PATH} https://raw.githubusercontent.com/${REPO}/master/${FRP_NAME}.toml -O ${FRP_NAME}.toml
        fi
    fi
else
    echo -e "${Green}文件 ${FILE_NAME}.tar.gz 已存在, 跳过下载.${Font}"
fi

# 解压并移动文件到指定目录
tar -zxvf ${FILE_NAME}.tar.gz
mkdir -p ${FRP_PATH}
mv ${FILE_NAME}/${FRP_NAME} ${FRP_PATH}
mv ${FRP_NAME}.toml ${FRP_PATH}

# 配置 systemd 服务
cat >/lib/systemd/system/frps.service <<'EOF'
[Unit]
Description=Frp Server Service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/frp/frps -c /usr/local/frp/frps.toml

[Install]
WantedBy=multi-user.target

EOF

# 重新加载 systemd 配置并启动服务
systemctl daemon-reload
sudo systemctl start ${FRP_NAME}
sudo systemctl enable ${FRP_NAME}

# 清理安装文件
rm -rf ${WORK_PATH}/${FILE_NAME}.tar.gz ${WORK_PATH}/${FILE_NAME} ${FRP_NAME}_linux_install.sh

# 输出安装成功提示
echo -e "${Green}====================================================================${Font}"
echo -e "${Green}安装成功,请先修改 ${FRP_NAME}.toml 文件,确保格式及配置正确无误!${Font}"
echo -e "${Red}vi /usr/local/frp/${FRP_NAME}.toml${Font}"
echo -e "${Green}修改完毕后执行以下命令重启服务:${Font}"
echo -e "${Red}sudo systemctl restart ${FRP_NAME}${Font}"
echo -e "${Green}====================================================================${Font}"
