#!/bin/bash
# ============================================================
#  MaaCare EC2 Setup Script
#  Run this ONCE on a fresh Ubuntu 22.04 EC2 instance
#  Usage: bash setup-ec2.sh
# ============================================================

set -e  # Exit on any error

echo "========================================"
echo "  MaaCare Backend — EC2 Setup Script"
echo "  Domain: api.maacare.co"
echo "========================================"

# ── 1. Update system ─────────────────────────────────────────
echo "[1/10] Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# ── 2. Install Node.js 20 LTS ────────────────────────────────
echo "[2/10] Installing Node.js 20 LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version

# ── 3. Install PM2 globally ──────────────────────────────────
echo "[3/10] Installing PM2..."
sudo npm install -g pm2
pm2 --version

# ── 4. Install Nginx ─────────────────────────────────────────
echo "[4/10] Installing Nginx..."
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# ── 5. Install Certbot (Let's Encrypt SSL) ───────────────────
echo "[5/10] Installing Certbot for SSL..."
sudo apt-get install -y certbot python3-certbot-nginx

# ── 6. Create app directory ──────────────────────────────────
echo "[6/10] Creating app directory..."
sudo mkdir -p /home/ubuntu/maacare-backend
sudo mkdir -p /home/ubuntu/logs
sudo chown -R ubuntu:ubuntu /home/ubuntu/maacare-backend
sudo chown -R ubuntu:ubuntu /home/ubuntu/logs

# ── 7. Configure Nginx for api.maacare.co ───────────────────
echo "[7/10] Configuring Nginx..."
sudo tee /etc/nginx/sites-available/maacare << 'NGINX_EOF'
server {
    listen 80;
    server_name api.maacare.co;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # File upload limit (for profile pictures, documents)
    client_max_body_size 20M;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
    }

    # Health check (bypass proxy for AWS ALB health checks)
    location /health {
        proxy_pass http://localhost:5000/health;
        access_log off;
    }
}
NGINX_EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/maacare /etc/nginx/sites-enabled/maacare
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo "[7/10] Nginx configured ✅"

# ── 8. Configure AWS CLI (optional) ─────────────────────────
echo "[8/10] Installing AWS CLI..."
sudo apt-get install -y awscli

# ── 9. Set up firewall ───────────────────────────────────────
echo "[9/10] Configuring UFW firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# ── 10. PM2 startup ─────────────────────────────────────────
echo "[10/10] Configuring PM2 to start on boot..."
pm2 startup systemd -u ubuntu --hp /home/ubuntu
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu

echo ""
echo "========================================"
echo "  Setup Complete! Next steps:"
echo "========================================"
echo ""
echo "1. Upload your backend files:"
echo "   scp -r ./backend ubuntu@YOUR_EC2_IP:/home/ubuntu/maacare-backend"
echo ""
echo "2. SSH into EC2 and run:"
echo "   cd /home/ubuntu/maacare-backend"
echo "   npm install"
echo "   pm2 start ecosystem.config.js --env production"
echo "   pm2 save"
echo ""
echo "3. Get SSL certificate:"
echo "   sudo certbot --nginx -d api.maacare.co"
echo ""
echo "4. Update Flutter constants.dart:"
echo "   insForgeUrl = 'https://api.maacare.co'"
echo ""
echo "Done! Your backend will be live at https://api.maacare.co 🚀"
