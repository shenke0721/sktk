#!/bin/bash
# ================================================
# 铭泽跨境 - 全网最强代理管理脚本 (最终小白版)
# 专为小白用户设计，一键安装，零配置
# Copyright © 2025 铭泽跨境. All rights reserved.
# 技术支持: 微信 a114447773
# 版本: v6.3
# ================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 全局变量
SCRIPT_VERSION="6.3"
LOG_FILE="/var/log/mzproxy.log"
CONFIG_FILE="/etc/mzproxy/config.json"

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
    echo "║          铭泽跨境 - 全网最强代理管理脚本 (v$SCRIPT_VERSION)  ║"
    echo "║         ⭐ 专为小白设计，一键安装，零基础操作 ⭐         ║"
    echo "║        Copyright © 2025 铭泽跨境. All rights reserved.    ║"
    echo "║               技术支持: 微信 a114447773                   ║"
    echo "║                                                           ║"
    echo "║         📦 功能: 代理面板 + 中转工具 + 防封保护          ║"
    echo "║         ⏰ 时间: 3-5分钟自动完成，无需手动配置           ║"
    echo "║         📱 支持: Windows/Mac/安卓/IOS 全平台             ║"
    echo "║         🔐 自动防封，自动优化，自动修复                  ║"
    echo "║         💡 新手友好，全程中文提示，无需专业知识         ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}提示: 只需按数字键选择，全程自动完成，无需手动配置！${NC}"
    echo ""
}

# 日志记录
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ 错误: 必须使用 root 用户运行！${NC}"
        echo -e "${YELLOW}请执行以下命令:${NC}"
        echo "sudo -i"
        echo "或者: sudo bash 脚本名称"
        exit 1
    fi
}

# 检查网络连接
check_network() {
    echo -e "${YELLOW}🔍 正在检查网络连接...${NC}"
    if ping -c 2 -W 3 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}✅ 网络连接正常${NC}"
    else
        echo -e "${RED}❌ 网络连接失败，请检查服务器网络${NC}"
        exit 1
    fi
}

# 安装基础工具
install_tools() {
    echo -e "${YELLOW}🛠️ 正在安装必要工具...${NC}"
    
    if command -v apt &> /dev/null; then
        apt update -qq
        apt install -y wget curl jq tar gzip ufw socat screen qrencode
    elif command -v yum &> /dev/null; then
        yum install -y wget curl jq tar gzip firewalld socat screen qrencode
    fi
    
    echo -e "${GREEN}✅ 工具安装完成${NC}"
    log "基础工具安装完成"
}

# 安装X-UI面板
install_xui() {
    echo -e "${YELLOW}📊 正在安装代理管理面板...${NC}"
    echo -e "${CYAN}支持协议: VLESS/VMess/Trojan/Shadowsocks/Hysteria2/TUIC${NC}"
    
    # 自动安装X-UI
    bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
    
    # 获取服务器IP
    local ip=$(curl -s4m5 icanhazip.com -k || curl -s6m5 icanhazip.com -k)
    
    echo -e "${GREEN}✅ 代理面板安装完成${NC}"
    echo -e "${CYAN}════════════ 登录信息 ════════════${NC}"
    echo -e "🌐 访问地址: http://${ip}:54321"
    echo -e "👤 用户账号: admin"
    echo -e "🔑 用户密码: admin"
    echo -e "${CYAN}══════════════════════════════════${NC}"
    echo -e "${RED}⚠ 重要: 首次登录后立即修改密码！${NC}"
    
    log "X-UI面板安装完成，IP: $ip"
}

# 安装GOST中转
install_gost() {
    echo -e "${YELLOW}🔄 正在安装中转工具...${NC}"
    
    # 检测系统架构
    ARCH=$(uname -m)
    [ "$ARCH" = "x86_64" ] && ARCH="amd64"
    [ "$ARCH" = "aarch64" ] && ARCH="arm64"
    
    # 下载最新版GOST
    GOST_VER="v3.0.0-rc6"  # 使用稳定版本
    wget -q "https://github.com/ginuerzh/gost/releases/download/${GOST_VER}/gost-linux-${ARCH}-${GOST_VER}.tar.gz"
    
    if [ -f "gost-linux-${ARCH}-${GOST_VER}.tar.gz" ]; then
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
ExecStart=/usr/local/bin/gost -L=tcp://:3333
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable gost
        systemctl start gost
        
        echo -e "${GREEN}✅ 中转工具安装完成${NC}"
        echo -e "${YELLOW}📊 默认中转端口: 3333${NC}"
    else
        echo -e "${YELLOW}⚠ 中转工具下载失败，跳过安装${NC}"
    fi
    
    log "GOST中转安装完成"
}

