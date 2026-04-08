cat > /usr/local/bin/xboard << 'EOF'
#!/bin/bash

# 配置
REMOTE_SCRIPT="https://raw.githubusercontent.com/cedar2025/Xboard-Node/refs/heads/dev/install.sh"
CONFIG_DIR="/etc/xboard-node"
BLUE='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PLAIN='\033[0m'

# 系统检测
if command -v systemctl >/dev/null 2>&1; then
    SYS_TYPE="systemd"
elif [ -f /etc/alpine-release ]; then
    SYS_TYPE="alpine"
else
    SYS_TYPE="generic"
fi

# 服务管理逻辑
ensure_alpine_service() {
    local nid=$1
    local service_path="/etc/init.d/xboard-node.$nid"
    if [ ! -f "$service_path" ]; then
        cat > "$service_path" << SVC
#!/sbin/openrc-run
description="Xboard Node $nid"
command="/usr/local/bin/xboard-node"
command_args="-c /etc/xboard-node/$nid/config.yml"
pidfile="/run/xboard-node.$nid.pid"
command_background="yes"
output_log="/var/log/xboard-node.$nid.log"
error_log="/var/log/xboard-node.$nid.log"
depend() { need net; }
SVC
        chmod +x "$service_path"
        rc-update add "xboard-node.$nid" default >/dev/null 2>&1
    fi
}

is_node_running() {
    local nid=$1
    if [ "$SYS_TYPE" = "systemd" ]; then
        systemctl is-active --quiet "xboard-node@$nid" && return 0
    fi
    if [ -f "/run/xboard-node.$nid.pid" ]; then
        local pid=$(cat "/run/xboard-node.$nid.pid")
        kill -0 "$pid" 2>/dev/null && return 0
    fi
    if ps -ef | grep -v grep | grep -q "xboard-node.*$nid/config.yml"; then
        return 0
    fi
    return 1
}

fetch_list() {
    echo -e "${BLUE}--- 节点列表 ---${PLAIN}"
    local tmp_file=$(mktemp)
    bash <(curl -Ls ${REMOTE_SCRIPT}) list | grep -E "Node|kernel|status|Deployed" > "$tmp_file"
    
    local current_id=""
    while read -r line; do
        if echo "$line" | grep -q "Node"; then
            current_id=$(echo "$line" | grep -oE "[0-9]+")
            echo -e "$line"
        elif echo "$line" | grep -q "status="; then
            if is_node_running "$current_id" ; then
                echo -e "              status=${GREEN}running${PLAIN}"
            else
                echo -e "              status=${RED}stopped${PLAIN}"
            fi
        else
            echo -e "$line"
        fi
    done < "$tmp_file"
    rm -f "$tmp_file"
}

do_service() {
    local act=$1
    local nid=$2
    if [ "$SYS_TYPE" = "systemd" ]; then
        systemctl $act "xboard-node@$nid"
    elif [ "$SYS_TYPE" = "alpine" ]; then
        ensure_alpine_service "$nid"
        rc-service "xboard-node.$nid" $act
    fi
    echo -e "${GREEN}节点 $nid $act 完成${PLAIN}"
}

select_node() {
    clear
    echo -e "${BLUE}==========================================${PLAIN}"
    echo -e "${YELLOW}操作：$1${PLAIN}"
    echo -e "${BLUE}------------------------------------------${PLAIN}"
    fetch_list
    echo -e "${BLUE}------------------------------------------${PLAIN}"
    read -p "请输入节点 ID: " SELECTED_NID
}

show_menu() {
    clear
    echo -e "${BLUE}==========================================${PLAIN}"
    echo -e "${BLUE}         Xboard-Node 管理工具            ${PLAIN}"
    echo -e "${BLUE}==========================================${PLAIN}"
    echo -e "  ${GREEN}1.${PLAIN} 节点列表"
    echo -e "  ${GREEN}2.${PLAIN} 添加节点"
    echo -e "  ${BLUE}------------------------------------------${PLAIN}"
    echo -e "  ${YELLOW}3.${PLAIN} 启动节点"
    echo -e "  ${YELLOW}4.${PLAIN} 停止节点"
    echo -e "  ${YELLOW}5.${PLAIN} 重启节点"
    echo -e "  ${BLUE}------------------------------------------${PLAIN}"
    echo -e "  ${BLUE}6.${PLAIN} 节点日志"
    echo -e "  ${BLUE}7.${PLAIN} 更新程序"
    echo -e "  ${RED}8.${PLAIN} 删除节点"
    echo -e "  ${RED}9.${PLAIN} 卸载脚本"
    echo -e "  ${PLAIN}0. 退出"
    echo -e "${BLUE}==========================================${PLAIN}"
    read -p "选择 [0-9]: " choice

    case $choice in
        1) clear; fetch_list; echo ""; read -p "按回车继续..." ;;
        2) bash <(curl -Ls ${REMOTE_SCRIPT}) ;;
        3) select_node "启动"; [[ -z "$SELECTED_NID" ]] || do_service "start" "$SELECTED_NID"; sleep 1 ;;
        4) select_node "停止"; [[ -z "$SELECTED_NID" ]] || do_service "stop" "$SELECTED_NID"; sleep 1 ;;
        5) select_node "重启"; [[ -z "$SELECTED_NID" ]] || do_service "restart" "$SELECTED_NID"; sleep 1 ;;
        6) select_node "日志"; [[ -n "$SELECTED_NID" ]] && ( [ "$SYS_TYPE" = "systemd" ] && journalctl -u xboard-node@$SELECTED_NID -f || tail -f "/var/log/xboard-node.$SELECTED_NID.log" ) ;;
        7) bash <(curl -Ls ${REMOTE_SCRIPT}) update; read -p "按回车继续..." ;;
        8) select_node "删除"; [[ -z "$SELECTED_NID" ]] || bash <(curl -Ls ${REMOTE_SCRIPT}) remove $SELECTED_NID; read -p "按回车继续..." ;;
        9) read -p "确认卸载？(y/n): " confirm; [[ "$confirm" == [Yy] ]] && bash <(curl -Ls ${REMOTE_SCRIPT}) uninstall; exit 0 ;;
        0) exit 0 ;;
    esac
    show_menu
}

show_menu
EOF

# 设置权限并建立快捷方式
chmod +x /usr/local/bin/xboard
ln -sf /usr/local/bin/xboard /usr/local/bin/xb

# 安装完成后的正式提示
echo -e "\n${GREEN}Xboard-Node 管理工具已安装。${PLAIN}"
echo -e "输入 ${YELLOW}xb${PLAIN} 或 ${YELLOW}xboard${PLAIN} 即可运行。\n"
