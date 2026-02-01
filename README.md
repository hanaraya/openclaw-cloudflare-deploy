# 🦞 OpenClaw Cloudflare Deploy Skill

**Deploy OpenClaw to Cloudflare Workers in under 5 minutes.**

One-command deployment of a serverless personal AI assistant on Cloudflare's global edge network.

## Features

- ⚡ **One-command deploy** — minimal input required
- 🔒 **Secure by default** — Cloudflare Sandbox isolation
- 🌍 **Global edge network** — low latency everywhere
- 💬 **Multi-channel** — Web UI, Telegram, Discord, Slack
- 💾 **Optional persistence** — R2 storage for data

## Quick Start

```bash
# Just run:
./scripts/deploy.sh

# With Telegram bot:
./scripts/deploy.sh --with-telegram

# With R2 persistence:
./scripts/deploy.sh --with-telegram --with-r2
```

## Requirements

| Requirement | Cost |
|-------------|------|
| Cloudflare Workers Paid | $5/month |
| Anthropic API Key | Pay-per-use |
| Node.js 18+ | Free |

## What You Need

1. **Anthropic API Key** — [console.anthropic.com](https://console.anthropic.com)
2. **Cloudflare Account** — [Sign up free](https://dash.cloudflare.com/sign-up)

That's it! The script handles everything else.

## Output

After deployment you get:
- Control UI URL with your gateway token
- Admin panel for device pairing
- WebSocket endpoint for integrations

## Cost Estimate

~$10-55/month depending on API usage.

## Links

- [Moltworker Repo](https://github.com/cloudflare/moltworker)
- [OpenClaw Docs](https://docs.openclaw.ai)
- [Cloudflare Workers](https://workers.cloudflare.com)

## Author

Created by Harish Narayanappa

## License

MIT
