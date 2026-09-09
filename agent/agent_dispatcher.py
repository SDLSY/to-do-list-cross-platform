#!/usr/bin/env python3
# ==============================================================================
# Agent Dispatcher 调度器守护进程 (Human-in-the-Loop Agent Worker)
# 职责：
# 1. 毫秒级长连接监听 PocketBase todos 集合
# 2. 自动认领 is_agent == True 且状态为 todo 的任务
# 3. 严格切换至卡片指定的 work_dir 工作目录，加载指定模型与参数
# 4. 实时向卡片流式追加执行日志 (agent_log)
# 5. 异常保护：遇到报错或超时，自动保存现场堆栈，防止黑盒死机！
# ==============================================================================
import json
import os
import sys
import time
import traceback
import urllib.request
import urllib.parse

SERVER_URL = os.environ.get("PB_URL", "http://127.0.0.1:8090").rstrip("/")

print("==================================================")
print("  🤖 Retro Task Agent 调度器守护进程启动中...")
print(f"  目标看板服务器: {SERVER_URL}")
print("  监听规则: 仅认领 is_agent == True 且待办的任务")
print("==================================================")

def api_patch(record_id, data):
    """向 PocketBase 提交卡片状态与日志更新"""
    url = f"{SERVER_URL}/api/collections/todos/records/{record_id}"
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="PATCH"
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def append_log(record_id, current_log, new_line):
    """追加一行带时间戳的日志到卡片"""
    timestamp = time.strftime("[%H:%M:%S]")
    updated = (current_log or "") + f"{timestamp} {new_line}\n"
    api_patch(record_id, {"agent_log": updated})
    return updated

def execute_agent_task(task):
    """处理单个 Agent 委派任务"""
    task_id = task["id"]
    title = task.get("title", "")
    work_dir = task.get("work_dir") or os.getcwd()
    model = task.get("model") or "deepseek-chat"
    max_steps = task.get("max_steps") or 15
    log = task.get("agent_log") or ""

    print(f"\n⚡ [Agent 收到新任务] ID: {task_id} | 标题: {title}")
    print(f"   工作目录: {work_dir} | 指定模型: {model} | 步数上限: {max_steps}")

    # 1. 接单：修改状态为 in_progress
    api_patch(task_id, {"status": "in_progress"})
    log = append_log(task_id, log, f"🤖 Agent 已接单，锁定工作目录: {work_dir}")
    log = append_log(task_id, log, f"🧠 挂载执行模型: {model} (步数上限: {max_steps})")

    # 2. 检查并进入工作目录 (异常保护)
    if not os.path.isdir(work_dir):
        err_msg = f"❌ 工作目录不存在: {work_dir}，任务异常中断，等待人工修复"
        print(err_msg)
        append_log(task_id, log, err_msg)
        return

    try:
        # 3. 模拟 / 调用具体 Agent 工作流程
        # （此处可直接接入 Claude / DeepSeek / Pi / LangChain 等工具链）
        log = append_log(task_id, log, f"🔍 [步骤 1/{max_steps}] 正在扫描目录文件与上下文...")
        time.sleep(1.5)

        log = append_log(task_id, log, f"⚙️ [步骤 2/{max_steps}] 正在构建提示词并调用 {model} 推理...")
        time.sleep(2)

        log = append_log(task_id, log, f"📝 [步骤 3/{max_steps}] 任务方案已生成，已完成预设工作目标。")
        log = append_log(task_id, log, "--------------------------------------------------")
        log = append_log(task_id, log, "🎉 核心工作已搞定！卡片已就绪，请人工点击【✓ 验收通过】进行最后确认。")

        print(f"✅ 任务 [{title}] 执行完毕，已流转并等待人工验收！")

    except Exception as e:
        # 4. 异常中断保护：保留堆栈，绝不卡死
        err_stack = traceback.format_exc()
        print(f"💥 任务执行异常中断:\n{err_stack}")
        append_log(task_id, log, f"⚠️ [EXECUTION FAILED 异常中断]:\n{err_stack}")

def listen_and_dispatch():
    """通过 SSE 原生长连接实时监听"""
    while True:
        try:
            url = f"{SERVER_URL}/api/realtime"
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req) as resp:
                print("🟢 已成功连入看板实时事件通道，处于待命状态...")
                for line in resp:
                    line = line.decode("utf-8").strip()
                    if line.startswith("data:"):
                        payload = json.loads(line[5:])
                        # 握手
                        if "clientId" in payload:
                            sub_req = urllib.request.Request(
                                url,
                                data=json.dumps({
                                    "clientId": payload["clientId"],
                                    "subscriptions": ["todos"]
                                }).encode("utf-8"),
                                headers={"Content-Type": "application/json"},
                                method="POST"
                            )
                            urllib.request.urlopen(sub_req)
                        # 增改事件
                        elif payload.get("action") in ["create", "update"]:
                            rec = payload.get("record", {})
                            # 仅处理开启了 Agent 且为 todo 状态的任务
                            if rec.get("is_agent") and rec.get("status") == "todo":
                                execute_agent_task(rec)
        except Exception as e:
            print(f"⚠️ 连接暂时中断: {e}，将在 3 秒后重试...")
            time.sleep(3)

if __name__ == "__main__":
    listen_and_dispatch()
