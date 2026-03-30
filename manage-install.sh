# 1. 将管理脚本写入 /usr/local/bin/xboard
cat > /usr/local/bin/xboard << 'EOF'
#!/bin/bash

# 配置在线脚本地址
REMOTE_SCRIPT="https://raw.githubusercontent.com/cedar2025/Xboard-Node/refs/heads/dev/install.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

# 检查权限
[[ $EUID -ne 0 ]] && echo -e "${RED}错误：${PLAIN} 必须使用 root 运行！" && exit 1

# 辅助函数：显示列表并提示输入 ID
get_node_id() {
    echo -e "${BLUE}--- 当前节点列表 ---${PLAIN}"
    bash <(curl -Ls $REMOTE_SCRIPT) list
    echo -e "${BLUE}--------------------${PLAIN}"
    read -p "请输入节点 ID (直接回车取消): " nid
    echo "$nid"
}

show_menu() {
    clear
    echo -e "${BLUE}==========================================${PLAIN}"
    echo -e "${BLUE}       Xboard-Node 全局管理助手          ${PLAIN}"
    echo -e "${BLUE}==========================================${PLAIN}"
    echo -e "  ${GREEN}1.${PLAIN} 查看所有节点列表 (List)"
    echo -e "  ${GREEN}2.${PLAIN} 安装/添加新节点 (Add)"
    echo -e "  ${BLUE}------------------------------------------${PLAIN}"
    echo -e "  ${YELLOW}3.${PLAIN} 启动节点 (Start)"
    echo -e "  ${YELLOW}4.${PLAIN} 停止节点 (Stop)"
    echo -e "  ${YELLOW}5.${PLAIN} 重启节点 (Restart)"
    echo -e "  ${BLUE}------------------------------------------${PLAIN}"
    echo -e "  ${BLUE}6.${PLAIN} 查看实时日志 (Logs)"
    echo -e "  ${BLUE}7.${PLAIN} 更新内核二进制 (Update)"
    echo -e "  ${RED}8.${PLAIN} 删除指定节点 (Remove)"
    echo -e "  ${RED}9.${PLAIN} 彻底卸载 (Uninstall)"
    echo -e "  ${PLAIN}0. 退出脚本"
    echo -e "${BLUE}==========================================${PLAIN}"
    read -p "请选择操作 [0-9]: " choice

    case $choice in
        1) 
            bash <(curl -Ls $REMOTE_SCRIPT) list
            read -p "按回车继续..." ;;
        2) 
            bash <(curl -Ls $REMOTE_SCRIPT)
            read -p "按回车继续..." ;;
        3) 
            nid=$(get_node_id)
            if [ -n "$nid" ]; then
                systemctl start xboard-node@$nid
                echo -e "${GREEN}节点 $nid 启动指令已发送${PLAIN}"
                sleep 1
            fi ;;
        4) 
            nid=$(get_node_id)
            if [ -n "$nid" ]; then
                systemctl stop xboard-node@$nid
                echo -e "${RED}节点 $nid 已停止${PLAIN}"
                sleep 1
            fi ;;
        5) 
            nid=$(get_node_id)
            if [ -n "$nid" ]; then
                systemctl restart xboard-node@$nid
                echo -e "${GREEN}节点 $nid 重启完成${PLAIN}"
                sleep 1
            fi ;;
        6)
            nid=$(get_node_id)
            if [ -n "$nid" ]; then
                echo -e "${BLUE}提示：按 Ctrl+C 退出日志查看${PLAIN}"
                journalctl -u xboard-node@$nid -f
            fi ;;
        7) 
            bash <(curl -Ls $REMOTE_SCRIPT) update
            read -p "按回车继续..." ;;
        8)
            nid=$(get_node_id)
            if [ -n "$nid" ]; then
                bash <(curl -Ls $REMOTE_SCRIPT) remove "$nid"
                read -p "按回车继续..."
            fi ;;
        9)
            read -p "确认要彻底卸载吗？(y/n): " confirm
            [[ "$confirm" == [Yy] ]] && bash <(curl -Ls $REMOTE_SCRIPT) uninstall
            exit 0 ;;
        0) exit 0 ;;
        *) ;;
    esac
    show_menu
}

show_menu
EOF

# 2. 赋予执行权限
chmod +x /usr/local/bin/xboard

# 3. 创建 xboard 软链接指向 xb
ln -sf /usr/local/bin/xboard /usr/local/bin/xb

echo -e "\033[32m[完成] 全局命令已部署！\033[0m"
echo -e "\033[33m现在输入 \033[1;36mxb\033[0m\033[33m 或 \033[1;36mxboard\033[0m\033[33m 均可进入管理菜单。\033[0m"
