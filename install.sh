#!/bin/bash
# ================================================
# 铭泽跨境代理管理脚本 - 修复版 (无外部弹窗)
# 修复内容：移除了会弹窗的 tcp.sh，改用内置 BBR
# ================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示横幅
show_banner() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN} 铭泽跨境代理管理脚本 - 修复版 ${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# 安装基础依赖
install_dependencies() {
    echo -e "${YELLOW}[1/3] 正在安装基础依赖...${NC}"
    if command -v apt &> /dev/null; then
        apt update -qq
        apt install -y wget curl jq tar gzip net-tools
    elif command -v yum &> /dev/null; then
        yum install -y wget curl jq tar gzip net-tools
    fi
    echo -e "${GREEN}基础依赖安装完成！${NC}"
}

# 安装 BBR (修复版：直接修改内核参数，不弹窗)
install_bbr() {
    echo -e "${YELLOW}[2/3] 正在安装 BBR 加速...${NC}"
    
    # 检查是否已启用
    if [[ $(sysctl net.ipv4.tcp_congestion_control | grep -o bbr) == "bbr" ]]; then
        echo -e "${GREEN}BBR 已启用，无需重复安装。${NC}"
        return
    fi
    
    # 备份原配置
    cp /etc/sysctl.conf /etc/sysctl.conf.bak 2>/dev/null
    
    # 应用 BBR 参数
    {
        echo "net.core.default_qdisc=fq"
        echo "net.ipv4.tcp_congestion_control=bbr"
    } >> /etc/sysctl.conf
    
    # 加载配置
    sysctl -p /etc/sysctl.conf >/dev/null 2>&1
    
    # 验证
    if [[ $(sysctl net.ipv4.tcp_congestion_control | grep -o bbr) == "bbr" ]]; then
        echo -e "${GREEN}BBR 加速安装完成！${NC}"
    else
        echo -e "${RED}BBR 安装失败，可能需要手动重启或更换内核。${NC}"
    fi
}

# 安装 X-UI 面板
install_xui() {
    echo -e "${YELLOW}[3/3] 正在安装 X-UI 面板...${NC}"
    bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/install.sh)
    echo -e "${GREEN}X-UI 面板安装完成！${NC}"
}

# 一键安装所有
install_all() {
    install_dependencies
    install_bbr
    install_xui
    echo -e "${GREEN}✅ 所有组件安装完成！${NC}"
    echo -e "${YELLOW}请使用浏览器访问: http://你的服务器IP:54321${NC}"
}

# 主菜单
main_menu() {
    clear
    show_banner
    echo "请选择功能："
    echo "1. 一键安装所有组件 (依赖 + BBR + X-UI)"
    echo "2. 仅安装 BBR 加速 (修复版)"
    echo "3. 仅安装 X-UI 面板"
    echo "4. 退出"
    echo ""
    read -p "请输入数字 [1-4]: " choice
    
    case $choice in
        1) install_all ;;
        2) install_bbr ;;
        3) install_xui ;;
        4) exit 0 ;;
        *) echo -e "${RED}无效选择！${NC}" ;;
    esac
    
    echo ""
    read -p "按回车键返回菜单..."
    main_menu
}

# 主程序入口
main() {
    if [[ $1 == "auto" ]]; then
        install_all
    else
        main_menu
    fi
}

main "$@"
