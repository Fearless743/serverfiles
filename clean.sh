#!/bin/bash

# ---------------------------------------------------------
# 全自动极简优化脚本 (含冲突检查、清理逻辑 & 多系统适配)
# ---------------------------------------------------------

# 检查是否为 root 运行
[ "$EUID" -ne 0 ] && echo "请以 root 权限运行此脚本。" && exit 1

echo "🔍 正在检查已存在的清理任务冲突..."

# 定义可能的冲突关键词
SEARCH_KEY="clean"
# 获取当前脚本自己的名称，避免误杀自己
SELF_NAME="clean_system.sh"

# 查找 crontab 中包含关键词的行，但排除掉我们即将要安装的文件名
EXISTING_CRON=$(crontab -l 2>/dev/null | grep "$SEARCH_KEY" | grep -v "$SELF_NAME")

if [ ! -z "$EXISTING_CRON" ]; then
    echo "⚠️ 发现可能冲突的 Cron 任务:"
    echo "$EXISTING_CRON"
    echo "------------------------------------------------"
    read -p "是否删除这些旧任务并彻底物理删除对应的源文件？(y/n): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        # 提取文件路径并删除源文件
        echo "$EXISTING_CRON" | awk '{for(i=1;i<=NF;i++) if($i ~ " /") print $i}' | while read -r file_path; do
            if [ -f "$file_path" ]; then
                echo "正在删除源文件: $file_path"
                rm -f "$file_path"
            fi
        done
        
        # 从 crontab 中移除包含关键词的行
        (crontab -l 2>/dev/null | grep -v "$SEARCH_KEY") | crontab -
        echo "✅ 旧冲突已清理。"
    else
        echo "⏺️ 已跳过冲突清理，继续安装..."
    fi
fi

# 1. 确保 cron 安装
echo "正在配置 cron 服务..."
if command -v apt-get >/dev/null; then
    apt-get update && apt-get install -y cron
    systemctl enable cron && systemctl start cron
elif command -v yum >/dev/null; then
    yum install -y crontabs
    systemctl enable crond && systemctl start crond
elif command -v apk >/dev/null; then
    apk add dcron
    rc-update add dcron && rc-service dcron start
fi

# 2. 创建深度清理脚本
# 注意：这里直接将内容写入 /usr/local/bin/clean_system.sh
cat << 'EOF' | tee /usr/local/bin/clean_system.sh > /dev/null
#!/bin/bash

# --- 1. 深度清理语言包与文档 ---
if [ -d /usr/share/locale ]; then
    find /usr/share/locale -maxdepth 1 -not -name 'zh*' -not -name 'en*' -not -name 'locale.alias' -not -name '.' -exec rm -rf {} +
fi
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/*

# --- 2. 日志清理 ---
if command -v journalctl >/dev/null; then
    journalctl --vacuum-time=1d
fi
LOGS=("/var/log/btmp" "/var/log/wtmp" "/var/log/lastlog" "/var/log/maillog" "/var/log/messages")
for log in "${LOGS[@]}"; do
    [ -f "$log" ] && truncate -s 0 "$log"
done

# --- 3. 包管理器清理 ---
if command -v apt-get >/dev/null; then
    apt-get clean
    apt-get autoclean
    rm -rf /var/lib/apt/lists/*
    apt-get autoremove --purge -y
elif command -v yum >/dev/null; then
    yum clean all
    rm -rf /var/cache/yum
elif command -v apk >/dev/null; then
    apk cache clean
fi

# --- 4. 临时文件 & APT 彻底残留 ---
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/cache/apt/*
rm -rf /var/lib/apt/lists/*

echo "深度清理完成！当前磁盘状态："
df -h /
EOF

# 3. 权限与 Cron 配置
chmod +x /usr/local/bin/clean_system.sh

# 立即执行一次
bash /usr/local/bin/clean_system.sh

# 写入 crontab (每周日凌晨3点执行)
(crontab -l 2>/dev/null | grep -Fv "/usr/local/bin/clean_system.sh"; echo "0 3 * * 0 /usr/local/bin/clean_system.sh > /dev/null 2>&1") | crontab -

echo "------------------------------------------------"
echo "✅ 深度清理脚本安装成功并已执行！"
echo "定时任务已设为每周日凌晨 3:00 执行。"
