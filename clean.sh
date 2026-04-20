# ---------------------------------------------------------
# 全自动极简优化脚本 (含语言包/文档清理 & 多系统适配)
# ---------------------------------------------------------

# 1. 确保 cron 安装
echo "正在配置 cron 服务..."
if command -v apt-get >/dev/null; then
    sudo apt-get update && sudo apt-get install -y cron
    sudo systemctl enable cron && sudo systemctl start cron
elif command -v yum >/dev/null; then
    sudo yum install -y crontabs
    sudo systemctl enable crond && sudo systemctl start crond
elif command -v apk >/dev/null; then
    sudo apk add dcron
    rc-update add dcron && rc-service dcron start
fi

# 2. 创建深度清理脚本
cat << 'EOF' | sudo tee /usr/local/bin/clean_system.sh > /dev/null
#!/bin/bash

# --- 1. 深度清理语言包与文档 (释放核心空间) ---
# 保留英文和中文，删除其他所有语言翻译
if [ -d /usr/share/locale ]; then
    find /usr/share/locale -maxdepth 1 -not -name 'zh*' -not -name 'en*' -not -name 'locale.alias' -not -name '.' -exec rm -rf {} +
fi

# 删除所有程序帮助文档和手册 (极小硬盘不建议保留 doc/man)
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

# --- 4. 临时文件 ---
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "深度清理完成！"
df -h /
EOF

# 3. 权限与 Cron 配置
sudo chmod +x /usr/local/bin/clean_system.sh

# 写入 crontab
(sudo crontab -l 2>/dev/null | grep -Fv "/usr/local/bin/clean_system.sh"; echo "0 3 * * 0 /usr/local/bin/clean_system.sh > /dev/null 2>&1") | sudo crontab -

echo "✅ 深度清理脚本安装成功！"
echo "已包含：语言包清理、帮助文档清理、日志轮转及包缓存清理。"
