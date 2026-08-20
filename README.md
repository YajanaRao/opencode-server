# OpenCode Web Server

Deploy [OpenCode](https://opencode.ai) as a password-protected web interface with optional task automation.

## Features

- 🔒 Password-protected web interface
- 🌐 Access from anywhere via browser
- ⏰ Automated task scheduling (needs persistent storage + an always-on host — see [Troubleshooting](#troubleshooting))
- ☁️ Free deployment on Render.com (interactive use only — sleeps after 15min, no persistent disk)
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

## Security

Read this before putting the URL anywhere public.

OpenCode's **only** authentication is HTTP basic auth via `OPENCODE_SERVER_PASSWORD`. There is no bearer-token support, no rate limiting, no lockout, and no 2FA — requests for token auth were closed as not planned ([#24874](https://github.com/anomalyco/opencode/issues/24874), [#5256](https://github.com/anomalyco/opencode/issues/5256)). Behind that single password sits an agent with shell access, your `OPENCODE_API_KEY`, and your `GITHUB_TOKEN`.

Upstream's position is that server mode is opt-in and hardening it is the operator's job, so don't expect the framework to protect you.

**Recommended:** don't expose this to the internet at all. Put the host on a private network ([Tailscale](https://tailscale.com) or WireGuard) and reach it from your own devices. That removes the public attack surface entirely, which is worth more than any password.

If you do expose it publicly: use a long random password, serve it only over HTTPS (Render does this for you), and never enable `--mdns` on an untrusted network.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENCODE_SERVER_PASSWORD` | Access password | **Required** — the container refuses to start without it. Render generates one automatically via `render.yaml`. |
| `OPENCODE_SERVER_USERNAME` | Access username | `admin` (opencode's own default is `opencode`) |
| `PORT` | Server port | `10000` (Render) / `4096` (Docker) |
| `OPENCODE_API_KEY` | OpenCode Zen API key | - |

### LLM Provider Setup

**Option 1: Environment Variable (Recommended)**

Set your OpenCode Zen API key as an environment variable. Get your key at [opencode.ai/auth](https://opencode.ai/auth).

- **Render:** Set `OPENCODE_API_KEY` in Dashboard → Environment
- **Docker:** Set `OPENCODE_API_KEY` in your `.env` file or export it before running

**Option 2: Manual Configuration**

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

Scheduling needs two things this setup does not always provide:

- **Persistent storage.** Render's free tier has an ephemeral filesystem and no persistent disk (disks are paid-only), so job definitions are wiped on every spin-up and deploy.
- **An always-on process.** Free web services spin down after 15 minutes without inbound traffic. A scheduled job cannot wake a sleeping service, so it simply never fires.

There's also a container caveat: [opencode-scheduler](https://github.com/different-ai/opencode-scheduler) delegates to the OS scheduler (launchd/systemd), and there is no systemd in this image — it falls back to cron, which is less predictable.

OpenCode has no native scheduling and won't get it ([#11232](https://github.com/anomalyco/opencode/issues/11232), closed as not planned). For scheduling that actually persists, use a SQLite-backed plugin such as `opencode-cron` on a host with a real disk, or GitHub Actions.

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
