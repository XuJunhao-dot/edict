---
name: kanban-truth-source
description: >
  防止“三省六部看板双数据源”导致旨意看不到/状态不一致。用于：创建/更新旨意前后必须确认写入的是7898看板的真实数据源，并做写后校验。NOT for：业务排障。
---

# 看板真源（Truth Source）与写入校验

## 目的
确保所有旨意/进展写入 **7898 看板真实数据源**，避免出现：
- 你在 CLI/脚本里“创建成功”，但 7898 看板看不到
- 同一任务 ID 在不同文件里状态不一致（例如一边 Done，一边 Zhongshu）

## 背景事实（你必须记住）
- 7898 看板服务（edict/dashboard/server.py）读取的数据目录在 **主工作区**：
  - `~/.openclaw/workspace/edict/data/tasks_source.json`
- 太子工作区可能存在另一份：
  - `~/.openclaw/workspace-taizi/edict/data/tasks_source.json`
- **两份不自动同步**。写错地方 = 看板永远看不到。

## 强制规则（每次写看板都必须执行）

### 规则 A：写入前确认“真源路径”
- 只允许写入：`~/.openclaw/workspace/edict/data/tasks_source.json`
- 如果你当前 cwd 不是 `~/.openclaw/workspace/edict`，必须显式切到该目录执行脚本：

```bash
cd ~/.openclaw/workspace/edict
python3 scripts/kanban_update.py create <id> "<title>" Zhongshu 中书省 中书令 "太子整理旨意"
```

> 禁止：在 `workspace-taizi` 下创建旨意后再“同步”。必须一次写对。

### 规则 B：写入后做“看板 API 校验”
写入成功后，必须用 7898 API 校验任务可见：

```bash
# 不走代理
env -u ALL_PROXY -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy \
  curl -sS http://127.0.0.1:7898/api/live-status \
  | python3 - <<'PY'
import sys, json
obj=json.load(sys.stdin)
# 请替换 TASK_ID
TASK_ID='<id>'
found=[t for t in obj.get('tasks',[]) if t.get('id')==TASK_ID]
print('FOUND' if found else 'NOT_FOUND')
if found:
  t=found[0]
  print(t.get('id'), t.get('state'), t.get('org'), t.get('updatedAt'))
PY
```

若返回 `NOT_FOUND`：
- 立即停止后续工作（避免在错误数据源上继续写）
- 回到规则 A，确认 cwd 与 tasks_source.json 位置

### 规则 C：禁止复用已存在 ID
- 创建前先查一次：
  - `python3 scripts/kanban_update.py show <id>`（若存在则改用新 ID）
- 若当天序号冲突，必须顺延（例如 010→011），不要覆盖历史记录。

## 常见错误与处理

### 错误 1：curl 显示 Empty reply from server
原因通常是本机代理环境变量（7890/7891）影响 localhost 探活。
处理：对 localhost 的探活/校验，统一用 `env -u ...` 移除代理变量。

### 错误 2：看板显示“Done/归档”，但你认为还在做
先确认你在看的是否是同一数据源（规则 B）。
若确实需要“复开”：
- 走皇上批准的状态纠偏：Done → Doing/Review（仅用于人工纠偏与追加产出）。

## 最小执行清单（每次创建/更新都照做）
1) cd ~/.openclaw/workspace/edict
2) 运行 kanban_update.py（create/progress/flow/state）
3) 用 7898 /api/live-status 查到该任务（FOUND）
4) 在飞书对皇上回奏阶段性产物链接
