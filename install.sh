#!/bin/bash
# ================================================
# 铭泽跨境 - 全网最强代理管理脚本 (MZProxy-Master)
# Copyright © 2025 铭泽跨境. All rights reserved.
# 技术支持: 微信 a114447773
# 特性: 全协议支持 | GOST中转 | BBR加速 | 防封配置
# ================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示横幅
show_banner() {
 clear
 echo -e "${PURPLE}"
 echo "╔═══════════════════════════════════════════════════════════╗"
 echo "║                                                           ║"
 echo "║  ███╗   ███╗███████╗ ██████╗ ██████╗ ██████╗ ██╗  ██╗    ║"
 echo "║  ████╗ ████║╚══███╔╝██╔═══██╗██╔══██╗██╔═══██╗╚██╗██╔╝    ║"
 echo "║  ██╔████╔██║  ███╔╝ ██║   ██║██████╔╝██║   ██║ ╚███╔╝     ║"
 echo "║  ██║╚██╔╝██║ ███╔╝  ██║   ██║██╔══██╗██║   ██║ ██╔██╗     ║"
 echo "║  ██║ ╚═╝ ██║███████╗╚██████╔╝██║  ██║╚██████╔╝██╔╝ ██╗    ║"
 echo "║  ╚═╝     ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝    ║"
 echo "║                                                           ║"
 echo "║          铭泽跨境 - 全网最强代理管理脚本 v5.0              ║"
 echo "║        Copyright © 2025 铭泽跨境. All rights reserved.    ║"
 echo "║               技术支持: 微信 a114447773                   ║"
 echo "║                                                           ║"
 echo "╚═══════════════════════════════════════════════════════════╝"
 echo -e "${NC}"
}

# 安装基础依赖
install_dependencies() {
 echo -e "${YELLOW}[1/5] 正在安装基础依赖...${NC}"
 if command -v apt &> /dev/null; then
 apt update -qq
 apt install -y wget curl jq tar gzip net-tools ufw socat
 elif command -v yum &> /dev/null; then
 yum install -y wget curl jq tar gzip net-tools firewalld socat
 fi
 echo -e "${GREEN}✓ 基础依赖安装完成！${NC}"
}

# 安装 BBR 加速（安全模式：不换内核，仅启用）
install_bbr() {
 echo -e "${YELLOW}[2/5] 正在配置 BBR 加速（安全模式）...${NC}"
 
 # 仅启用现有内核的 BBR，不安装新内核（避免重启）
 echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
 echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
 sysctl -p > /dev/null 2>&1
 
 # 验证
 if lsmod | grep -q bbr; then
 echo -e "${GREEN}✓ BBR 加速已启用（无需重启）${NC}"
 else
 echo -e "${YELLOW}⚠ BBR 未加载（需手动重启后生效）${NC}"
 fi
}

# 安装 X-UI 面板（全协议支持）
install_xui() {
 echo -e "${YELLOW}[3/5] 正在安装 X-UI 代理面板（全协议版）...${NC}"
 echo -e "${CYAN}支持协议: VLESS/VMess/Trojan/Shadowsocks/Hysteria2/TUIC${NC}"
 
 # 使用功能最全的 X-UI 版本
 bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
 
 echo -e "${GREEN}✓ X-UI 面板安装完成！${NC}"
 echo -e "${YELLOW}访问地址: http://你的服务器IP:54321${NC}"
 echo -e "${YELLOW}默认账号: admin | 默认密码: admin${NC}"
}

