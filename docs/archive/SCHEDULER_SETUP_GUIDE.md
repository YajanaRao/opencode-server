# OpenCode-Scheduler Setup Guide

This guide explains how to use the opencode-scheduler plugin with your opencode-server deployment.

## 🎯 What is OpenCode-Scheduler?

OpenCode-scheduler is an official OpenCode plugin that enables scheduled task automation using your operating system's native scheduler (launchd on macOS, systemd on Linux, cron as fallback).

**Repository**: https://github.com/different-ai/opencode-scheduler

## ⚠️ Important: Deployment Environment

### ❌ Render.com Free Tier Limitation

**The scheduler will NOT work properly on Render.com free tier** because:
- Containers restart frequently (after 15min inactivity)
- Ephemeral storage - all scheduler state is lost on restart
- No persistent systemd/cron daemon

**For Render.com free tier deployments**: Use GitHub Actions instead for scheduled tasks.

### ✅ Where OpenCode-Scheduler Works

The plugin works perfectly on:
- **Dedicated servers** (VPS, cloud VM with persistent storage)
- **Local development** (your laptop/desktop)
- **Self-hosted Docker** with persistent volumes
- **Render.com paid plans** with persistent disks

## 📦 What's Included

This repository now includes:

1. **`opencode.json`** - Configuration file with scheduler plugin enabled
2. **Updated Dockerfile** - Installs opencode-scheduler plugin
3. **This guide** - Setup and usage instructions

## 🚀 Quick Start (Local/Dedicated Server)

### Option 1: Use Pre-built Docker Image

```bash
# Build the image
docker build -t opencode-server .

# Run with persistent storage for scheduler
docker run -d \
  -p 4096:4096 \
  -v opencode-scheduler:/home/opencode/.config/opencode \
  -e OPENCODE_SERVER_PASSWORD=your-password \
  -e PORT=4096 \
  opencode-server
```

The `-v` flag creates a persistent volume for scheduler state.

### Option 2: Local OpenCode Installation

If you have OpenCode installed locally:

```bash
# Install the scheduler plugin
npm install -g opencode-scheduler

# Copy the opencode.json to your config directory
mkdir -p ~/.config/opencode
cp opencode.json ~/.config/opencode/

# Start OpenCode
opencode serve --hostname 0.0.0.0 --port 4096
```

## 📝 Using the Scheduler

Once installed, you can schedule tasks using natural language:

### Create a Scheduled Job

```
Schedule a daily job at 9am to check my GitHub notifications and send me a summary
```

The plugin will:
1. Parse your natural language into a cron expression
2. Create a job file in `~/.config/opencode/scheduler/scopes/`
3. Install a timer in your OS scheduler (systemd/launchd/cron)

### Example Scheduled Tasks

**Daily Report**:
```
Schedule a job every weekday at 9am to:
1. Summarize my GitHub issues assigned to me
2. List PRs that need my review
3. Send the summary via email
```

**Website Monitoring**:
```
Schedule a job every 6 hours to:
1. Check if my website is responding
2. If down, alert me via Slack
3. Log the status to a file
```

**Data Backup**:
```
Schedule a job every Sunday at 2am to:
1. Export my notes from Notion
2. Commit to GitHub backup repository
3. Verify backup completed successfully
```

### Manage Scheduled Jobs

| Command | Example |
|---------|---------|
| **List jobs** | `Show my scheduled jobs` |
| **Get details** | `Show details for github-notifications` |
| **Update schedule** | `Update github-notifications to run at 10am` |
| **Run immediately** | `Run the github-notifications job now` |
| **View logs** | `Show logs for github-notifications` |
| **Delete job** | `Delete the github-notifications job` |

## 🔧 Configuration

### opencode.json

```json
{
  "$schema": "https://opencode.ai/schema/config.json",
  "plugin": ["opencode-scheduler"],
  "description": "OpenCode configuration with scheduler plugin for automated task execution"
}
```

You can add additional plugins or configuration as needed:

```json
{
  "plugin": ["opencode-scheduler", "other-plugin"],
  "someOtherConfig": "value"
}
```

### Environment Variables

The Docker container supports these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Port to listen on | 10000 |
| `OPENCODE_SERVER_PASSWORD` | Access password | (required) |
| `OPENCODE_SERVER_USERNAME` | Access username | admin |
| `GITHUB_TOKEN` | For cloning Notes repo | (optional) |

## 🐳 Docker Deployment (Dedicated Server)

### Using Docker Compose

Create a `docker-compose.yml`:

```yaml
version: '3.8'

services:
  opencode-server:
    build: .
    ports:
      - "4096:4096"
    environment:
      - PORT=4096
      - OPENCODE_SERVER_PASSWORD=${OPENCODE_SERVER_PASSWORD}
      - OPENCODE_SERVER_USERNAME=admin
    volumes:
      # Persistent storage for scheduler state
      - opencode-config:/home/opencode/.config/opencode
      # Persistent storage for logs
      - opencode-logs:/home/opencode/.config/opencode/logs
    restart: unless-stopped

volumes:
  opencode-config:
  opencode-logs:
```