# 自动修复防火墙
fix_firewall() {
    echo -e "${YELLOW}🛡️ 正在自动配置防火墙...${NC}"
    
    # 检测SSH端口
    SSH_PORT=$(grep -E "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    [ -z "$SSH_PORT" ] && SSH_PORT=22
    
    if command -v ufw &> /dev/null; then
        ufw --force disable
        ufw --force reset
        
        # 放行必要端口
        ufw allow ${SSH_PORT}/tcp
        ufw allow 54321/tcp    # X-UI面板
        ufw allow 3333/tcp     # GOST中转
        ufw allow 443/tcp      # HTTPS
        ufw allow 8443/tcp     # 备用
        ufw allow 80/tcp       # HTTP
        
        echo "y" | ufw --force enable
        
        echo -e "${GREEN}✅ 防火墙配置完成${NC}"
        echo -e "${YELLOW}📊 已放行端口: ${SSH_PORT}(SSH), 54321(面板), 3333(中转), 443/8443(代理)${NC}"
    else
        echo -e "${YELLOW}⚠ 未检测到UFW防火墙，跳过配置${NC}"
    fi
    
    log "防火墙配置完成，SSH端口: $SSH_PORT"
}

# 优化系统性能
optimize_system() {
    echo -e "${YELLOW}⚡ 正在优化系统性能...${NC}"
    
    # 启用BBR加速
    {
        echo "net.core.default_qdisc=fq"
        echo "net.ipv4.tcp_congestion_control=bbr"
        echo "net.ipv4.tcp_fastopen=3"
    } >> /etc/sysctl.conf
    
    sysctl -p &> /dev/null
    
    # 优化内核参数
    {
        echo "net.ipv4.tcp_fin_timeout = 30"
        echo "net.ipv4.tcp_tw_reuse = 1"
        echo "net.ipv4.tcp_max_syn_backlog = 8192"
        echo "net.ipv4.tcp_syncookies = 1"
        echo "net.core.somaxconn = 65535"
    } >> /etc/sysctl.conf
    
    sysctl -p &> /dev/null
    
    echo -e "${GREEN}✅ 系统优化完成${NC}"
    log "系统优化完成"
}

# 一键安装所有
install_all() {
    echo ""
    echo -e "${YELLOW}🚀 开始一键安装，请勿关闭终端...${NC}"
    echo -e "${CYAN}预计需要 3-5 分钟，请耐心等待${NC}"
    echo ""
    
    check_root
    check_network
    install_tools
    install_xui
    install_gost
    fix_firewall
    optimize_system
    
    # 显示完成信息
    local ip=$(curl -s4m5 icanhazip.com -k || curl -s6m5 icanhazip.com -k)
    
    echo -e "${PURPLE}════════════ 安装完成 ════════════${NC}"
    echo -e "${GREEN}🎉 恭喜！所有组件安装完成！${NC}"
    echo ""
    echo -e "${WHITE}📱 访问地址:${NC} http://${ip}:54321"
    echo -e "${WHITE}👤 用户账号:${NC} admin"
    echo -e "${WHITE}🔑 用户密码:${NC} admin"
    echo ""
    echo -e "${YELLOW}⚠ 重要提示:${NC}"
    echo "  1. 首次登录后立即修改密码！"
    echo "  2. 建议使用 VLESS+Reality 协议（最安全）"
    echo "  3. 如需中转，修改 /etc/systemd/system/gost.service 文件"
    echo ""
    echo -e "${CYAN}🔧 管理命令:${NC}"
    echo "  查看面板状态: systemctl status x-ui"
    echo "  查看中转状态: systemctl status gost"
    echo "  重启面板: systemctl restart x-ui"
    echo "  重启中转: systemctl restart gost"
    echo ""
    echo -e "${WHITE}📞 技术支持: 微信 a114447773${NC}"
    echo -e "${PURPLE}══════════════════════════════════${NC}"
    
    # 显示二维码
    if command -v qrencode &> /dev/null; then
        echo ""
        echo -e "${CYAN}📱 手机扫描二维码访问:${NC}"
        qrencode -t ANSIUTF8 "http://${ip}:54321"
    fi
    
    log "一键安装完成，IP: $ip"
}

# 查看服务状态
check_status() {
    echo -e "${YELLOW}📊 系统状态查看:${NC}"
    echo ""
    
    # 检查X-UI
    if systemctl is-active x-ui &>/dev/null; then
        echo -e "${GREEN}✅ 代理面板: 运行正常${NC}"
    else
        echo -e "${RED}❌ 代理面板: 未运行${NC}"
    fi
    
    # 检查GOST
    if systemctl is-active gost &>/dev/null; then
        echo -e "${GREEN}✅ 中转工具: 运行正常 (端口:3333)${NC}"
    else
        echo -e "${RED}❌ 中转工具: 未运行${NC}"
    fi
    
    # 检查BBR
    if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
        echo -e "${GREEN}✅ 网络加速: 已启用${NC}"
    else
        echo -e "${YELLOW}⚠ 网络加速: 未启用${NC}"
    fi
    
    # 显示IP
    local ip=$(curl -s4m5 icanhazip.com -k || curl -s6m5 icanhazip.com -k)
    echo ""
    echo -e "${CYAN}🌐 服务器IP: ${ip}${NC}"
    echo -e "${CYAN}🔗 面板地址: http://${ip}:54321${NC}"
    echo ""
}

# 重启服务
restart_services() {
    echo -e "${YELLOW}🔄 正在重启服务...${NC}"
    
    systemctl restart x-ui
    systemctl restart gost
    
    echo -e "${GREEN}✅ 服务重启完成${NC}"
    echo -e "${YELLOW}📊 重启的服务:${NC}"
    echo "  • 代理面板 (X-UI)"
    echo "  • 中转工具 (GOST)"
    echo ""
}

# 防封指南
security_guide() {
    echo -e "${PURPLE}════════════ 防封使用指南 ════════════${NC}"
    echo ""
    echo -e "${RED}⚠ 重要提醒: 以下建议可大幅降低被封锁风险${NC}"
    echo ""
    echo -e "${GREEN}✅ 推荐配置 (最安全):${NC}"
    echo "  1. 协议选择: VLESS + Reality"
    echo "  2. 端口设置: 30000-50000 之间的随机端口"
    echo "  3. 域名伪装: 使用 apple.com 或 microsoft.com"
    echo ""
    echo -e "${YELLOW}⚠ 可用配置 (较安全):${NC}"
    echo "  1. 协议选择: Trojan + TLS"
    echo "  2. 端口设置: 443 或 8443"
    echo "  3. 域名配置: 绑定自己的域名"
    echo ""
    echo -e "${RED}❌ 不推荐配置 (高风险):${NC}"
    echo "  1. 裸奔协议: VMess 无加密"
    echo "  2. 常见端口: 8080, 8888, 9999"
    echo "  3. 长时间不更换配置"
    echo ""
    echo -e "${CYAN}💡 高级技巧:${NC}"
    echo "  • 绑定域名 + Cloudflare CDN"
    echo "  • 使用 Nginx 反向代理"
    echo "  • 每月更换一次端口和密码"
    echo "  • 避免高峰时段大量使用"
    echo ""
    echo -e "${PURPLE}══════════════════════════════════${NC}"
    echo ""
}

# 主菜单
main_menu() {
    while true; do
        show_banner
        
        echo -e "${WHITE}请选择要执行的操作:${NC}"
        echo ""
        echo -e "${GREEN}[1] 一键安装所有 (推荐新手)${NC}"
        echo "   ├─ 自动安装代理面板 + 中转 + 优化"
        echo "   └─ 全程自动，无需手动配置"
        echo ""
        echo -e "${YELLOW}[2] 仅安装代理面板${NC}"
        echo "   └─ 只安装管理面板，不含中转"
        echo ""
        echo -e "${YELLOW}[3] 仅安装中转工具${NC}"
        echo "   └─ 只安装流量中转工具"
        echo ""
        echo -e "${BLUE}[4] 查看系统状态${NC}"
        echo "   ├─ 检查面板状态"
        echo "   ├─ 检查中转状态"
        echo "   └─ 查看服务器IP"
        echo ""
        echo -e "${PURPLE}[5] 重启所有服务${NC}"
        echo "   ├─ 重启代理面板"
        echo "   └─ 重启中转工具"
        echo ""
        echo -e "${CYAN}[6] 防封使用指南${NC}"
        echo "   ├─ 安全协议推荐"
        echo "   ├─ 端口设置建议"
        echo "   └─ 防封高级技巧"
        echo ""
        echo -e "${WHITE}[7] 退出脚本${NC}"
        echo ""
        
        read -p "$(echo -e "请输入数字 [1-7]: ")" choice
        
        case $choice in
            1)
                install_all
                ;;
            2)
                echo ""
                check_root
                install_xui
                ;;
            3)
                echo ""
                check_root
                install_gost
                ;;
            4)
                echo ""
                check_status
                ;;
            5)
                echo ""
                check_root
                restart_services
                ;;
            6)
                echo ""
                security_guide
                ;;
            7)
                echo -e "${GREEN}感谢使用铭泽跨境代理管理脚本！再见！${NC}"
                echo -e "${YELLOW}有需要随时再次运行本脚本${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 输入错误，请重新选择${NC}"
                sleep 1
                continue
                ;;
        esac
        
        echo ""
        read -p "$(echo -e "按 ${GREEN}回车键${NC} 返回主菜单: ")" -n 1
    done
}

# 脚本启动
main() {
    # 创建日志目录
    mkdir -p /var/log
    > "$LOG_FILE"
    log "脚本启动，版本: $SCRIPT_VERSION"
    
    # 开始主菜单
    main_menu
}

# 运行脚本
main "$@"
