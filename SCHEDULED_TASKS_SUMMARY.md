# Scheduled Tasks Feature - Quick Summary

## 🎯 TL;DR - The Perfect Solution Found!

**New Discovery**: [OpenCode-Scheduler](https://github.com/different-ai/opencode-scheduler) ⭐

✅ **Use opencode-scheduler** - It's specifically built for OpenCode and is the ideal solution!

---

## Original Analysis

**Question**: Does nanoclaw have a scheduled tasks feature?  
**Answer**: ✅ **YES** - Fully implemented and production-ready

**But**: Nanoclaw is a WhatsApp bot, not compatible with OpenCode.

---

## What It Does

Nanoclaw allows users to schedule AI agents to run automatically:

```
@Andy send an overview of the sales pipeline every weekday morning at 9am
@Andy every Monday at 8am, compile news and message me a briefing
@Andy list all scheduled tasks
@Andy pause the Monday briefing task
```

---

## How It Works

### 1. Schedule Types

| Type | Format | Example | Use Case |
|------|--------|---------|----------|
| **cron** | Standard cron expression | `"0 9 * * *"` | Daily at 9 AM |
| **interval** | Milliseconds | `"3600000"` | Every hour |
| **once** | Local timestamp | `"2026-02-23T15:30:00"` | One-time at 3:30 PM |

### 2. Context Modes

- **group**: Task runs with conversation history (for context-aware tasks)
- **isolated**: Task runs fresh (for independent tasks)

### 3. Architecture

```
┌─────────────────────────────────────────────┐
│ Scheduler Loop (polls every 60s)           │
│  - Queries SQLite for due tasks             │
│  - Enqueues tasks for execution             │
└─────────────────┬───────────────────────────┘
                  │
                  v
┌─────────────────────────────────────────────┐
│ Task Execution                               │
│  - Runs AI agent in isolated container      │
│  - Sends results via WhatsApp               │
│  - Logs execution history                   │
│  - Calculates next run time                 │
└─────────────────────────────────────────────┘
```

### 4. Database Schema

**scheduled_tasks**:
- id, group_folder, chat_jid, prompt
- schedule_type, schedule_value, context_mode
- next_run, last_run, status, created_at

**task_run_logs**:
- task_id, run_at, duration_ms
- status, result, error

---

## Key Components

### Files

| File | Purpose |
|------|---------|
| `src/task-scheduler.ts` | Main scheduler loop and task execution |
| `src/db.ts` | SQLite database operations |
| `container/agent-runner/src/ipc-mcp-stdio.ts` | MCP tools for managing tasks |
| `src/ipc.ts` | Processes task creation/management requests |

### Dependencies

- `cron-parser` (^5.5.0) - Parse cron expressions
- `better-sqlite3` (^11.8.1) - SQLite database
- `@whiskeysockets/baileys` (^7.0.0-rc.9) - WhatsApp integration

### MCP Tools

- `schedule_task` - Create new task
- `list_tasks` - View scheduled tasks
- `pause_task` - Pause a task
- `resume_task` - Resume a paused task
- `cancel_task` - Delete a task

---

## Is This Applicable to OpenCode-Server?

### ❌ NO - Not Directly Applicable

**Reasons:**

1. **Different Purpose**
   - Nanoclaw: WhatsApp chat bot that proactively sends messages
   - OpenCode-server: Web-based coding tool for on-demand use

2. **Different Architecture**
   - Nanoclaw: Long-running Node.js app with SQLite database
   - OpenCode-server: Docker container running opencode CLI

3. **No Messaging System**
   - Nanoclaw: Sends WhatsApp messages
   - OpenCode-server: HTTP request/response only

4. **No Persistence**
   - Nanoclaw: SQLite persists across restarts
   - OpenCode-server: Ephemeral storage on Render.com free tier

### ✅ What You CAN Do

If you want scheduled tasks with OpenCode:

#### Option 1: GitHub Actions
```yaml
name: Daily Task
on:
  schedule:
    - cron: '0 9 * * *'
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - run: npx opencode-ai "Your task"
```

#### Option 2: External Cron Service
- cron-job.org
- EasyCron
- AWS EventBridge

#### Option 3: Cloud Functions
- AWS Lambda
- Google Cloud Functions
- Cloudflare Workers

---

## Example Nanoclaw Usage

### Create a Daily Reminder
```
@Andy schedule a task to remind me about standup every weekday at 8:45am
```

Agent will:
1. Call `schedule_task` MCP tool
2. Write IPC file to `/workspace/ipc/tasks/`
3. Host reads IPC file and creates database entry
4. Scheduler picks up task when due
5. Agent runs in container and sends WhatsApp message

### List All Tasks
```
@Andy list all scheduled tasks
```

Returns:
```
Scheduled tasks:
- [task-1] Remind me about standup... (cron: 0 8 * * 1-5) - active, next: 2026-02-24T08:00:00
- [task-2] Weekly report... (cron: 0 17 * * 5) - active, next: 2026-02-28T17:00:00
```

### Pause a Task
```
@Andy pause task-1
```

Task status changes to 'paused' and won't run until resumed.

---

## Cron Examples

| Expression | Description |
|------------|-------------|
| `0 9 * * *` | Every day at 9:00 AM |
| `0 9 * * 1-5` | Weekdays at 9:00 AM |
| `*/15 * * * *` | Every 15 minutes |
| `0 8,12,18 * * *` | At 8 AM, 12 PM, and 6 PM |
| `0 0 * * 0` | Every Sunday at midnight |
| `0 0 1 * *` | First day of each month |

Test your cron expressions: https://crontab.guru/

---

## Summary

| Aspect | Nanoclaw | OpenCode-Server |
|--------|----------|----------------|
| Scheduled Tasks | ✅ Full support | ❌ Not applicable |
| Use Case | Proactive assistant | On-demand tool |
| Messaging | WhatsApp | Web interface |
| Persistence | SQLite | Ephemeral |
| Architecture | Custom Node.js app | CLI wrapper |
| **Recommendation** | Use as-is or fork | Use external schedulers |

---

## For More Details

See [NANOCLAW_SCHEDULED_TASKS_ANALYSIS.md](./NANOCLAW_SCHEDULED_TASKS_ANALYSIS.md) for:
- Complete technical architecture
- Database schema details
- Code examples
- Performance considerations
- Security analysis
- Testing approach

---

## 🆕 Better Solution: OpenCode-Scheduler

After analyzing nanoclaw, we discovered **[opencode-scheduler](https://github.com/different-ai/opencode-scheduler)** - the perfect solution!

### Why It's Better

| Aspect | Nanoclaw | OpenCode-Scheduler | Winner |
|--------|----------|-------------------|--------|
| Purpose | WhatsApp bot | OpenCode automation | ⭐ OpenCode-Scheduler |
| Installation | Separate app | Simple plugin | ⭐ OpenCode-Scheduler |
| Setup | Complex | One config line | ⭐ OpenCode-Scheduler |
| OS Integration | None | Native schedulers | ⭐ OpenCode-Scheduler |
| Compatibility | WhatsApp only | Any OpenCode | ⭐ OpenCode-Scheduler |
| Maintenance | High | Low | ⭐ OpenCode-Scheduler |

### Quick Start

```json
// opencode.json
{
  "plugin": ["opencode-scheduler"]
}
```

Then just say:
```
Schedule a daily job at 9am to check my email
```

**See [OPENCODE_SCHEDULER_SOLUTION.md](./OPENCODE_SCHEDULER_SOLUTION.md) for complete details!**

---

**Analysis Date**: February 23, 2026  
**Original Analysis**: https://github.com/qwibitai/nanoclaw  
**Recommended Solution**: ⭐ https://github.com/different-ai/opencode-scheduler  
**Conclusion**: OpenCode-Scheduler is the perfect solution for scheduled tasks with OpenCode!
