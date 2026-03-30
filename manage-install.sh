cat > /usr/local/bin/xboard << 'EOF'
#!/bin/bash

# 配置在线脚本地址
REMOTE_SCRIPT="https://raw.githubusercontent.com/cedar2025/Xboard-Node/refs/heads/dev/install.sh"

# 颜色定义
BLUE='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}       Xboard-Node 全局管理助手          ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo -e "  1. ${GREEN}查看节点列表 (List)${NC}"
    echo -e "  2. ${GREEN}安装/添加新节点 (Add)${NC}"
    echo -e "  3. ${RED}删除指定节点 (Remove)${NC}"
    echo -e "  4. 更新内核二进制 (Update)${NC}"
    echo -e "  5. 卸载全部组件 (Uninstall)${NC}"
    echo -e "  6. 查看节点实时日志 (Logs)${NC}"
    echo -e "  0. 退出脚本"
    echo -e "${BLUE}------------------------------------------${NC}"
    read -p "请输入选项 [0-6]: " choice

    case $choice in
        1)
            bash <(curl -Ls $REMOTE_SCRIPT) list
            read -p "按回车键继续..."
            show_menu
            ;;
        2)
            bash <(curl -Ls $REMOTE_SCRIPT)
            read -p "按回车键继续..."
            show_menu
            ;;
        3)
            read -p "请输入要删除的 Node ID: " nid
            [ -n "$nid" ] && bash <(curl -Ls $REMOTE_SCRIPT) remove "$nid"
            read -p "按回车键继续..."
            show_menu
            ;;
        4)
            bash <(curl -Ls $REMOTE_SCRIPT) update
            read -p "按回车键继续..."
            show_menu
            ;;
        5)
            read -p "确认卸载吗？(y/n): " confirm
            [[ "$confirm" == [Yy] ]] && bash <(curl -Ls $REMOTE_SCRIPT) uninstall
            exit 0
            ;;
        6)
            read -p "请输入 Node ID: " nid
            echo -e "${BLUE}提示：按 Ctrl+C 退出日志${NC}"
            journalctl -u xboard-node@$nid -f
            show_menu
            ;;
        0) exit 0 ;;
        *) show_menu ;;
    esac
}

# 检查权限
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}请使用 root 运行！${NC}"
    exit 1
fi

show_menu
EOF

# 赋予执行权限
chmod +x /usr/local/bin/xboard

echo -e "\033[32m安装成功！现在你可以在任何地方输入 \033[1;33mxboard\033[0;32m 来管理节点了。\033[0m"
