# Quick Start Guide

Choose your deployment method:

## 🚀 Option 1: Self-Hosted with Scheduler (Recommended for Automation)

Perfect for dedicated servers or local development with automated task scheduling.

```bash
# 1. Clone the repository
git clone https://github.com/YajanaRao/opencode-server.git
cd opencode-server

# 2. Set your password
export OPENCODE_SERVER_PASSWORD="your-secure-password"

# 3. Start the server
docker-compose up -d

# 4. Access OpenCode
# URL: http://localhost:4096
# Username: admin
# Password: (what you set in step 2)
```

### Schedule Your First Task

Once logged in, just say:
```
Schedule a daily job at 9am to check my GitHub notifications
```

That's it! The plugin handles everything.

### Manage Your Scheduled Jobs

```
Show my scheduled jobs
Show logs for github-notifications
Update github-notifications to run at 10am
Delete the github-notifications job
```

**See [SCHEDULER_SETUP_GUIDE.md](./SCHEDULER_SETUP_GUIDE.md) for more details.**

---

## ☁️ Option 2: Render.com (No Scheduler)

Best for simple web-based coding assistance without automated tasks.

⚠️ **Note**: Scheduler plugin will be installed but won't persist due to ephemeral storage.

### Quick Deploy

1. Fork this repository on GitHub
2. Go to [Render Dashboard](https://dashboard.render.com)
3. Click "New" → "Web Service"
4. Connect your GitHub repository
5. Render detects `render.yaml` automatically
6. Click "Apply" and deploy

### Get Your Password

After deployment:
1. Go to Render Dashboard
2. Click your service
3. Go to "Environment" tab
4. Find `OPENCODE_SERVER_PASSWORD`
5. Click "Show" to reveal

### Access OpenCode

```
URL: https://opencode-web-xxxx.onrender.com
Username: admin
Password: (from Render Dashboard)
```

### For Scheduled Tasks on Render

Use GitHub Actions instead. See [SCHEDULER_SETUP_GUIDE.md](./SCHEDULER_SETUP_GUIDE.md) for migration guide.

---

## 📚 Additional Resources

- [SCHEDULER_SETUP_GUIDE.md](./SCHEDULER_SETUP_GUIDE.md) - Complete scheduler documentation
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Detailed Render.com deployment guide
- [README.md](./README.md) - Full project documentation
- [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) - Technical implementation details

---

## 🆘 Quick Troubleshooting

### Docker: Can't access localhost:4096
```bash
# Check if container is running
docker-compose ps

# View logs
docker-compose logs -f

# Restart
docker-compose restart
```

### Render: Can't log in
1. Check password in Render Dashboard → Environment
2. Wait 50 seconds after first deploy (cold start)
3. Try incognito/private browsing mode

### Scheduled jobs not running
1. Make sure you're using self-hosted deployment (not Render free tier)
2. Check persistent volumes are mounted
3. View logs: `Show logs for {job-name}`
4. See [SCHEDULER_SETUP_GUIDE.md](./SCHEDULER_SETUP_GUIDE.md) troubleshooting section

---

**Questions?** Open an issue on [GitHub](https://github.com/YajanaRao/opencode-server/issues)
