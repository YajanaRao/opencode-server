# OpenCode-Scheduler - The Perfect Solution! ✅

**Date**: February 23, 2026  
**Repository**: [different-ai/opencode-scheduler](https://github.com/different-ai/opencode-scheduler)  
**Verdict**: ⭐ **This is the ideal solution for scheduled tasks with OpenCode!**

---

## Executive Summary

After reviewing nanoclaw's scheduled tasks implementation, we discovered **opencode-scheduler** - a purpose-built OpenCode plugin that provides native scheduled task support.

**Comparison:**
- ❌ **Nanoclaw**: WhatsApp bot with custom scheduling (not compatible with OpenCode)
- ✅ **OpenCode-Scheduler**: Official OpenCode plugin (perfect fit!)

---

## Why OpenCode-Scheduler is Perfect

### 🎯 1. Built Specifically for OpenCode

Unlike nanoclaw (which is a separate WhatsApp assistant), opencode-scheduler is:
- An official OpenCode plugin
- Designed to work with opencode-ai package
- Integrates seamlessly with existing OpenCode installations
- No custom code or architecture changes needed

### 🔌 2. Simple Installation

```json
// opencode.json
{
  "plugin": ["opencode-scheduler"]
}
```

That's it! Just add one line to your config.

### 🖥️ 3. Native OS Schedulers

Uses your operating system's built-in scheduler:

| Platform | Scheduler | Benefits |
|----------|-----------|----------|
| **macOS** | launchd | Apple's native task scheduler |
| **Linux (systemd)** | systemd --user | Modern Linux standard |
| **Linux (POSIX)** | cron | Universal fallback |
| **Windows** | Task Scheduler | Windows native |

**Advantages:**
- ✅ Survives reboots
- ✅ Catches up on missed runs (if computer was sleeping)
- ✅ Better resource management
- ✅ System-level reliability
- ✅ No custom polling loops needed

### 🔄 4. Supervised Execution

**Reliability guarantees:**
- **No overlap**: If previous run is still active, next tick is skipped
- **Non-interactive**: Scheduled runs auto-deny prompts (won't hang)
- **Optional timeout**: Hard-stop long runs (SIGTERM, then SIGKILL)

### 📦 5. Works with OpenCode-Server

Since opencode-scheduler is a plugin, it works with:
- ✅ Local OpenCode installations
- ✅ OpenCode web deployments
- ✅ OpenCode-server (after setup)
- ✅ Any project with `opencode.json`

### 🌍 6. Cross-Platform Support

Full support for macOS, Linux, and Windows with automatic backend selection.

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenCode Installation                     │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ opencode.json                                          │ │
│  │ {                                                      │ │
│  │   "plugin": ["opencode-scheduler"]                    │ │
│  │ }                                                      │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ opencode-scheduler Plugin                              │ │
│  │ - schedule_job                                         │ │
│  │ - list_jobs                                            │ │
│  │ - run_job                                              │ │
│  │ - update_job                                           │ │
│  │ - delete_job                                           │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Job Files (~/.config/opencode/scheduler/scopes/)       │ │
│  │ - standing-desk.json                                   │ │
│  │ - daily-report.json                                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              OS Native Scheduler (launchd/systemd)          │
│                                                              │
│  At scheduled time:                                          │
│  1. OS scheduler triggers supervisor script                  │
│  2. Supervisor checks if previous run is still active        │
│  3. If clear, runs: opencode run {prompt}                   │
│  4. Appends logs to job log file                            │
│  5. Updates job metadata (last_run, next_run)               │
└─────────────────────────────────────────────────────────────┘
```

### Workflow

1. **Schedule a Job**
   ```
   User: "Schedule a daily job at 9am to search for standing desks under $300"
   ```

2. **Plugin Creates Job**
   - Parses natural language to cron expression: `0 9 * * *`
   - Creates job file: `~/.config/opencode/scheduler/scopes/{workdir}/jobs/standing-desk.json`
   - Installs OS timer (launchd plist / systemd unit / cron entry)

3. **OS Scheduler Triggers**
   - At 9:00 AM daily, OS scheduler activates
   - Calls supervisor script with job ID
   - Supervisor checks no overlap, then executes

4. **Job Executes**
   - Runs: `opencode run "search for standing desks under $300"`
   - Logs output to: `~/.config/opencode/logs/standing-desk.log`
   - Updates metadata in job file

---

## Features

### Natural Language Scheduling

Just describe what you want:

```
"Schedule a daily job at 9am to..."
"Schedule a job every Monday at 8am to..."
"Schedule a job every 6 hours to..."
```

The plugin converts this to proper cron expressions automatically.

### Cron Syntax Support

Standard 5-field cron expressions:

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-6, Sunday=0)
│ │ │ │ │
* * * * *
```

**Examples:**

| Expression | Meaning |
|------------|---------|
| `0 9 * * *` | Daily at 9:00 AM |
| `0 */6 * * *` | Every 6 hours |
| `30 8 * * 1` | Mondays at 8:30 AM |
| `0 9,17 * * *` | At 9 AM and 5 PM daily |

### Job Management Commands

| Command | Example |
|---------|---------|
| **Schedule** | `Schedule a daily job at 9am to check my email` |
| **List** | `Show my scheduled jobs` |
| **Get details** | `Show details for standing-desk` |
| **Update** | `Update standing-desk to run at 10am` |
| **Run now** | `Run the standing-desk job now` |
| **View logs** | `Show logs for standing-desk` |
| **Delete** | `Delete the standing-desk job` |

### Workdir Scoping

Jobs are scoped by working directory, so:
- Different projects don't collide
- Each project has its own set of jobs
- Jobs pick up the correct `opencode.json` and MCP configs

### Timeout Support

```typescript
{
  "timeoutSeconds": 300  // Kill job after 5 minutes
}
```

Prevents runaway jobs from consuming resources.

---

## Installation for OpenCode-Server

### Option 1: Add to Dockerfile (Recommended)

```dockerfile
# OpenCode Web Server with Scheduler
FROM node:20-slim

# ... existing setup ...

# Install OpenCode with scheduler plugin
RUN npm install -g opencode-ai opencode-scheduler

# Create opencode config
USER opencode
WORKDIR /home/opencode
RUN mkdir -p .config/opencode && \
    echo '{"plugin": ["opencode-scheduler"]}' > .config/opencode/opencode.json

# ... rest of Dockerfile ...
```

### Option 2: Local Installation

If running OpenCode locally:

```bash
# Install plugin
npm install -g opencode-scheduler

# Add to your opencode.json
cat >> opencode.json << 'EOF'
{
  "plugin": ["opencode-scheduler"]
}
EOF
```

### Option 3: Per-Project Installation

```bash
# In your project directory
npm install opencode-scheduler --save-dev

# Add to opencode.json
{
  "plugin": ["opencode-scheduler"]
}
```

---

## Usage Examples

### Daily Reports

```
Schedule a job every weekday at 9am to:
1. Check my GitHub notifications
2. Summarize issues assigned to me
3. Send summary via email using MCP email tool
```

### Website Monitoring

```
Schedule a job every 6 hours to:
1. Check if my website is up
2. If down, alert me on Slack
3. Log the status to a file
```

### Deal Hunting

```
Schedule a daily job at 9am to:
1. Search Facebook Marketplace for standing desks under $300
2. Filter for good condition and local pickup
3. Send top 5 deals to my Telegram
```

### Data Backups

```
Schedule a job every Sunday at 2am to:
1. Export my notes from Notion
2. Commit to GitHub backup repo
3. Verify backup completed successfully
```

### Code Reviews

```
Schedule a job every Monday at 8am to:
1. List all open PRs in my repos
2. Check which ones need my review
3. Send me a prioritized list via Slack
```

---

## Comparison: Nanoclaw vs OpenCode-Scheduler

| Aspect | Nanoclaw | OpenCode-Scheduler |
|--------|----------|-------------------|
| **Purpose** | WhatsApp AI assistant | OpenCode task automation |
| **Installation** | Separate Node.js app | OpenCode plugin |
| **Configuration** | Complex (SQLite, IPC, containers) | Simple (one line in config) |
| **Platform** | WhatsApp only | Any OpenCode project |
| **Scheduler** | Custom polling loop (60s) | Native OS schedulers |
| **Reliability** | Manual implementation | OS-guaranteed |
| **Reboots** | Requires always-on process | Survives reboots |
| **Missed Runs** | No catch-up | Catches up automatically |
| **Overlap Prevention** | Manual queue management | Built-in supervision |
| **Timeout Support** | Custom implementation | Built-in |
| **Dependencies** | cron-parser, better-sqlite3, baileys | @opencode-ai/plugin only |
| **Complexity** | High (custom architecture) | Low (just a plugin) |
| **Maintenance** | You maintain scheduler | OS maintains scheduler |
| **Integration** | None with OpenCode | Perfect integration |
| **Use Case** | Chat bot automation | General task automation |
| **Best For** | WhatsApp assistant | OpenCode workflows |

**Winner**: **OpenCode-Scheduler** (for OpenCode use cases)

---

## Architecture Comparison

### Nanoclaw Architecture (Complex)

```
WhatsApp → Baileys → SQLite → Polling Loop → Container → Agent
                       ↓
                   Task Scheduler
                   (Custom, 60s poll)
```

- Custom polling implementation
- Requires always-on Node.js process
- SQLite database management
- IPC file communication
- Container orchestration
- Manual queue management

### OpenCode-Scheduler Architecture (Simple)

```
User → OpenCode → Plugin → Job File → OS Scheduler → Supervised Execution
```

- Leverages OS scheduler (launchd/systemd/cron)
- No polling needed
- No database needed
- No custom process management
- Works with existing OpenCode

---

## Technical Details

### Storage Location

```
~/.config/opencode/
├── scheduler/
│   ├── scopes/
│   │   └── {workdir-hash}/
│   │       └── jobs/
│   │           ├── job-name.json
│   │           └── job-name.log
│   └── supervisor.pl
└── opencode-scheduler.json
```

### Job File Format

```json
{
  "name": "standing-desk",
  "prompt": "search for standing desks under $300",
  "schedule": "0 9 * * *",
  "workdir": "/home/user/projects/myproject",
  "timeoutSeconds": 0,
  "enabled": true,
  "lastRun": "2026-02-23T09:00:00Z",
  "nextRun": "2026-02-24T09:00:00Z",
  "metadata": {
    "created": "2026-02-20T10:00:00Z",
    "updated": "2026-02-23T09:00:00Z"
  }
}
```

### OS Integration

**macOS (launchd):**
```xml
<!-- ~/Library/LaunchAgents/com.opencode.job.standing-desk.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.opencode.job.standing-desk</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/supervisor.pl</string>
        <string>standing-desk</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
```

**Linux (systemd):**
```ini
# ~/.config/systemd/user/opencode-job-standing-desk.timer
[Unit]
Description=OpenCode Job: standing-desk

[Timer]
OnCalendar=*-*-* 09:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

**Cron fallback:**
```cron
# Added by opencode-scheduler
0 9 * * * /path/to/supervisor.pl standing-desk
```

---

## Benefits Over Custom Solutions

### 1. No Maintenance Burden

| Custom Solution (Nanoclaw) | OpenCode-Scheduler |
|---------------------------|-------------------|
| Maintain custom scheduler | OS maintains scheduler |
| Handle edge cases yourself | OS handles edge cases |
| Debug custom code | Plugin is tested |
| Update dependencies | One plugin update |

### 2. Better Reliability

| Feature | Custom | OpenCode-Scheduler |
|---------|--------|-------------------|
| Survives reboots | ❌ Need process manager | ✅ Built-in |
| Catches missed runs | ❌ Manual implementation | ✅ Automatic |
| No overlap | ❌ Manual queue | ✅ Supervised |
| Timeout | ❌ Custom code | ✅ Built-in |
| Error recovery | ❌ Manual | ✅ OS handles it |

### 3. Simpler Setup

**Nanoclaw:**
1. Clone repository
2. Install dependencies
3. Set up SQLite
4. Configure WhatsApp
5. Set up containers
6. Start process
7. Keep running 24/7

**OpenCode-Scheduler:**
1. Add plugin to config
2. Done!

---

## Migration from Alternative Solutions

### From GitHub Actions

**Before:**
```yaml
# .github/workflows/daily-task.yml
on:
  schedule:
    - cron: '0 9 * * *'
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - run: npx opencode-ai "..."
```

**After:**
```
Schedule a daily job at 9am to...
```

**Benefits:**
- ✅ Runs locally (no GitHub dependency)
- ✅ Faster execution
- ✅ Access to local files
- ✅ Can use local MCP servers

### From External Cron Services

**Before:**
- Set up account on cron-job.org
- Configure webhook to hit your server
- Handle authentication
- Manage external dependency

**After:**
```
Schedule a job every 6 hours to...
```

**Benefits:**
- ✅ No external service needed
- ✅ No internet dependency
- ✅ No authentication setup
- ✅ Runs offline

### From Cloud Functions

**Before:**
- Set up AWS Lambda / Google Cloud Function
- Configure EventBridge / Cloud Scheduler
- Deploy function code
- Pay for executions

**After:**
```
Schedule a weekly job to...
```

**Benefits:**
- ✅ No cloud account needed
- ✅ Zero cost
- ✅ Simpler setup
- ✅ Local execution

---

## Limitations & Considerations

### 1. Requires Local Installation

- ❌ Won't work on Render.com free tier (container restarts)
- ✅ Perfect for local development
- ✅ Great for personal computers
- ✅ Works on dedicated servers

### 2. Computer Must Be Running

- ❌ Tasks don't run if computer is off
- ✅ Catches up on missed runs when it wakes
- ✅ Perfect for always-on machines
- ✅ Use cloud VM for 24/7 tasks

### 3. Platform-Specific Features

| Feature | macOS | Linux | Windows |
|---------|-------|-------|---------|
| Native scheduler | ✅ launchd | ✅ systemd | ✅ Task Scheduler |
| Supervised runs | ✅ | ✅ | ⚠️ Limited |
| Catch missed runs | ✅ | ✅ | ⚠️ Depends |
| No overlap | ✅ | ✅ | ⚠️ Not guaranteed |

### 4. Resource Usage

- Scheduled jobs consume CPU/memory when running
- Supervisor adds minimal overhead
- OS scheduler is very lightweight
- Consider timeout for long-running tasks

---

## Recommendation

### ✅ Use OpenCode-Scheduler If:

- ✅ You're using OpenCode (obviously!)
- ✅ You have a local machine or dedicated server
- ✅ You want simple, reliable scheduling
- ✅ You want native OS integration
- ✅ You value low maintenance

### ❌ Use Alternatives If:

- ❌ You're on Render.com free tier (ephemeral storage)
- ❌ You need guaranteed 24/7 uptime without a dedicated server
- ❌ You're building a WhatsApp bot (use Nanoclaw)
- ❌ You need multi-platform distributed scheduling

### 🎯 For OpenCode-Server Specifically:

**Current Setup (Render.com free tier):**
- ❌ OpenCode-Scheduler won't persist (container restarts)
- ✅ Use GitHub Actions instead (as documented)

**Future Setup (Dedicated server):**
- ✅ OpenCode-Scheduler is perfect!
- Install on server, set up jobs, done!

---

## Conclusion

**OpenCode-Scheduler is the ideal solution for scheduled tasks with OpenCode.**

**Comparison Summary:**

| Solution | Best For | Complexity | Reliability |
|----------|----------|------------|-------------|
| **Nanoclaw** | WhatsApp bots | High | Good |
| **OpenCode-Scheduler** | OpenCode workflows | Low | Excellent |
| **GitHub Actions** | Stateless deployments | Medium | Excellent |
| **Cloud Functions** | Distributed systems | Medium | Excellent |

**Final Recommendation:**

1. **Local/Server OpenCode**: Use **opencode-scheduler** ⭐
2. **OpenCode on Render.com free tier**: Use **GitHub Actions**
3. **WhatsApp assistant**: Use **Nanoclaw**
4. **Distributed system**: Use **Cloud Functions**

---

## Resources

- **OpenCode-Scheduler Repository**: https://github.com/different-ai/opencode-scheduler
- **OpenCode Documentation**: https://opencode.ai/docs
- **Plugin API**: https://opencode.ai/docs/plugins
- **Cron Expression Tester**: https://crontab.guru/

---

**Analysis Date**: February 23, 2026  
**Verdict**: ⭐ **OpenCode-Scheduler is the perfect solution for OpenCode scheduled tasks!**
