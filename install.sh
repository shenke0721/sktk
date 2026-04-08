#!/bin/bash
# 铭泽跨境 - 全网最强代理管理脚本 (Sing-box + GOST 集成版)
# 支持: VLESS Reality, VMess WS, Hysteria2, Tuic, GOST中转, 域名证书, WARP解锁
# 特点: 全终端菜单交互，无需记忆命令，小白也能轻松管理

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="/root/mingze-proxy"

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║             铭泽跨境 - 全网最强代理管理脚本 v6.0         ║"
    echo "║         (Sing-box + GOST 终端交互版)                     ║"
    echo "║        Copyright © 2025 铭泽跨境. All rights reserved.   ║"
    echo "║               技术支持: 微信 a114447773                  ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用 root 权限运行此脚本！${NC}"
        exit 1
    fi
}

# 安装基础依赖
install_dependencies() {
    echo -e "${YELLOW}[1/4] 正在安装基础依赖...${NC}"
    if command -v apt &> /dev/null; then
        apt update -qq
        apt install -y wget curl jq tar gzip net-tools ufw socat
    elif command -v yum &> /dev/null; then
        yum install -y wget curl jq tar gzip net-tools firewalld socat
    fi
    echo -e "${GREEN}✓ 基础依赖安装完成！${NC}"
}

# 安装 Sing-box 服务端 (全协议)
install_singbox() {
    echo -e "${YELLOW}[2/4] 正在安装 Sing-box 全协议服务端...${NC}"
    
    # 使用 yonggekkk 的脚本安装 Sing-box
    bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
    
    echo -e "${GREEN}✓ Sing-box 安装完成！${NC}"
    echo -e "${YELLOW}配置文件路径: /etc/s-box/sb.json${NC}"
}

# 安装 GOST 中转工具
install_gost() {
    echo -e "${YELLOW}[3/4] 正在安装 GOST 中转工具...${NC}"
    
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

# 配置 GOST 中转 (终端交互)
setup_gost() {
    echo -e "${YELLOW}正在配置 GOST 中转...${NC}"
    
    # 停止当前服务
    systemctl stop gost
    
    # 获取用户输入
    echo -e "${CYAN}请输入中转规则:${NC}"
    echo -e "${YELLOW}格式: 监听端口:目标IP:目标端口${NC}"
    echo -e "${YELLOW}示例: 8080:1.2.3.4:443${NC}"
    read -p "请输入规则: " gost_rule
    
    # 提取参数
    listen_port=$(echo $gost_rule | cut -d':' -f1)
    target_ip=$(echo $gost_rule | cut -d':' -f2)
    target_port=$(echo $gost_rule | cut -d':' -f3)
    
    # 验证输入
    if [[ -z $listen_port || -z $target_ip || -z $target_port ]]; then
        echo -e "${RED}输入格式错误！${NC}"
        return 1
    fi
    
    # 修改服务文件
    sed -i "s|ExecStart=.*|ExecStart=/usr/local/bin/gost -L=tcp://:$listen_port/$target_ip:$target_port|g" /etc/systemd/system/gost.service
    
    # 重载并启动
    systemctl daemon-reload
    systemctl start gost
    
    echo -e "${GREEN}✓ GOST 中转配置完成！${NC}"
    echo -e "${YELLOW}监听端口: $listen_port -> 目标: $target_ip:$target_port${NC}"
}

# 申请域名证书 (终端交互)
setup_domain() {
    echo -e "${YELLOW}正在配置域名证书...${NC}"
    
    # 使用 yonggekkk 的 acme 脚本
    bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/acme-yg/main/acme.sh)
    
    echo -e "${GREEN}✓ 域名证书配置完成！${NC}"
}

# 主菜单
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}请选择操作:${NC}"
        echo "1. 一键安装所有组件 (Sing-box + GOST)"
        echo "2. 仅安装 Sing-box 服务端"
        echo "3. 仅安装 GOST 中转"
        echo "4. 配置 GOST 中转规则"
        echo "5. 申请域名证书 (Acme)"
        echo "6. 查看服务状态"
        echo "7. 重启 Sing-box"
        echo "8. 重启 GOST"
        echo "9. 退出脚本"
        echo ""
        read -p "请输入数字 [1-9]: " choice
        
        case $choice in
            1)
                install_dependencies
                install_singbox
                install_gost
                echo -e "${GREEN}✅ 所有组件安装完成！${NC}"
                ;;
            2)
                install_singbox
                ;;
            3)
                install_gost
                ;;
            4)
                setup_gost
                ;;
            5)
                setup_domain
                ;;
            6)
                echo -e "${YELLOW}服务状态:${NC}"
                systemctl status sing-box --no-pager 2>/dev/null || echo "Sing-box 未安装"
                systemctl status gost --no-pager 2>/dev/null || echo "GOST 未安装"
                ;;
            7)
                systemctl restart sing-box
                echo -e "${GREEN}✓ Sing-box 已重启${NC}"
                ;;
            8)
                systemctl restart gost
                echo -e "${GREEN}✓ GOST 已重启${NC}"
                ;;
            9)
                echo -e "${GREEN}感谢使用铭泽跨境代理管理脚本！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择！${NC}"
                ;;
        esac
        
        echo ""
        read -p "按回车键返回菜单..."
    done
}

# 脚本入口
main() {
    check_root
    main_menu
}

main "$@"
