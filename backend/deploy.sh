#!/bin/bash
# ============================================================
#  MaaCare Deploy Script
#  Run this from your LOCAL machine to deploy to EC2
#  Usage: bash deploy.sh YOUR_EC2_IP YOUR_PEM_KEY.pem
# ============================================================

EC2_IP=${1:-"YOUR_EC2_IP_HERE"}
PEM_KEY=${2:-"maacare-key.pem"}
EC2_USER="ubuntu"
REMOTE_DIR="/home/ubuntu/maacare-backend"

echo "========================================"
echo "  Deploying MaaCare Backend to EC2"
echo "  Server: $EC2_IP"
echo "========================================"

# ── Check PEM key exists ────────────────────────────────────
if [ ! -f "$PEM_KEY" ]; then
  echo "❌ PEM key '$PEM_KEY' not found!"
  echo "   Usage: bash deploy.sh EC2_IP your-key.pem"
  exit 1
fi

chmod 400 "$PEM_KEY"

# ── Upload backend files ────────────────────────────────────
echo "[1/4] Uploading backend files..."
rsync -avz --progress \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude 'uploads' \
  --exclude '*.log' \
  -e "ssh -i $PEM_KEY -o StrictHostKeyChecking=no" \
  ./backend/ \
  $EC2_USER@$EC2_IP:$REMOTE_DIR/

echo "[1/4] Upload complete ✅"

# ── Install dependencies & restart ─────────────────────────
echo "[2/4] Installing dependencies on EC2..."
ssh -i "$PEM_KEY" -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP << 'REMOTE_COMMANDS'
  cd /home/ubuntu/maacare-backend
  npm install --production
  echo "Dependencies installed ✅"
REMOTE_COMMANDS

# ── Restart PM2 ─────────────────────────────────────────────
echo "[3/4] Restarting server with PM2..."
ssh -i "$PEM_KEY" -o StrictHostKeyChecking=no $EC2_USER@$EC2_IP << 'REMOTE_COMMANDS'
  cd /home/ubuntu/maacare-backend
  if pm2 list | grep -q "maacare-backend"; then
    pm2 restart maacare-backend
    echo "PM2 restarted ✅"
  else
    pm2 start ecosystem.config.js --env production
    pm2 save
    echo "PM2 started fresh ✅"
  fi
  pm2 list
REMOTE_COMMANDS

# ── Health check ────────────────────────────────────────────
echo "[4/4] Running health check..."
sleep 3
HEALTH=$(curl -s "https://api.maacare.co/health" 2>/dev/null || curl -s "http://$EC2_IP:5000/health" 2>/dev/null)
if echo "$HEALTH" | grep -q '"status":"ok"'; then
  echo ""
  echo "✅ Deployment successful!"
  echo "   Backend: https://api.maacare.co"
  echo "   Health:  $HEALTH"
else
  echo "⚠️  Health check returned: $HEALTH"
  echo "   Check logs: ssh -i $PEM_KEY $EC2_USER@$EC2_IP 'pm2 logs maacare-backend --lines 50'"
fi

echo ""
echo "========================================"
echo "  Deploy Complete 🚀"
echo "========================================"