# 安装 GOST 中转工具
install_gost() {
 echo -e "${YELLOW}[4/5] 正在安装 GOST 中转工具...${NC}"
 
 # 下载最新版 GOST
 ARCH=$(uname -m)
 [ "$ARCH" = "x86_64" ] && ARCH="amd64"
 [ "$ARCH" = "aarch64" ] && ARCH="arm64"
 
 GOST_VER=$(curl -s https://api.github.com/repos/ginuerzh/gost/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
 wget -q "https://github.com/ginuerzh/gost/releases/download/${GOST_VER}/gost-linux-${ARCH}-${GOST_VER}.tar.gz"
 tar -xzf gost-linux-${ARCH}-${GOST_VER}.tar.gz
 mv gost-linux-${ARCH} /usr/local/bin/gost
 chmod +x /usr/local/bin/gost
 rm -f gost-linux-${ARCH}-${GOST_VER}.tar.gz
 
 # 创建系统服务
 cat > /etc/systemd/system/gost.service << EOF
[Unit]
Description=GOST Tunnel Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/gost -L=tcp://:8080
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
 
 systemctl daemon-reload
 systemctl enable gost
 echo -e "${GREEN}✓ GOST 中转工具安装完成！${NC}"
}

# 防封安全配置
setup_security() {
 echo -e "${YELLOW}[5/5] 正在配置防封安全策略...${NC}"
 
 # 1. 防火墙配置
 if command -v ufw &> /dev/null; then
 ufw default deny incoming
 ufw default allow outgoing
 ufw allow 22/tcp
 ufw allow 443,8443,8080/tcp
 ufw --force enable
 fi
 
 # 2. 防扫描配置
 echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
 echo "net.ipv4.tcp_max_syn_backlog = 2048" >> /etc/sysctl.conf
 sysctl -p > /dev/null
 
 # 3. 防封建议
 echo -e "${CYAN}════════════ 防封关键建议 ════════════${NC}"
 echo -e "${YELLOW}1. 在 X-UI 中优先使用:${NC}"
 echo -e " • VLESS + Reality (最推荐)"
 echo -e " • Trojan + TLS (次推荐)"
 echo -e "${YELLOW}2. 避免使用:${NC}"
 echo -e " • 裸奔的 VMess/VLESS (无TLS)"
 echo -e " • 常见端口 443/8443 (可改为随机高位端口)"
 echo -e "${YELLOW}3. 高级防护:${NC}"
 echo -e " • 使用域名 + CDN (Cloudflare)"
 echo -e " • 配置 Nginx 反向代理"
 echo -e "${CYAN}══════════════════════════════════════${NC}"
 
 echo -e "${GREEN}✓ 安全配置完成！${NC}"
}

# 一键安装所有
install_all() {
 show_banner
 echo -e "${CYAN}开始安装铭泽跨境全网最强代理套件...${NC}"
 echo -e "${CYAN}预计时间: 3-5分钟 (取决于网络)${NC}"
 echo ""
 
 install_dependencies
 install_bbr
 install_xui
 install_gost
 setup_security
 
 echo -e "${PURPLE}════════════ 安装完成 ════════════${NC}"
 echo -e "${GREEN}✅ 铭泽跨境代理套件安装完成！${NC}"
 echo ""
 echo -e "${YELLOW}🎯 核心服务:${NC}"
 echo -e " • X-UI 面板: http://你的服务器IP:54321"
 echo -e " • GOST 中转: 已安装，配置文件 /etc/systemd/system/gost.service"
 echo ""
 echo -e "${YELLOW}🔧 管理命令:${NC}"
 echo -e " • X-UI状态: systemctl status x-ui"
 echo -e " • GOST状态: systemctl status gost"
 echo -e " • 查看BBR: sysctl net.ipv4.tcp_congestion_control"
 echo ""
 echo -e "${YELLOW}📞 技术支持: 微信 a114447773${NC}"
 echo -e "${PURPLE}══════════════════════════════════${NC}"
}

# 主菜单
main_menu() {
 show_banner
 echo -e "${CYAN}请选择安装模式:${NC}"
 echo "1. 一键安装所有组件 (推荐)"
 echo "2. 仅安装 BBR 加速"
 echo "3. 仅安装 X-UI 面板"
 echo "4. 仅安装 GOST 中转"
 echo "5. 防封安全配置"
 echo "6. 查看服务状态"
 echo "7. 退出脚本"
 echo ""
 read -p "请输入数字 [1-7]: " choice
 
 case $choice in
 1) install_all ;;
 2) install_bbr ;;
 3) install_xui ;;
 4) install_gost ;;
 5) setup_security ;;
 6) 
 echo -e "${YELLOW}服务状态:${NC}"
 systemctl status x-ui --no-pager 2>/dev/null || echo "X-UI 未安装"
 systemctl status gost --no-pager 2>/dev/null || echo "GOST 未安装"
 ;;
 7) 
 echo -e "${GREEN}感谢使用铭泽跨境代理管理脚本！${NC}"
 exit 0
 ;;
 *) 
 echo -e "${RED}无效选择！${NC}"
 sleep 1
 ;;
 esac
 
 echo ""
 read -p "按回车键返回菜单..."
 main_menu
}

# 脚本入口
main() {
 # 检查 root 权限
 if [ "$EUID" -ne 0 ]; then
 echo -e "${RED}请使用 root 权限运行此脚本！${NC}"
 exit 1
 fi
 
 # 如果是自动安装模式
 if [ "$1" = "auto" ]; then
 install_all
 else
 main_menu
 fi
}

main "$@"
