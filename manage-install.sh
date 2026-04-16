cat >> /usr/local/bin/xboard << 'EOF'

# 核心操作函数
do_action() {
    local action=$1
    case $action in
        "list")
            xbctl list
            ;;
        "add")
            echo -e "${YELLOW}请选择添加模式:${PLAIN}"
            echo "1. 节点模式 (Node Mode)"
            echo "2. 机器模式 (Machine Mode)"
            read -p "选择 [1-2]: " m_choice
            read -p "请输入 Panel URL: " p_url
            read -p "请输入 Token: " p_token
            if [ "$m_choice" == "1" ]; then
                read -p "请输入 Node ID: " n_id
                bash <(curl -Ls ${REMOTE_SCRIPT}) --mode node --panel "$p_url" --token "$p_token" --node-id "$n_id"
            else
                read -p "请输入 Machine ID: " m_id
                bash <(curl -Ls ${REMOTE_SCRIPT}) --mode machine --panel "$p_url" --token "$p_token" --machine-id "$m_id"
            fi
            ;;
        "upgrade")
            bash <(curl -Ls ${REMOTE_SCRIPT}) upgrade
            ;;
        "uninstall")
            read -p "是否彻底清除配置文件？(y/n): " purge_choice
            if [ "$purge_choice" == "y" ]; then
                bash <(curl -Ls ${REMOTE_SCRIPT}) uninstall --purge --yes
            else
                bash <(curl -Ls ${REMOTE_SCRIPT}) uninstall --yes
            fi
            ;;
        "service")
            local cmd=$2
            xbctl service $cmd
            ;;
    esac
}

show_menu() {
    clear
    echo -e "${BLUE}==========================================${PLAIN}"
    echo -e "${BLUE}         Xboard-Node 管理工具 (v2)       ${PLAIN}"
    echo -e "${BLUE}==========================================${PLAIN}"
    echo -e "  ${GREEN}1.${PLAIN} 查看所有实例 (List)"
    echo -e "  ${GREEN}2.${PLAIN} 查看运行状态 (Status)"
    echo -e "  ${GREEN}3.${PLAIN} 添加新绑定 (Add Node/Machine)"
    echo -e "  ${BLUE}------------------------------------------${PLAIN}"
    echo -e "  ${YELLOW}4.${PLAIN} 重启服务"
    echo -e "  ${YELLOW}5.${PLAIN} 停止服务"
    echo -e "  ${BLUE}------------------------------------------${PLAIN}"
    echo -e "  ${CYAN}6.${PLAIN} 查看日志 (Journalctl)"
    echo -e "  ${CYAN}7.${PLAIN} 更新程序 (Upgrade)"
    echo -e "  ${RED}8.${PLAIN} 卸载 Xboard-Node"
    echo -e "  ${PLAIN}0. 退出"
    echo -e "${BLUE}==========================================${PLAIN}"
    read -p "选择 [0-8]: " choice

    case $choice in
        1) clear; do_action "list"; echo ""; read -p "按回车继续..." ;;
        2) clear; xbctl status; echo ""; read -p "按回车继续..." ;;
        3) do_action "add"; read -p "按回车继续..." ;;
        4) do_action "service" "restart"; sleep 1 ;;
        5) do_action "service" "stop"; sleep 1 ;;
        6) clear; journalctl -u xboard-node.service -f ;;
        7) do_action "upgrade"; read -p "按回车继续..." ;;
        8) do_action "uninstall"; exit 0 ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${PLAIN}"; sleep 1 ;;
    esac
    show_menu
}

# 启动菜单
show_menu
EOF
