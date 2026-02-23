# Nanoclaw Scheduled Tasks Feature - Analysis

**Date**: February 23, 2026  
**Repository Analyzed**: [qwibitai/nanoclaw](https://github.com/qwibitai/nanoclaw)  
**Purpose**: Understand the scheduled tasks implementation for potential reference

---

## Executive Summary

✅ **Nanoclaw has a fully-implemented scheduled tasks feature** that allows users to create recurring or one-time tasks that run AI agents automatically.

⚠️ **This feature is NOT directly applicable to opencode-server** because:
- Nanoclaw is a WhatsApp-based AI assistant with messaging capabilities
- OpenCode-server is a web-based coding tool deployment
- The architectures and use cases are fundamentally different

However, the implementation provides valuable insights into building scheduled task systems with AI agents.

---

## Feature Overview

The scheduled tasks feature in nanoclaw allows users to:

1. **Schedule recurring tasks** - Run AI agents at specific times or intervals
2. **Choose context mode** - Tasks can run with conversation history or in isolation
3. **Manage tasks** - Pause, resume, cancel, and list scheduled tasks
4. **Receive results** - Tasks can send messages back to users/groups
5. **Track history** - All task runs are logged with results and errors

### Use Cases from Nanoclaw README

```
@Andy send an overview of the sales pipeline every weekday morning at 9am
@Andy review the git history for the past week each Friday and update the README
@Andy every Monday at 8am, compile news on AI developments and message me a briefing
@Andy list all scheduled tasks across groups
@Andy pause the Monday briefing task
```

---

## Technical Architecture

### Core Components

#### 1. Database Schema (`src/db.ts`)

**scheduled_tasks table:**
```sql
CREATE TABLE IF NOT EXISTS scheduled_tasks (
    id TEXT PRIMARY KEY,
    group_folder TEXT NOT NULL,
    chat_jid TEXT NOT NULL,
    prompt TEXT NOT NULL,
    schedule_type TEXT NOT NULL,  -- 'cron' | 'interval' | 'once'
    schedule_value TEXT NOT NULL,
    context_mode TEXT DEFAULT 'isolated',  -- 'group' | 'isolated'
    next_run TEXT,
    last_run TEXT,
    last_result TEXT,
    status TEXT NOT NULL,  -- 'active' | 'paused' | 'completed'
    created_at TEXT NOT NULL
)
```

**task_run_logs table:**
```sql
CREATE TABLE IF NOT EXISTS task_run_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    run_at TEXT NOT NULL,
    duration_ms INTEGER NOT NULL,
    status TEXT NOT NULL,  -- 'success' | 'error'
    result TEXT,
    error TEXT,
    FOREIGN KEY (task_id) REFERENCES scheduled_tasks(id)
)
```

#### 2. Task Scheduler (`src/task-scheduler.ts`)

**Main Functions:**

- `startSchedulerLoop(deps)` - Starts the polling loop
- `runTask(task, deps)` - Executes a single scheduled task
- `getDueTasks()` - Queries database for tasks ready to run

**Key Features:**

1. **Poll Interval**: Configurable (default ~60 seconds)
2. **Next Run Calculation**: Automatic based on schedule type
3. **Queue Integration**: Uses GroupQueue for concurrency control
4. **Container Execution**: Runs tasks in isolated containers
5. **Error Handling**: Logs failures, pauses invalid tasks
6. **Context Management**: Supports group or isolated sessions

**Scheduler Loop Logic:**
```typescript
const loop = async () => {
    const dueTasks = getDueTasks();  // WHERE next_run <= NOW AND status = 'active'
    
    for (const task of dueTasks) {
        const currentTask = getTaskById(task.id);  // Re-check status
        if (!currentTask || currentTask.status !== 'active') {
            continue;
        }
        
        queue.enqueueTask(
            currentTask.chat_jid,
            currentTask.id,
            () => runTask(currentTask, deps)
        );
    }
    
    setTimeout(loop, SCHEDULER_POLL_INTERVAL);
};
```

**Task Execution Flow:**
```typescript
async function runTask(task, deps) {
    1. Resolve group folder and create directory
    2. Load group context and session
    3. Write tasks snapshot for container
    4. Run agent in container with task prompt
    5. Stream output and send messages to user
    6. Log task run (success/error, duration)
    7. Calculate next_run based on schedule type
    8. Update task in database
}
```

#### 3. MCP Tools (`container/agent-runner/src/ipc-mcp-stdio.ts`)

The agent running inside the container has access to these MCP tools:

**schedule_task** - Create a new scheduled task
```typescript
Parameters:
- prompt: string - What the agent should do
- schedule_type: 'cron' | 'interval' | 'once'
- schedule_value: string - See formats below
- context_mode: 'group' | 'isolated' (default: 'group')
- target_group_jid: string (optional, main group only)

Schedule Value Formats:
- cron: "*/5 * * * *" (every 5 min), "0 9 * * *" (daily at 9am)
- interval: "300000" (5 minutes in milliseconds)
- once: "2026-02-01T15:30:00" (local time, no Z suffix)
```

**list_tasks** - List all scheduled tasks
```typescript
Returns:
- From main group: All tasks across all groups
- From other groups: Only that group's tasks
```

**pause_task** - Pause a scheduled task
```typescript
Parameters:
- task_id: string
```

**resume_task** - Resume a paused task
```typescript
Parameters:
- task_id: string
```

**cancel_task** - Cancel and delete a scheduled task
```typescript
Parameters:
- task_id: string
```

#### 4. IPC Communication

Tasks are created via **IPC files** written by the agent:

**Directory Structure:**
```
/workspace/ipc/
  ├── messages/         # Outbound messages
  │   └── {timestamp}-{random}.json
  └── tasks/           # Task management commands
      └── {timestamp}-{random}.json
```

**IPC File Format (schedule_task):**
```json
{
  "type": "schedule_task",
  "prompt": "Check the weather and message me",
  "schedule_type": "cron",
  "schedule_value": "0 8 * * *",
  "context_mode": "isolated",
  "targetJid": "1234567890@s.whatsapp.net",
  "createdBy": "main",
  "timestamp": "2026-02-23T10:00:00.000Z"
}
```

**Host Processing (`src/ipc.ts`):**
- Watches `/workspace/ipc/tasks/` directory
- Reads and processes IPC files
- Calls appropriate database functions
- Deletes processed files

---

## Schedule Types

### 1. Cron Schedule

**Purpose**: Recurring tasks at specific times

**Format**: Standard cron expression
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
* * * * *
```

**Examples:**
```
"0 9 * * *"      - Daily at 9:00 AM
"0 9 * * 1-5"    - Weekdays at 9:00 AM
"*/15 * * * *"   - Every 15 minutes
"0 8,12,18 * * *" - At 8 AM, 12 PM, and 6 PM
"0 0 1 * *"      - First day of every month at midnight
```

**Implementation**:
- Uses `cron-parser` library (v5.5.0)
- Timezone-aware (uses `TIMEZONE` config)
- Next run calculated via `CronExpressionParser.parse().next()`

### 2. Interval Schedule

**Purpose**: Recurring tasks at fixed intervals

**Format**: Milliseconds as string

**Examples:**
```
"60000"      - Every 1 minute
"300000"     - Every 5 minutes
"3600000"    - Every 1 hour
"86400000"   - Every 24 hours
```

**Implementation**:
```typescript
if (task.schedule_type === 'interval') {
    const ms = parseInt(task.schedule_value, 10);
    nextRun = new Date(Date.now() + ms).toISOString();
}
```

### 3. Once Schedule

**Purpose**: One-time task at a specific time

**Format**: Local timestamp (ISO 8601 without timezone)

**Examples:**
```
"2026-02-23T15:30:00"  - Today at 3:30 PM local time
"2026-12-25T09:00:00"  - Christmas Day at 9 AM local time
```

**Important Notes:**
- ❌ Do NOT use UTC suffix: `"2026-02-23T15:30:00Z"` is invalid
- ❌ Do NOT use timezone offset: `"2026-02-23T15:30:00+05:30"` is invalid
- ✅ Use local time format: `"2026-02-23T15:30:00"`
- After execution, task status becomes 'completed' and next_run is NULL

---

## Context Modes

### Group Context Mode

**When to use:**
- Task needs access to conversation history
- Task should know about ongoing discussions
- Task references recent interactions or user preferences
- Examples: "Remind me about our discussion", "Follow up on my request"

**Behavior:**
- Task runs with the group's current session ID
- Has access to CLAUDE.md memory file
- Can see previous messages and context
- Session persists between task runs

### Isolated Context Mode

**When to use:**
- Task is self-contained
- Task doesn't need conversation history
- Fresh perspective is desired
- Examples: "Check the weather", "Generate a daily report"

**Behavior:**
- Task runs with no session ID (fresh session)
- No access to conversation history
- Must include all necessary context in the prompt
- Each run is completely independent

---

## Dependencies

From `package.json`:

```json
{
  "dependencies": {
    "@whiskeysockets/baileys": "^7.0.0-rc.9",  // WhatsApp integration
    "better-sqlite3": "^11.8.1",                // SQLite database
    "cron-parser": "^5.5.0",                    // Cron expression parsing
    "pino": "^9.6.0",                           // Logging
    "pino-pretty": "^13.0.0"                    // Log formatting
  }
}
```

**Key Dependency: cron-parser**
- GitHub: [harrisiirak/cron-parser](https://github.com/harrisiirak/cron-parser)
- Purpose: Parse and iterate cron expressions
- Features: Timezone support, validation, next occurrence calculation
- Used for calculating next_run times for cron schedules

---

## Configuration

From `src/config.ts`:

```typescript
export const SCHEDULER_POLL_INTERVAL = 60_000;  // 60 seconds
export const TIMEZONE = 'America/Los_Angeles';   // or from env var
export const IDLE_TIMEOUT = 30 * 60 * 1000;     // 30 minutes
```

**Configurable values:**
- **Poll interval**: How often to check for due tasks
- **Timezone**: Used for cron schedule calculations
- **Idle timeout**: When to close inactive task containers

---

## Error Handling

### Invalid Group Folder
```typescript
try {
    groupDir = resolveGroupFolderPath(task.group_folder);
} catch (err) {
    // Prevent retry churn for malformed legacy rows
    updateTask(task.id, { status: 'paused' });
    logger.error('Task has invalid group folder');
    logTaskRun({ status: 'error', error: err.message });
    return;
}
```

### Invalid Schedule Values

**Cron validation:**
```typescript
if (args.schedule_type === 'cron') {
    try {
        CronExpressionParser.parse(args.schedule_value);
    } catch {
        return {
            content: [{ 
                type: 'text', 
                text: 'Invalid cron: "..."' 
            }],
            isError: true
        };
    }
}
```

**Interval validation:**
```typescript
const ms = parseInt(args.schedule_value, 10);
if (isNaN(ms) || ms <= 0) {
    return { isError: true };
}
```

**Once timestamp validation:**
```typescript
// Reject UTC/timezone suffixes
if (/[Zz]$/.test(args.schedule_value) || /[+-]\d{2}:\d{2}$/.test(args.schedule_value)) {
    return { isError: true };
}

const date = new Date(args.schedule_value);
if (isNaN(date.getTime())) {
    return { isError: true };
}
```

### Task Execution Errors

All errors are logged to `task_run_logs`:
```typescript
logTaskRun({
    task_id: task.id,
    run_at: new Date().toISOString(),
    duration_ms: durationMs,
    status: error ? 'error' : 'success',
    result: result ? result.slice(0, 200) : null,
    error: error
});
```

---

## Testing

From `src/task-scheduler.test.ts`:

```typescript
describe('task scheduler', () => {
    it('pauses due tasks with invalid group folders to prevent retry churn', async () => {
        createTask({
            id: 'task-invalid-folder',
            group_folder: '../../outside',  // Invalid path
            schedule_type: 'once',
            next_run: new Date(Date.now() - 60_000).toISOString(),  // In the past
            status: 'active'
        });
        
        startSchedulerLoop(deps);
        await vi.advanceTimersByTimeAsync(10);
        
        const task = getTaskById('task-invalid-folder');
        expect(task?.status).toBe('paused');  // Should be paused, not retrying
    });
});
```

**Testing Strategy:**
- Uses `vitest` with fake timers
- Tests error handling and edge cases
- Verifies database state changes
- Mocks container execution

---

## Performance Considerations

### Polling vs Event-Driven

**Current Implementation**: Poll-based (checks every 60 seconds)

**Pros:**
- Simple implementation
- No complex event system
- Predictable resource usage

**Cons:**
- Not precise (up to 60-second delay)
- Wastes CPU checking when no tasks due
- Cannot schedule tasks more frequently than poll interval

**Alternative**: Event-driven with setTimeout
- Calculate time to next task
- Use setTimeout for precise timing
- More complex but more efficient

### Concurrency Control

Uses `GroupQueue` to manage parallel task execution:
```typescript
deps.queue.enqueueTask(
    currentTask.chat_jid,
    currentTask.id,
    () => runTask(currentTask, deps)
);
```

**Benefits:**
- Prevents multiple tasks from running simultaneously in same group
- Controls global concurrency across all groups
- Handles task queueing when at capacity

### Container Lifecycle

**Problem**: Task containers stay alive for 30 minutes (IDLE_TIMEOUT)

**Solution**: Early termination for tasks
```typescript
const TASK_CLOSE_DELAY_MS = 10000;  // 10 seconds

const scheduleClose = () => {
    if (closeTimer) return;
    closeTimer = setTimeout(() => {
        deps.queue.closeStdin(task.chat_jid);
    }, TASK_CLOSE_DELAY_MS);
};

// Called when task produces result
if (streamedOutput.result) {
    result = streamedOutput.result;
    await deps.sendMessage(task.chat_jid, streamedOutput.result);
    scheduleClose();  // Close container after 10s instead of 30min
}
```

---

## Security Considerations

### Path Traversal Prevention

```typescript
// In resolveGroupFolderPath()
if (groupFolder.includes('..') || groupFolder.startsWith('/')) {
    throw new Error('Invalid group folder');
}
```

### Per-Group Isolation

- Each group can only see its own tasks (except main group)
- Tasks run in separate containers with mounted group folders
- No cross-group access to data or sessions

### Main Group Privileges

The main group (self-chat) has special permissions:
- Can list all tasks across all groups
- Can create tasks for other groups via `target_group_jid`
- Can manage any task

---

## Applicability to OpenCode-Server

### Why It Doesn't Fit

1. **Different Architecture**
   - Nanoclaw: Long-running Node.js process with WhatsApp connection
   - OpenCode-server: Stateless Docker container running opencode CLI

2. **Different Use Case**
   - Nanoclaw: Proactive assistant that sends messages
   - OpenCode-server: Reactive tool that responds to web requests

3. **No Messaging System**
   - Nanoclaw: Sends WhatsApp messages to users/groups
   - OpenCode-server: Only responds via HTTP to web interface

4. **No Persistence**
   - Nanoclaw: SQLite database persists across restarts
   - OpenCode-server: Ephemeral storage, sessions lost on restart

5. **No Extension Points**
   - Nanoclaw: Custom Node.js application we control
   - OpenCode-server: Wrapper around opencode-ai npm package

### What Could Be Learned

If building a similar system:

1. **Database Schema**: The scheduled_tasks and task_run_logs design is solid
2. **Cron Parsing**: Using cron-parser for flexible scheduling
3. **Context Modes**: Supporting both isolated and contextual execution
4. **IPC Pattern**: File-based IPC for container communication
5. **Error Handling**: Automatic pausing of invalid tasks
6. **Logging**: Comprehensive task run history

---

## Alternative Solutions for OpenCode

If you want scheduled tasks with OpenCode:

### Option 1: External Scheduler (Recommended)

Use a service like **GitHub Actions** or **cron** to trigger OpenCode:

```yaml
# .github/workflows/daily-report.yml
name: Daily Report
on:
  schedule:
    - cron: '0 9 * * 1-5'  # Weekdays at 9 AM
jobs:
  report:
    runs-on: ubuntu-latest
    steps:
      - name: Run OpenCode
        run: |
          npx opencode-ai "Generate daily report"
```

### Option 2: Separate Automation Service

Build a lightweight scheduler that calls OpenCode API:

```typescript
// scheduler.ts
import cron from 'node-cron';
import fetch from 'node-fetch';

cron.schedule('0 9 * * *', async () => {
    await fetch('https://opencode-server.onrender.com/api/session', {
        method: 'POST',
        body: JSON.stringify({
            prompt: 'Generate daily report'
        })
    });
});
```

### Option 3: Cloud Functions

Use AWS Lambda, Google Cloud Functions, or similar:

```javascript
// lambda.js
exports.handler = async (event) => {
    // Triggered by EventBridge (cron)
    const response = await fetch(opencode_url, {
        method: 'POST',
        body: JSON.stringify({ prompt: event.prompt })
    });
    return response.json();
};
```

---

## Conclusion

✅ **Nanoclaw has a robust scheduled tasks implementation** suitable for a chat-based AI assistant.

❌ **The feature is NOT directly applicable to opencode-server** due to fundamental architectural differences.

💡 **Key Takeaways:**
- Poll-based scheduling with cron-parser for flexibility
- SQLite persistence with comprehensive logging
- IPC-based communication for containerized agents
- Support for multiple schedule types and context modes
- Proper error handling and security considerations

🔨 **If you need scheduled tasks:**
- For OpenCode: Use external schedulers (GitHub Actions, cron, cloud functions)
- For custom assistant: Study nanoclaw's implementation as a reference
- For WhatsApp bot: Consider forking nanoclaw directly

---

## References

- **Nanoclaw Repository**: https://github.com/qwibitai/nanoclaw
- **Cron Parser Library**: https://github.com/harrisiirak/cron-parser
- **OpenCode Documentation**: https://opencode.ai/docs
- **Cron Expression Syntax**: https://crontab.guru/

**Analysis Date**: February 23, 2026  
**Nanoclaw Version**: Latest from main branch  
**Analyst**: GitHub Copilot Agent