Deploy:
```bash
# Set password
export OPENCODE_SERVER_PASSWORD="your-secure-password"

# Start the service
docker-compose up -d

# View logs
docker-compose logs -f
```

### On a VPS (Ubuntu/Debian)

```bash
# 1. Clone the repository
git clone https://github.com/YajanaRao/opencode-server.git
cd opencode-server

# 2. Build the image
docker build -t opencode-server .

# 3. Run with persistent storage
docker run -d \
  --name opencode-server \
  --restart unless-stopped \
  -p 4096:4096 \
  -v /opt/opencode-scheduler:/home/opencode/.config/opencode \
  -e PORT=4096 \
  -e OPENCODE_SERVER_PASSWORD="your-secure-password" \
  opencode-server

# 4. Check it's running
docker ps
docker logs opencode-server
```

Access at: `http://your-server-ip:4096`

## 🔒 Security Considerations

### Scheduled Jobs

Scheduled jobs run with the same permissions as OpenCode:
- Can access files in the working directory
- Can use configured MCP servers
- Can make network requests

**Best practices:**
1. Review scheduled job prompts carefully
2. Use timeouts for long-running jobs
3. Monitor job logs regularly
4. Test jobs manually before scheduling

### Example with Timeout

```
Schedule a job with 5-minute timeout every day at 9am to check my email
```

The plugin will set `timeoutSeconds: 300` to prevent runaway jobs.

## 📊 Scheduler Storage Location

The scheduler stores data in:
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

**In Docker**, this is at `/home/opencode/.config/opencode/`

## 🐛 Troubleshooting

### Jobs Not Running

1. **Check scheduler is active**:
   ```
   Show my scheduled jobs
   ```

2. **Check system scheduler** (on host):
   - Linux: `systemctl --user list-timers`
   - macOS: `launchctl list | grep opencode`
   - Cron: `crontab -l`

3. **View job logs**:
   ```
   Show logs for {job-name}
   ```

### Jobs Lost After Restart

This means you're using ephemeral storage:

**Solution**: Mount persistent volumes (see Docker deployment above)

### Permission Errors

Jobs run as the `opencode` user. Ensure:
- Working directory is accessible
- Required tools are in PATH
- MCP servers are properly configured

## 🔄 Migrating from GitHub Actions

If you were using GitHub Actions for scheduling:

**Before** (GitHub Actions):
```yaml
on:
  schedule:
    - cron: '0 9 * * *'
jobs:
  run:
    steps:
      - run: npx opencode-ai "generate report"
```

**After** (OpenCode-Scheduler):
```
Schedule a daily job at 9am to generate report
```

**Benefits:**
- Runs locally (no GitHub dependency)
- Faster execution
- Access to local files
- Can use local MCP servers
- No public repository needed

## 📚 Additional Resources

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode-Scheduler Repository](https://github.com/different-ai/opencode-scheduler)
- [Cron Expression Guide](https://crontab.guru/)
- [OpenCode Plugins](https://opencode.ai/docs/plugins)

## 💡 Example Use Cases

### 1. Daily Standup Notes
```
Schedule a job every weekday at 9am to:
1. Review my calendar for today
2. Check my GitHub activity from yesterday
3. Generate standup notes in my Notes repository
4. Commit and push the notes
```

### 2. Weekly Backup
```
Schedule a job every Sunday at 3am to:
1. Export all my Notion pages
2. Commit to my backup repository
3. Verify backup integrity
4. Send success notification via email
```

### 3. System Monitoring
```
Schedule a job every hour to:
1. Check disk space on /home partition
2. If above 80%, alert me via Slack
3. Log the status
```

### 4. Social Media Monitoring
```
Schedule a job every 6 hours to:
1. Search Twitter for mentions of my project
2. Filter for questions or issues
3. Send me a summary of important mentions
```

## ⚙️ Advanced Configuration

### Custom Working Directory

Jobs run from the directory where they were created. To use a specific directory:

```bash
cd /path/to/your/project
opencode serve
# Then schedule jobs - they'll run from this directory
```

### Multiple Projects

Each project can have its own scheduled jobs:

```bash
# Project A
cd ~/projects/project-a
opencode serve --port 4096

# Project B (separate terminal)
cd ~/projects/project-b
opencode serve --port 4097
```

Jobs are scoped by working directory and won't conflict.

## 🎯 Summary

**For Render.com Free Tier Users:**
- ❌ Don't use opencode-scheduler (won't persist)
- ✅ Use GitHub Actions for scheduling

**For Dedicated Server/Local Users:**
- ✅ Use opencode-scheduler (perfect solution!)
- ✅ Persistent storage with Docker volumes
- ✅ Native OS scheduler reliability

---

**Questions?** Check the [OpenCode Discord](https://opencode.ai/discord) or [GitHub Issues](https://github.com/YajanaRao/opencode-server/issues).
