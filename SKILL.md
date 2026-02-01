---
name: openclaw-cloudflare-deploy
description: "Deploy OpenClaw (Moltbot) to Cloudflare Workers with minimal input. One-command setup for a serverless personal AI assistant."
version: "1.0.0"
author: "Harish Narayanappa"
repository: "https://github.com/hanaraya/openclaw-cloudflare-deploy-skill"
tags: ["cloudflare", "deployment", "serverless", "ai-assistant", "moltbot", "openclaw"]
---

# OpenClaw Cloudflare Deploy Skill

Deploy OpenClaw (formerly Moltbot/Clawdbot) to Cloudflare Workers in minutes. Serverless, always-on personal AI assistant — no hardware required.

## What You Get

- 🦞 **OpenClaw** running on Cloudflare's edge network
- 🔒 **Secure sandbox** with Cloudflare Access authentication
- 💬 **Multi-channel support** (Web UI, Telegram, Discord, Slack)
- 💾 **Optional persistence** via R2 storage
- 🌍 **Global availability** on Cloudflare's network

## Prerequisites

| Requirement | Cost | Notes |
|-------------|------|-------|
| Cloudflare Workers Paid | $5/month | Required for Sandbox containers |
| Anthropic API Key | Pay-per-use | Or use Cloudflare AI Gateway |
| Node.js 18+ | Free | For wrangler CLI |
| Cloudflare Account | Free | [Sign up](https://dash.cloudflare.com/sign-up) |

## Quick Deploy (Minimal Input)

### What You Need Ready

Before running the deploy script, have these ready:
1. **Anthropic API Key** — from [console.anthropic.com](https://console.anthropic.com)
2. **Cloudflare Account** — logged in via `wrangler login`

### One-Command Deploy

```bash
# Run the deploy script
./skills/moltworker-deploy/scripts/deploy.sh
```

The script will:
1. Check prerequisites
2. Clone moltworker repo
3. Prompt for your Anthropic API key
4. Auto-generate gateway token
5. Deploy to Cloudflare Workers
6. Output your access URL and token

## Manual Deploy Steps

If you prefer manual control:

### 1. Install Wrangler CLI

```bash
npm install -g wrangler
wrangler login
```

### 2. Clone & Setup

```bash
git clone https://github.com/cloudflare/moltworker.git
cd moltworker
npm install
```

### 3. Set Secrets (Minimal Required)

> **⚠️ Auth Recommendation:** For Claude Code CLI integration, use a **setup-token** (long-lived, 1 year) instead of OAuth. OAuth requires constant refresh and can become unresponsive until manually fixed. Setup tokens are more reliable for always-on deployments.

```bash
# Anthropic API Key (required)
npx wrangler secret put ANTHROPIC_API_KEY
# Paste your key when prompted

# Gateway Token (required - auto-generate)
export MOLTBOT_GATEWAY_TOKEN=$(openssl rand -hex 32)
echo "Save this token: $MOLTBOT_GATEWAY_TOKEN"
echo "$MOLTBOT_GATEWAY_TOKEN" | npx wrangler secret put MOLTBOT_GATEWAY_TOKEN
```

### 4. Deploy

```bash
npm run deploy
```

### 5. Access Your Instance

```
https://moltbot-sandbox.<your-subdomain>.workers.dev/?token=YOUR_TOKEN
```

## Optional: Add Telegram Bot

To connect a Telegram bot:

```bash
# Get bot token from @BotFather on Telegram
npx wrangler secret put TELEGRAM_BOT_TOKEN

# Redeploy
npm run deploy
```

Then configure webhook in Telegram or use polling.

## Optional: Enable Persistence (R2)

Without R2, data resets on container restart. To enable persistence:

### 1. Create R2 Bucket

```bash
npx wrangler r2 bucket create moltbot-data
```

### 2. Create R2 API Token

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/) → R2 → Manage R2 API Tokens
2. Create token with "Object Read & Write" for `moltbot-data` bucket
3. Copy Access Key ID and Secret

### 3. Set R2 Secrets

```bash
npx wrangler secret put R2_ACCESS_KEY_ID
npx wrangler secret put R2_SECRET_ACCESS_KEY
npx wrangler secret put CF_ACCOUNT_ID
# Find Account ID in Cloudflare Dashboard URL or Workers overview
```

### 4. Redeploy

```bash
npm run deploy
```

## Optional: Cloudflare AI Gateway

Use AI Gateway instead of direct Anthropic for:
- Unified billing through Cloudflare
- Request analytics & caching
- Fallback providers

```bash
# Instead of ANTHROPIC_API_KEY, set:
npx wrangler secret put AI_GATEWAY_API_KEY
npx wrangler secret put AI_GATEWAY_BASE_URL
# URL format: https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_name}/anthropic
```

## Security: Cloudflare Access Setup

Protect your admin UI with Cloudflare Access:

### 1. Enable Access on Worker

1. Go to [Workers Dashboard](https://dash.cloudflare.com/?to=/:account/workers-and-pages)
2. Select your worker (`moltbot-sandbox`)
3. Settings → Domains & Routes → workers.dev row → (...) → Enable Cloudflare Access
4. Configure allowed emails/identity providers
5. Copy the Application Audience (AUD) tag

### 2. Set Access Secrets

```bash
npx wrangler secret put CF_ACCESS_TEAM_DOMAIN
# Enter: yourteam.cloudflareaccess.com

npx wrangler secret put CF_ACCESS_AUD
# Paste the AUD tag from step 1
```

### 3. Redeploy

```bash
npm run deploy
```

## Device Pairing

After deployment:

1. Open `https://your-worker.workers.dev/?token=YOUR_TOKEN`
2. First connection is held pending
3. Go to `/_admin/` to approve the device
4. Device is now paired and can connect freely

## Troubleshooting

### Container Takes Long to Start
First request may take 1-2 minutes for container cold start. Subsequent requests are fast.

### "Unauthorized" Error
- Verify gateway token is correct
- Check Cloudflare Access is configured
- Ensure device is paired via `/_admin/`

### Data Lost on Restart
Enable R2 persistence (see above).

### Telegram Bot Not Working
- Verify bot token is correct
- Check webhook URL: `https://your-worker.workers.dev/telegram/webhook`
- Or use polling mode in config

## Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| Workers Paid | $5 |
| Anthropic API | ~$5-50 (usage varies) |
| R2 Storage | Free tier (10GB) |
| AI Gateway | Free |
| **Total** | **~$10-55/month** |

## Updating

```bash
cd moltworker
git pull
npm install
npm run deploy
```

## Uninstalling

```bash
npx wrangler delete moltbot-sandbox
npx wrangler r2 bucket delete moltbot-data  # if using R2
```

## Authentication Best Practices

| Method | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **Setup Token** | Long-lived (1 year), no refresh needed, reliable | Manual setup | ✅ **Recommended** |
| **OAuth** | Easy initial setup | Requires constant refresh, can become unresponsive | ⚠️ Avoid for always-on |
| **API Key** | Simple, no expiry | Direct Anthropic billing | Good alternative |

For Claude Code CLI integration, **always use setup-token** over OAuth. OAuth tokens expire and require refresh cycles that can leave your deployment unresponsive until manually fixed.

## Links

- [Moltworker GitHub](https://github.com/cloudflare/moltworker)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Cloudflare Workers](https://workers.cloudflare.com/)
- [Cloudflare Sandbox Docs](https://developers.cloudflare.com/sandbox/)

---

*Skill created by Harish Narayanappa. Contributions welcome!*
