#!/usr/bin/env bash
# ==============================================================================
# 跨平台待办与看板 - 每日自动备份与 GitHub Private 仓库同步脚本
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$DIR")"
BACKUP_DIR="$PROJECT_ROOT/backup"
DATA_DIR="$BACKUP_DIR/data"
HISTORY_DIR="$DATA_DIR/history"
REPORTS_DIR="$BACKUP_DIR/reports"

mkdir -p "$DATA_DIR" "$HISTORY_DIR" "$REPORTS_DIR"

TODAY=$(date +"%Y-%m-%d")
NOW=$(date +"%Y-%m-%d %H:%M:%S")

# 1. 探测优先可用的 PocketBase API 地址 (本地或阿里云)
SERVER_URL="http://127.0.0.1:8090"
if ! curl -s -m 2 "$SERVER_URL/api/health" &> /dev/null; then
    SERVER_URL="http://47.116.20.106:8090"
fi

echo "=================================================="
echo "  🚀 开始执行待办数据每日自动备份 ($TODAY)"
echo "  数据来源服务器: $SERVER_URL"
echo "=================================================="

# 2. 从 API 导出全量任务 JSON 数据
RAW_JSON=$(curl -s "$SERVER_URL/api/collections/todos/records?sort=order&perPage=500")

# 校验 JSON 有效性
if ! echo "$RAW_JSON" | grep -q '"items"'; then
    echo "❌ 获取任务数据失败或响应格式异常，终止本次备份。"
    exit 1
fi

# 保存全量 JSON 最新快照与历史归档
echo "$RAW_JSON" > "$DATA_DIR/todos-latest.json"
echo "$RAW_JSON" > "$HISTORY_DIR/todos-$TODAY.json"
echo "✅ 结构化 JSON 数据已保存: todos-latest.json 及 history/todos-$TODAY.json"

# 3. 自动生成美观且详尽的 Markdown 每日生产力与待办日志
REPORT_FILE="$REPORTS_DIR/daily-$TODAY.md"

python3 -c "
import json, sys

with open('$DATA_DIR/todos-latest.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

items = data.get('items', [])
total = len(items)
done_items = [t for t in items if t.get('status') == 'done']
prog_items = [t for t in items if t.get('status') == 'in_progress']
todo_items = [t for t in items if t.get('status') == 'todo']

rate = round((len(done_items) / total) * 100) if total > 0 else 0

p1_total = len([t for t in items if t.get('priority') == 2])
p1_done = len([t for t in done_items if t.get('priority') == 2])
p1_rate = round((p1_done / p1_total) * 100) if p1_total > 0 else 100

md = []
md.append(f'# 📅 每日待办日志与生产力备份 - $TODAY')
md.append(f'> **归档时间**：$NOW ｜ **数据源**：$SERVER_URL')
md.append('')
md.append('## 📊 核心指标概览')
md.append('| 指标项 | 统计数值 | 说明 |')
md.append('| :--- | :--- | :--- |')
md.append(f'| 📋 **任务总数** | **{total}** 项 | 全看板跟踪事项 |')
md.append(f'| 🎉 **已完成** | **{len(done_items)}** 项 | 累计达成任务 |')
md.append(f'| ⚡ **进行中** | **{len(prog_items)}** 项 | 当前正在攻坚 |')
md.append(f'| 📌 **待办存量** | **{len(todo_items)}** 项 | 等待排期处理 |')
md.append(f'| 🏆 **总体完成率** | **{rate}%** | 达成进度 |')
md.append(f'| 🔥 **高优灭霸指数** | **{p1_rate}%** | P1 高优任务搞定率 |')
md.append('')

md.append('## ✅ 今日已达成事项清单')
if not done_items:
    md.append('*暂无已完成事项*')
else:
    for t in done_items:
        p_tag = '🔴 [P1高优]' if t.get('priority') == 2 else ('🟡 [P2中优]' if t.get('priority') == 1 else '⚪ [P3低优]')
        desc = f\" - *{t['description']}*\" if t.get('description') else ''
        md.append(f\"- [x] **{t['title']}** {p_tag}{desc}\")
md.append('')

md.append('## ⚡ 攻坚中与重点待办推进')
if not prog_items and not todo_items:
    md.append('*看板所有任务均已清空搞定！🎯*')
else:
    if prog_items:
        md.append('### 正在进行中：')
        for t in prog_items:
            desc = f\" - *{t['description']}*\" if t.get('description') else ''
            md.append(f\"- [ ] ⏳ **{t['title']}**{desc}\")
    if todo_items:
        md.append('### 待办队列：')
        for t in todo_items:
            desc = f\" - *{t['description']}*\" if t.get('description') else ''
            md.append(f\"- [ ] 📌 **{t['title']}**{desc}\")
md.append('')

md.append('---')
md.append('*🤖 本日志由 Retro Task 自动备份守护引擎每日自动生成并归档至 GitHub Private 仓库。*')

with open('$REPORT_FILE', 'w', encoding='utf-8') as f:
    f.write('\n'.join(md) + '\n')
"

echo "✅ Markdown 每日生产力复盘日志已生成: reports/daily-$TODAY.md"

# 4. 同步并推送到 GitHub 仓库 (支持自定义 Private 仓库或当前仓库)
cd "$PROJECT_ROOT"

# 检查当前 git 状态
if git status --porcelain | grep -q "backup/"; then
    echo "4. 正在提交并推送到 GitHub 仓库..."
    git add backup/
    git commit -m "chore(backup): 待办数据每日自动归档与生产力日志 ($TODAY)"
    git push origin main
    echo "=================================================="
    echo "🎉 备份完成！数据与 Markdown 日报已成功推送到 GitHub。"
    echo "=================================================="
else
    echo "ℹ️ 今日数据未发生变化，无需重复提交。"
fi
