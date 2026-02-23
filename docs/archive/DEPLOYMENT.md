# 🚀 Quick Deployment Guide

Follow these steps to deploy your OpenCode server to Render.

## Step 1: Create GitHub Repository (2 minutes)

### Option A: Via GitHub CLI (if installed)

```bash
cd ~/Developer/opencode-server

# Create private repository
gh repo create opencode-server --private --source=. --remote=origin --push
```

### Option B: Via GitHub Web Interface

1. Go to https://github.com/new
2. Repository name: `opencode-server`
3. Privacy: **Private** (recommended)
4. Don't initialize with README (we already have one)
5. Click **"Create repository"**
6. Run these commands:

```bash
cd ~/Developer/opencode-server

# Add remote
git remote add origin https://github.com/YajanaRao/opencode-server.git

# Push to GitHub
git push -u origin main
```

---

## Step 2: Deploy to Render (5 minutes)

### 1. Sign in to Render

- Go to https://dashboard.render.com
- Sign in (or create account if needed)

### 2. Create New Web Service

1. Click **"New"** button (top right)
2. Select **"Web Service"**

### 3. Connect GitHub

1. Click **"Connect GitHub"** (if first time)
2. Authorize Render to access your GitHub
3. Select **"Only select repositories"**
4. Choose **`opencode-server`**
5. Click **"Install"**

### 4. Configure Service

1. Select **`opencode-server`** from the list
2. Render will detect `render.yaml` automatically
3. You'll see: **"Blueprint Detected"**
4. Click **"Apply"** to use the configuration

### 5. Review Settings

The following will be configured automatically from `render.yaml`:

```
Name: opencode-web
Environment: Docker
Region: Singapore
Plan: Free
Branch: main
Auto-Deploy: Yes

Environment Variables:
- OPENCODE_SERVER_PASSWORD: [Auto-generated]
- OPENCODE_SERVER_USERNAME: admin
- NODE_ENV: production
```

### 6. Create Web Service

1. Review all settings
2. Click **"Create Web Service"** button
3. Render will start building and deploying

### 7. Wait for Deployment

- Build time: ~2-3 minutes
- Deploy time: ~1 minute
- Total: ~3-4 minutes
- Watch the logs in real-time

---

## Step 3: Get Your Password (1 minute)

After deployment shows **"Live"**:

1. In Render Dashboard, click on **`opencode-web`** service
2. Click **"Environment"** tab (left sidebar)
3. Find `OPENCODE_SERVER_PASSWORD`
4. Click **"Show"** to reveal the password
5. **Copy and save this password securely!**

Example password format: `abc123def456ghi789jkl`

---

## Step 4: Access Your OpenCode Server (1 minute)

Your OpenCode instance is now live at:

```
URL: https://opencode-web-[random].onrender.com
```

Find your exact URL:

- Render Dashboard > opencode-web service > **URL shown at top**

### First Access:

1. Copy the URL
2. Open in your browser
3. You'll see a login screen

```
Username: admin
Password: [paste from Step 3]
```

4. Click **"Sign In"**
5. You should see the OpenCode web interface!

**Note:** First access may take 50 seconds (cold start on free tier).

---

## Step 5: Configure LLM Provider (3 minutes)

Before you can use OpenCode, configure an LLM provider:

### Option A: OpenCode Zen (Recommended)

```
1. In OpenCode web interface, type: /connect
2. Select "opencode" from the list
3. Visit https://opencode.ai/auth in new tab
4. Sign in and add payment method
5. Copy your API key
6. Paste into OpenCode
7. Done! ✅
```

### Option B: OpenAI (ChatGPT)

```
1. Get API key from: https://platform.openai.com/api-keys
2. In Render Dashboard:
   - Go to opencode-web > Environment
   - Click "Add Environment Variable"
   - Key: OPENAI_API_KEY
   - Value: [paste your key]
   - Click "Save Changes"
3. Service will restart automatically
4. In OpenCode, type: /connect
5. Select "openai"
6. Done! ✅
```

### Option C: Anthropic (Claude)

```
1. Get API key from: https://console.anthropic.com/settings/keys
2. In Render Dashboard:
   - Go to opencode-web > Environment
   - Click "Add Environment Variable"
   - Key: ANTHROPIC_API_KEY
   - Value: [paste your key]
   - Click "Save Changes"
3. Service will restart automatically
4. In OpenCode, type: /connect
5. Select "anthropic"
6. Done! ✅
```

---

## Step 6: Test Your Setup (2 minutes)

### Create Your First Session

1. In OpenCode web interface
2. Click **"New Session"**
3. Type a test prompt:
   ```
   What is 2+2? Please explain.
   ```
4. Press Enter
5. You should get a response from your LLM!

### Verify Everything Works

- ✅ Web interface loads
- ✅ Authentication works
- ✅ Can create new session
- ✅ LLM responds to prompts
- ✅ No errors in logs

---

## 🎉 Success!

Your OpenCode server is now live and accessible from anywhere!

**Your URLs:**

- Web Interface: https://opencode-web-[random].onrender.com
- Health Check: https://opencode-web-[random].onrender.com/global/health

**Save these for later:**

- Username: `admin`
- Password: [from Render Environment]
- GitHub Repo: https://github.com/YajanaRao/opencode-server

---

## 📊 Monitor Your Service

### View Logs

```
Render Dashboard > opencode-web > Logs tab
```

### Check Metrics

```
Render Dashboard > opencode-web > Metrics tab
```

Shows:

- CPU usage
- Memory usage
- Request count
- Response times

### Health Check

```bash
curl https://opencode-web-[your-url].onrender.com/global/health
```

Expected response:

```json
{ "healthy": true, "version": "1.0.0" }
```

---

## 🔧 Common Issues

### Issue: "Service Unavailable" or 502 Error

**Solution:** Wait 50 seconds for cold start (free tier sleeps after 15min)

### Issue: "Authentication Failed"

**Solution:**

1. Verify username is `admin`
2. Get password from Render Dashboard > Environment
3. Clear browser cache/cookies
4. Try incognito/private window

### Issue: "Cannot connect to LLM"

**Solution:**

1. Verify you ran `/connect` command
2. Check API key is set correctly
3. Verify API key has credits/quota
4. Check Render logs for errors

### Issue: Build fails

**Solution:**

1. Check Render logs for error details
2. Verify render.yaml syntax
3. Verify Dockerfile syntax
4. Try rebuilding: Render Dashboard > Manual Deploy > Deploy latest commit

---

## 🔄 Updating Your Server

When you make changes:

```bash
cd ~/Developer/opencode-server

# Make your changes
vim Dockerfile  # or any file

# Commit changes
git add .
git commit -m "Update configuration"

# Push to GitHub
git push

# Render auto-deploys! (takes ~3 minutes)
```

Watch deployment progress in Render Dashboard > Logs.

---

## 📞 Need Help?

- OpenCode Discord: https://opencode.ai/discord
- Render Community: https://community.render.com
- Check README.md for troubleshooting guide
- Review Render logs for error details

---

## ⏭️ What's Next?

After your server is working:

1. **Phase 2:** Add GitHub integration for repo access
2. **Phase 3:** Set up Notes repository for saving notes
3. **Phase 4:** Add keep-alive to prevent sleep
4. **Phase 5:** Configure custom domain (optional)

See README.md "Future Enhancements" section for details.

---

**Total Deployment Time:** ~15 minutes  
**Cost:** $0/month (Render free tier)  
**Access:** Anywhere with internet connection

Enjoy your OpenCode server! 🚀
