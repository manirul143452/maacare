# ============================================================
#  MaaCare — Complete AWS Deployment Guide
#  Domain: maacare.co | Backend: api.maacare.co
# ============================================================

## Step 1 — AWS Console Setup (10 minutes)

### A) Launch EC2 Instance
1. Go to: https://console.aws.amazon.com/ec2
2. Click **"Launch Instance"**
3. Settings:
   - **Name**: `maacare-backend`
   - **AMI**: Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance type**: `t2.micro` (Free tier — 1 vCPU, 1GB RAM)
   - **Key pair**: Create new → name it `maacare-key` → Download `.pem` file → SAVE IT SAFELY
   - **Security Group**: Allow inbound:
     - SSH: Port 22 (My IP)
     - HTTP: Port 80 (Anywhere)
     - HTTPS: Port 443 (Anywhere)
     - Custom TCP: Port 5000 (Anywhere) ← for testing only
4. **Storage**: 20 GB gp3 (free tier allows 30 GB)
5. Click **"Launch Instance"**

### B) Get Elastic IP (Fixed IP — Important!)
1. EC2 Dashboard → **Elastic IPs** → Allocate Elastic IP
2. **Associate** it to your `maacare-backend` instance
3. Note down this IP: `YOUR_ELASTIC_IP`

### C) Create S3 Bucket (for profile pictures)
1. Go to: https://console.aws.amazon.com/s3
2. Click **"Create bucket"**
3. Settings:
   - **Bucket name**: `maacare-uploads`
   - **Region**: `ap-south-1` (Mumbai)
   - **Block public access**: UNCHECK "Block all public access" → confirm
4. Click **"Create bucket"**
5. Go to bucket → **Permissions** → **Bucket Policy** → paste:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::maacare-uploads/*"
    }
  ]
}
```

### D) Create IAM User (for S3 access from server)
1. Go to: https://console.aws.amazon.com/iam
2. **Users** → **Create User**
3. Name: `maacare-server`
4. **Permissions**: Attach policy → search `AmazonS3FullAccess` → add
5. **Create Access Key** → Application running on AWS EC2
6. Save: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

---

## Step 2 — Domain DNS Setup (5 minutes)

In your domain registrar (where you bought maacare.co):
Add these DNS records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | `@` | `YOUR_ELASTIC_IP` | 300 |
| A | `api` | `YOUR_ELASTIC_IP` | 300 |
| CNAME | `www` | `maacare.co` | 300 |

Wait 5-15 minutes for DNS to propagate.

---

## Step 3 — Server Setup (15 minutes)

### Connect to EC2:
```bash
# Windows PowerShell:
ssh -i "maacare-key.pem" ubuntu@YOUR_ELASTIC_IP

# If permission error on Windows:
icacls "maacare-key.pem" /inheritance:r /grant:r "%USERNAME%:R"
```

### Run setup script on EC2:
```bash
# Upload setup script first
scp -i "maacare-key.pem" backend/setup-ec2.sh ubuntu@YOUR_ELASTIC_IP:~/

# SSH in and run it
ssh -i "maacare-key.pem" ubuntu@YOUR_ELASTIC_IP
bash ~/setup-ec2.sh
```

---

## Step 4 — Deploy Backend (5 minutes)

### Option A: From your Windows PC (using Git Bash or WSL):
```bash
bash backend/deploy.sh YOUR_ELASTIC_IP maacare-key.pem
```

### Option B: Manual upload via SCP:
```bash
scp -i "maacare-key.pem" -r backend/ ubuntu@YOUR_ELASTIC_IP:/home/ubuntu/maacare-backend/
ssh -i "maacare-key.pem" ubuntu@YOUR_ELASTIC_IP
cd /home/ubuntu/maacare-backend
npm install --production
pm2 start ecosystem.config.js --env production
pm2 save
```

---

## Step 5 — Configure Environment Variables

SSH into EC2 and edit .env:
```bash
nano /home/ubuntu/maacare-backend/.env
```

Fill in:
- `NVIDIA_API_KEY` = Your NVIDIA NIM key from https://build.nvidia.com
- `AWS_ACCESS_KEY_ID` = From Step 1D
- `AWS_SECRET_ACCESS_KEY` = From Step 1D

Restart after editing:
```bash
pm2 restart maacare-backend
```

---

## Step 6 — Get SSL Certificate (HTTPS)

```bash
sudo certbot --nginx -d api.maacare.co
```

Follow prompts → enter your email → agree to terms → done!
SSL auto-renews every 90 days automatically.

---

## Step 7 — Test Everything

```bash
# Health check
curl https://api.maacare.co/health

# Expected response:
# {"status":"ok","service":"maacare-backend","version":"2.0.0","storage":"aws-s3","timestamp":"..."}
```

---

## Step 8 — Build Flutter APK

After backend is live, build the APK:
```bash
# In your project folder:
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## Useful Commands (After Deployment)

```bash
# View live logs
pm2 logs maacare-backend

# Restart server
pm2 restart maacare-backend

# View server status
pm2 list

# Check Nginx
sudo nginx -t
sudo systemctl status nginx

# Check SSL certificate
sudo certbot certificates
```

---

## Monthly Cost Estimate

| Service | Free Tier | After Free Tier |
|---------|-----------|-----------------|
| EC2 t2.micro | FREE 1 year | ~$8/month |
| S3 (5GB) | FREE 1 year | ~$0.12/month |
| Data transfer | 15GB FREE | ~$0.09/GB |
| MongoDB Atlas M0 | FREE forever | FREE forever |
| NVIDIA NIM API | 1000 calls FREE/month | Pay per use |
| **Total** | **$0** | **~$10/month** |
