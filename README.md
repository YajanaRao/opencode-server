# OpenCode Web Server

Deploy [OpenCode](https://opencode.ai) as a password-protected web interface with optional task automation.

## Features

- 🔒 Password-protected web interface
- 🌐 Access from anywhere via browser
- ⏰ Automated task scheduling (self-hosted only)
- ☁️ Free deployment on Render.com
- 🐳 Or self-host with Docker

## Quick Start

### Option 1: Self-Hosted (with scheduler)

```bash
git clone https://github.com/YajanaRao/opencode-server.git
cd opencode-server
export OPENCODE_SERVER_PASSWORD="your-password"
docker-compose up -d
```

Access at `http://localhost:4096` (username: `admin`)

**Schedule tasks with natural language:**
```
Schedule a daily job at 9am to check my GitHub notifications
```

### Option 2: Render.com (free hosting)

1. Fork this repository
2. Go to [Render Dashboard](https://dashboard.render.com) → New → Web Service
3. Connect your fork
4. Render auto-detects `render.yaml`
5. Click "Apply" to deploy

**Get your password:** Render Dashboard → Environment → `OPENCODE_SERVER_PASSWORD` → Show

Access at `https://opencode-web-xxxx.onrender.com` (username: `admin`)

**Note:** Scheduler doesn't persist on Render free tier (ephemeral storage). Use GitHub Actions for scheduled tasks instead.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCODE_SERVER_PASSWORD` | Access password | Auto-generated |
| `OPENCODE_SERVER_USERNAME` | Access username | `admin` |
| `PORT` | Server port | `10000` (Render) / `4096` (Docker) |

### LLM Provider Setup

After deployment, run `/connect` command and choose:
- OpenCode Zen (recommended for beginners)
- OpenAI (ChatGPT)
- Anthropic (Claude)

## Troubleshooting

**Can't access server?**
- Docker: Check `docker-compose ps` and `docker-compose logs -f`
- Render: Wait 50 seconds (cold start), check service status

**Can't log in?**
- Verify password in Render Dashboard → Environment
- Try incognito/private browsing mode

**Scheduler not working?**
- Only works with persistent storage (self-hosted)
- Render free tier has ephemeral storage
- Alternative: Use GitHub Actions

## What's Inside

- `Dockerfile` - Container setup with OpenCode + scheduler plugin
- `docker-compose.yml` - Self-hosted deployment
- `render.yaml` - Render.com deployment config
- `opencode.json` - Plugin configuration

## Resources

- [OpenCode Documentation](https://opencode.ai/docs)
- [opencode-scheduler Plugin](https://github.com/different-ai/opencode-scheduler)
- [GitHub Issues](https://github.com/YajanaRao/opencode-server/issues)

## License

This deployment configuration is provided as-is for personal use. OpenCode is developed by [Anomaly](https://anoma.ly).
