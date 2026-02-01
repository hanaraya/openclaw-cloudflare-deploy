#!/bin/bash
# OpenClaw Cloudflare Deploy Script
# Deploys OpenClaw to Cloudflare Workers with minimal input
#
# Usage: ./deploy.sh [--with-telegram] [--with-r2]
#
# Options:
#   --with-telegram  Also configure Telegram bot
#   --with-r2        Also configure R2 persistence
#   --skip-clone     Skip cloning (use existing moltworker dir)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse args
WITH_TELEGRAM=false
WITH_R2=false
SKIP_CLONE=false
for arg in "$@"; do
    case $arg in
        --with-telegram) WITH_TELEGRAM=true ;;
        --with-r2) WITH_R2=true ;;
        --skip-clone) SKIP_CLONE=true ;;
    esac
done

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🦞 OpenClaw Cloudflare Deploy - OpenClaw on Cloudflare       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js not found. Install from https://nodejs.org/${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Node.js $(node --version)"

if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ npm not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} npm $(npm --version)"

if ! command -v npx &> /dev/null; then
    echo -e "${RED}✗ npx not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} npx available"

# Check wrangler
if ! npx wrangler --version &> /dev/null; then
    echo -e "${YELLOW}Installing wrangler CLI...${NC}"
    npm install -g wrangler
fi
echo -e "${GREEN}✓${NC} Wrangler $(npx wrangler --version 2>/dev/null | head -1)"

# Check wrangler login
echo ""
echo -e "${YELLOW}Checking Cloudflare authentication...${NC}"
if ! npx wrangler whoami &> /dev/null; then
    echo -e "${YELLOW}Please login to Cloudflare:${NC}"
    npx wrangler login
fi
ACCOUNT_INFO=$(npx wrangler whoami 2>/dev/null | grep -E "Account ID|email" | head -2)
echo -e "${GREEN}✓${NC} Logged in"
echo "$ACCOUNT_INFO"

# Clone repo
DEPLOY_DIR="${MOLTWORKER_DIR:-$HOME/moltworker}"
echo ""
if [ "$SKIP_CLONE" = false ]; then
    if [ -d "$DEPLOY_DIR" ]; then
        echo -e "${YELLOW}Directory $DEPLOY_DIR exists. Updating...${NC}"
        cd "$DEPLOY_DIR"
        git pull
    else
        echo -e "${YELLOW}Cloning moltworker...${NC}"
        git clone https://github.com/cloudflare/moltworker.git "$DEPLOY_DIR"
        cd "$DEPLOY_DIR"
    fi
else
    cd "$DEPLOY_DIR"
fi
echo -e "${GREEN}✓${NC} Moltworker repo ready at $DEPLOY_DIR"

# Install dependencies
echo ""
echo -e "${YELLOW}Installing dependencies...${NC}"
npm install
echo -e "${GREEN}✓${NC} Dependencies installed"

# Collect secrets
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    Configuration                              ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Anthropic API Key
echo -e "${YELLOW}Enter your Anthropic API Key:${NC}"
echo -e "(Get one at https://console.anthropic.com/)"
read -s -p "> " ANTHROPIC_KEY
echo ""
if [ -z "$ANTHROPIC_KEY" ]; then
    echo -e "${RED}✗ API key required${NC}"
    exit 1
fi
echo "$ANTHROPIC_KEY" | npx wrangler secret put ANTHROPIC_API_KEY
echo -e "${GREEN}✓${NC} Anthropic API key set"

# Generate gateway token
echo ""
GATEWAY_TOKEN=$(openssl rand -hex 32)
echo "$GATEWAY_TOKEN" | npx wrangler secret put MOLTBOT_GATEWAY_TOKEN
echo -e "${GREEN}✓${NC} Gateway token generated"

# Optional: Telegram
if [ "$WITH_TELEGRAM" = true ]; then
    echo ""
    echo -e "${YELLOW}Enter your Telegram Bot Token:${NC}"
    echo -e "(Get one from @BotFather on Telegram)"
    read -s -p "> " TELEGRAM_TOKEN
    echo ""
    if [ -n "$TELEGRAM_TOKEN" ]; then
        echo "$TELEGRAM_TOKEN" | npx wrangler secret put TELEGRAM_BOT_TOKEN
        echo -e "${GREEN}✓${NC} Telegram bot token set"
    fi
fi

# Optional: R2 persistence
if [ "$WITH_R2" = true ]; then
    echo ""
    echo -e "${YELLOW}Setting up R2 persistence...${NC}"
    
    # Create bucket if doesn't exist
    npx wrangler r2 bucket create moltbot-data 2>/dev/null || true
    echo -e "${GREEN}✓${NC} R2 bucket ready"
    
    echo ""
    echo -e "${YELLOW}Enter R2 Access Key ID:${NC}"
    echo -e "(Create at Cloudflare Dashboard → R2 → Manage R2 API Tokens)"
    read -p "> " R2_KEY_ID
    if [ -n "$R2_KEY_ID" ]; then
        echo "$R2_KEY_ID" | npx wrangler secret put R2_ACCESS_KEY_ID
    fi
    
    echo -e "${YELLOW}Enter R2 Secret Access Key:${NC}"
    read -s -p "> " R2_SECRET
    echo ""
    if [ -n "$R2_SECRET" ]; then
        echo "$R2_SECRET" | npx wrangler secret put R2_SECRET_ACCESS_KEY
    fi
    
    echo -e "${YELLOW}Enter your Cloudflare Account ID:${NC}"
    echo -e "(Found in Workers Dashboard URL or overview page)"
    read -p "> " CF_ACCOUNT
    if [ -n "$CF_ACCOUNT" ]; then
        echo "$CF_ACCOUNT" | npx wrangler secret put CF_ACCOUNT_ID
    fi
    
    echo -e "${GREEN}✓${NC} R2 persistence configured"
fi

# Deploy
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      Deploying...                             ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

npm run deploy

# Get worker URL
WORKER_URL=$(npx wrangler whoami 2>/dev/null | grep -oE '[a-z0-9-]+\.workers\.dev' | head -1 || echo "moltbot-sandbox.<your-subdomain>.workers.dev")

# Success!
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    🎉 Deployment Complete!                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Your OpenClaw instance is ready!${NC}"
echo ""
echo -e "🔗 ${BLUE}Control UI:${NC}"
echo -e "   https://${WORKER_URL}/?token=${GATEWAY_TOKEN}"
echo ""
echo -e "🔑 ${BLUE}Gateway Token (save this!):${NC}"
echo -e "   ${GATEWAY_TOKEN}"
echo ""
echo -e "👤 ${BLUE}Admin UI:${NC}"
echo -e "   https://${WORKER_URL}/_admin/"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Open the Control UI link above"
echo "2. First load may take 1-2 min (container cold start)"
echo "3. Visit /_admin/ to pair your device"
echo "4. (Optional) Set up Cloudflare Access for security"
echo ""
echo -e "${BLUE}Docs: https://github.com/cloudflare/moltworker${NC}"

# Save config for reference
CONFIG_FILE="$HOME/.moltworker-config"
cat > "$CONFIG_FILE" << EOF
# OpenClaw Cloudflare Deployment Config
# Generated: $(date)

WORKER_URL=https://${WORKER_URL}
GATEWAY_TOKEN=${GATEWAY_TOKEN}
DEPLOY_DIR=${DEPLOY_DIR}
EOF
echo ""
echo -e "Config saved to: $CONFIG_FILE"
