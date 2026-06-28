const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
// MaaCare Backend v2.0 — AWS EC2 + MongoDB Atlas + NVIDIA NIM AI
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const dns = require('dns');
const crypto = require('crypto');

// ── DNS fix for IPv4 ────────────────────────────────────────────
if (dns.setDefaultResultOrder) dns.setDefaultResultOrder('ipv4first');
try { dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']); } catch (e) {}

dotenv.config();

// ── AWS S3 Setup ────────────────────────────────────────────────
let s3Client = null;
let multerS3 = null;
const USE_S3 = !!(
  process.env.AWS_ACCESS_KEY_ID && 
  !process.env.AWS_ACCESS_KEY_ID.startsWith('your_') &&
  process.env.AWS_SECRET_ACCESS_KEY && 
  !process.env.AWS_SECRET_ACCESS_KEY.startsWith('your_') &&
  process.env.S3_BUCKET_NAME &&
  !process.env.S3_BUCKET_NAME.startsWith('your_')
);

if (USE_S3) {
  try {
    const { S3Client } = require('@aws-sdk/client-s3');
    multerS3 = require('multer-s3');
    s3Client = new S3Client({
      region: process.env.AWS_REGION || 'ap-south-1',
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      },
    });
    console.log('✅ AWS S3 configured successfully');
  } catch (e) {
    console.warn('⚠️  AWS S3 packages not installed, falling back to local disk:', e.message);
  }
}

// ── Express App ─────────────────────────────────────────────────
const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/maacare';
const JWT_SECRET = process.env.JWT_SECRET;
const S3_BUCKET = process.env.S3_BUCKET_NAME;

if (!JWT_SECRET) {
  console.error('FATAL: JWT_SECRET environment variable is not set.');
  process.exit(1);
}

// ── CORS ─────────────────────────────────────────────────────────
const allowedOrigins = [
  'https://rainbow-granita-b4981d.netlify.app',
  'https://web-snowy-iota-93.vercel.app',
  'http://localhost:3000',
  'http://localhost:5000',
  'http://10.0.2.2:5000',
];
// Add EC2/custom domain from env
if (process.env.FRONTEND_URL) allowedOrigins.push(process.env.FRONTEND_URL);
if (process.env.BACKEND_URL) allowedOrigins.push(process.env.BACKEND_URL);

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) return callback(null, true);
    // Allow any origin in development
    if (process.env.NODE_ENV !== 'production') return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'apikey', 'Prefer'],
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Request Logging ──────────────────────────────────────────────
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// ── File Storage: S3 or Local Disk ──────────────────────────────
let storageEngine;
if (USE_S3 && s3Client && multerS3) {
  storageEngine = multerS3({
    s3: s3Client,
    bucket: S3_BUCKET,
    acl: 'public-read',
    contentType: multerS3.AUTO_CONTENT_TYPE,
    key: (req, file, cb) => {
      const bucket = req.params.bucket || 'general';
      const fileName = req.params.file || `${Date.now()}-${file.originalname}`;
      cb(null, `${bucket}/${fileName}`);
    },
  });
} else {
  // Local disk fallback
  storageEngine = multer.diskStorage({
    destination: (req, _file, cb) => {
      const bucket = req.params.bucket || 'default';
      const uploadPath = path.join(__dirname, 'uploads', bucket);
      fs.mkdirSync(uploadPath, { recursive: true });
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      cb(null, req.params.file || `${Date.now()}-${file.originalname}`);
    },
  });
}
const upload = multer({ storage: storageEngine });

// ── MongoDB Connection & WebSocket Setup ─────────────────────────
const WebSocket = require('ws');
const wsClients = new Set();

function setupWebSocket(server) {
  const wss = new WebSocket.Server({ noServer: true });

  server.on('upgrade', (request, socket, head) => {
    try {
      const { pathname } = new URL(request.url, `http://${request.headers.host}`);
      if (pathname.startsWith('/realtime/')) {
        wss.handleUpgrade(request, socket, head, (ws) => {
          wss.emit('connection', ws, request);
        });
      } else {
        socket.destroy();
      }
    } catch (e) {
      console.error('[WebSocket Upgrade Error]', e);
      socket.destroy();
    }
  });

  wss.on('connection', (ws) => {
    ws.subscribedTopics = new Set();
    wsClients.add(ws);
    console.log('[WebSocket] Client connected. Total clients:', wsClients.size);

    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);
        const { topic, event, ref } = data;

        if (event === 'phx_join') {
          ws.subscribedTopics.add(topic);
          console.log(`[WebSocket] Client joined topic: ${topic}`);
          ws.send(JSON.stringify({
            topic,
            event: 'phx_reply',
            payload: { status: 'ok', response: {} },
            ref
          }));
        } else if (event === 'phx_leave') {
          ws.subscribedTopics.delete(topic);
          console.log(`[WebSocket] Client left topic: ${topic}`);
          ws.send(JSON.stringify({
            topic,
            event: 'phx_reply',
            payload: { status: 'ok', response: {} },
            ref
          }));
        } else if (event === 'heartbeat') {
          ws.send(JSON.stringify({
            topic: 'phoenix',
            event: 'phx_reply',
            payload: { status: 'ok', response: {} },
            ref
          }));
        }
      } catch (err) {
        console.error('[WebSocket] Message parsing error:', err);
      }
    });

    ws.on('close', () => {
      wsClients.delete(ws);
      console.log('[WebSocket] Client disconnected. Total clients:', wsClients.size);
    });

    ws.on('error', (err) => {
      console.error('[WebSocket] Client error:', err);
      wsClients.delete(ws);
    });
  });
}

function broadcastDbChange(table, event, record, oldRecord = null) {
  wsClients.forEach((ws) => {
    if (ws.readyState !== WebSocket.OPEN) return;

    let matchedTopic = null;

    if (table === 'posts') {
      matchedTopic = 'realtime:posts:all';
    } else if (table === 'chats') {
      const convId = record.conversation_id || (oldRecord && oldRecord.conversation_id);
      if (convId) matchedTopic = `realtime:chats:${convId}`;
    } else if (table === 'appointments') {
      const docId = record.doctor_id || (oldRecord && oldRecord.doctor_id);
      if (docId) matchedTopic = `realtime:appointments:${docId}`;
    }

    if (matchedTopic && ws.subscribedTopics.has(matchedTopic)) {
      console.log(`[WebSocket] Broadcasting event ${event}_${table} to topic ${matchedTopic}`);
      ws.send(JSON.stringify({
        topic: matchedTopic,
        event: `${event}_${table}`,
        payload: {
          event: `${event}_${table}`,
          record: mapDoc(record),
          old_record: oldRecord ? mapDoc(oldRecord) : null
        },
        ref: null
      }));
    }
  });
}

let db;
console.log('Connecting to MongoDB...');
MongoClient.connect(MONGO_URI, { serverSelectionTimeoutMS: 5000 })
  .then(client => {
    console.log('✅ Connected to MongoDB successfully');
    db = client.db();
    ensureIndexes(db).catch(console.warn);
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 MaaCare Backend v2 running on port ${PORT}`);
      console.log(`   Storage: ${USE_S3 && s3Client ? 'AWS S3' : 'Local Disk'}`);
    });
    setupWebSocket(server);
  })
  .catch(err => {
    console.warn('⚠️  Failed to connect to MongoDB. Falling back to local JSON DB:', err.message);
    const { JsonDb } = require('./jsonDb');
    db = new JsonDb();
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 MaaCare Backend (JSON DB Fallback) running on port ${PORT}`);
    });
    setupWebSocket(server);
  });

async function ensureIndexes(database) {
  try {
    await database.collection('auth_users').createIndex({ email: 1 }, { unique: true });
    await database.collection('users').createIndex({ id: 1 });
    await database.collection('users').createIndex({ email: 1 });
    await database.collection('oauth_codes').createIndex({ code: 1 }, { unique: true });
    await database.collection('oauth_codes').createIndex({ created_at: 1 }, { expireAfterSeconds: 600 }); // TTL: 10 min
    await database.collection('appointments').createIndex({ user_id: 1 });
    await database.collection('appointments').createIndex({ doctor_id: 1 });
    await database.collection('chats').createIndex({ user_id: 1 });
    await database.collection('notifications').createIndex({ user_id: 1 });
    console.log('✅ MongoDB indexes ensured');
  } catch (e) {
    console.warn('Index creation warning:', e.message);
  }
}

// ────────────────────────────────────────────────────────────────
// HELPERS
// ────────────────────────────────────────────────────────────────

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Unauthorized: Token missing' });
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Forbidden: Invalid token' });
    if (!user || (!user.id && !user._id)) {
      return res.status(401).json({ error: 'Unauthorized: Invalid token payload' });
    }
    req.user = { ...user, id: user.id || user._id };
    next();
  });
};

function parsePostgrestQuery(queryParams) {
  const query = {};
  const options = {};
  for (const [key, value] of Object.entries(queryParams)) {
    if (key === 'order') {
      const [col, dir] = value.split('.');
      options.sort = { [col]: dir === 'desc' ? -1 : 1 };
    } else if (key === 'limit') {
      options.limit = parseInt(value, 10);
    } else if (key === 'offset') {
      options.skip = parseInt(value, 10);
    } else if (key === 'on_conflict') {
      // handled separately
    } else {
      if (typeof value === 'string' && value.startsWith('eq.')) {
        query[key] = value.substring(3);
      } else {
        query[key] = value;
      }
    }
  }
  return { query, options };
}

function mapDoc(doc) {
  if (doc && doc._id && !doc.id) return { ...doc, id: doc._id.toString() };
  return doc;
}

// ────────────────────────────────────────────────────────────────
// 0. HEALTH CHECK
// ────────────────────────────────────────────────────────────────

app.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'maacare-backend',
    version: '2.0.0',
    storage: USE_S3 && s3Client ? 'aws-s3' : 'local-disk',
    timestamp: new Date().toISOString(),
  });
});

// ────────────────────────────────────────────────────────────────
// 1. AUTHENTICATION ENDPOINTS
// ────────────────────────────────────────────────────────────────

// Register / Sign Up
app.post('/api/auth/users', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' });
    const authCollection = db.collection('auth_users');
    const existingUser = await authCollection.findOne({ email });
    if (existingUser) return res.status(400).json({ error: 'Email already registered' });
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = crypto.randomUUID();
    await authCollection.insertOne({ _id: userId, id: userId, email, password: hashedPassword, created_at: new Date() });
    await db.collection('users').insertOne({ _id: userId, id: userId, email, name: name || email.split('@')[0], points: 0, streak: 0, language: 'en', created_at: new Date() });
    const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '7d' });
    const refreshToken = jwt.sign({ id: userId, email, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
    res.status(201).json({ accessToken: token, refreshToken });
  } catch (err) {
    console.error('SignUp Error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// Login / Sign In
app.post('/api/auth/sessions', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' });
    const authCollection = db.collection('auth_users');
    const user = await authCollection.findOne({ email });
    if (!user) return res.status(400).json({ error: 'Invalid email or password' });
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) return res.status(400).json({ error: 'Invalid email or password' });
    const token = jwt.sign({ id: user.id || user._id, email }, JWT_SECRET, { expiresIn: '7d' });
    const refreshToken = jwt.sign({ id: user.id || user._id, email, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
    res.status(200).json({ accessToken: token, refreshToken });
  } catch (err) {
    console.error('SignIn Error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// Get Current User Session Info
app.get('/api/auth/sessions/current', authenticateToken, async (req, res) => {
  try {
    const profile = await db.collection('users').findOne({ $or: [{ id: req.user.id }, { _id: req.user.id }] });
    if (!profile) return res.status(404).json({ error: 'User profile not found' });
    res.status(200).json({ user: { id: profile.id || profile._id, email: profile.email, name: profile.name } });
  } catch (err) {
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// Google Token Verification
app.post('/api/auth/google/token', async (req, res) => {
  try {
    const { idToken, email, name, photoUrl, googleId } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });
    if (idToken) {
      try {
        const verifyRes = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
        const verifyData = await verifyRes.json();
        if (verifyData.error || verifyData.email !== email) {
          return res.status(401).json({ error: 'Invalid Google token' });
        }
      } catch (verifyErr) {
        console.error('Google token verification failed:', verifyErr.message);
        return res.status(503).json({ error: 'Could not verify Google token. Please try again.' });
      }
    }
    const authCollection = db.collection('auth_users');
    const usersCollection = db.collection('users');
    let user = await authCollection.findOne({ email });
    let userId;
    if (!user) {
      userId = crypto.randomUUID();
      await authCollection.insertOne({ _id: userId, id: userId, email, provider: 'google', google_id: googleId || null, name: name || email.split('@')[0], photo_url: photoUrl || null, created_at: new Date() });
      await usersCollection.insertOne({ _id: userId, id: userId, email, name: name || email.split('@')[0], avatar_url: photoUrl || null, points: 0, streak: 0, language: 'en', created_at: new Date() });
      console.log(`[Google Auth] New user created: ${email}`);
    } else {
      userId = user.id || user._id;
      if (photoUrl && !user.photo_url) {
        await authCollection.updateOne({ email }, { $set: { photo_url: photoUrl, updated_at: new Date() } });
      }
      console.log(`[Google Auth] Existing user signed in: ${email}`);
    }
    const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '30d' });
    const refreshToken = jwt.sign({ id: userId, email, type: 'refresh' }, JWT_SECRET, { expiresIn: '90d' });
    res.status(200).json({ accessToken: token, refreshToken, user: { id: userId, email, name: name || email.split('@')[0] } });
  } catch (err) {
    console.error('Google Token Auth Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// OAuth Initiation (PKCE)
app.get('/api/auth/oauth/:provider', (req, res) => {
  try {
    const { provider } = req.params;
    const { redirect_uri, code_challenge } = req.query;
    const params = new URLSearchParams({ provider, redirect_uri, code_challenge });
    const host = req.headers.host;
    const protocol = req.secure || req.headers['x-forwarded-proto'] === 'https' ? 'https' : 'http';
    const authUrl = `${protocol}://${host}/api/auth/oauth-mock/login?${params.toString()}`;
    res.status(200).json({ authUrl });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// OAuth Mock Login Page
app.get('/api/auth/oauth-mock/login', (req, res) => {
  const { provider, redirect_uri, code_challenge } = req.query;
  const providerName = (provider || 'google').charAt(0).toUpperCase() + (provider || 'google').slice(1);
  const color = provider === 'google' ? '#4285F4' : '#333';
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign in with ${providerName}</title>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    body { margin:0; font-family:'Plus Jakarta Sans',sans-serif; background:linear-gradient(135deg,#f5f7fa 0%,#c3cfe2 100%); display:flex; align-items:center; justify-content:center; height:100vh; }
    .card { background:rgba(255,255,255,0.9); backdrop-filter:blur(10px); border-radius:24px; padding:40px; width:100%; max-width:400px; box-shadow:0 20px 40px rgba(0,0,0,0.1); text-align:center; border:1px solid rgba(255,255,255,0.2); }
    .logo { font-size:32px; font-weight:700; background:linear-gradient(135deg,#FF6B6B 0%,#FF8E53 100%); -webkit-background-clip:text; -webkit-text-fill-color:transparent; margin-bottom:24px; }
    h2 { font-size:22px; margin-bottom:8px; color:#2D3748; }
    p { font-size:14px; color:#718096; margin-bottom:30px; }
    .form-group { margin-bottom:20px; text-align:left; }
    label { display:block; font-size:14px; font-weight:600; color:#4A5568; margin-bottom:8px; }
    input { width:100%; padding:14px 16px; border:1px solid #E2E8F0; border-radius:12px; font-size:16px; box-sizing:border-box; font-family:inherit; transition:all 0.2s; }
    input:focus { outline:none; border-color:${color}; box-shadow:0 0 0 3px rgba(66,133,244,0.15); }
    .btn { width:100%; padding:14px; background:${color}; color:white; border:none; border-radius:12px; font-size:16px; font-weight:600; cursor:pointer; transition:background 0.2s; margin-top:10px; }
    .btn:hover { opacity:0.9; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">MaaCare 💕</div>
    <h2>Sign in with ${providerName}</h2>
    <p>Secure OAuth Authentication</p>
    <form action="/api/auth/oauth-mock/callback" method="GET">
      <input type="hidden" name="redirect_uri" value="${redirect_uri || ''}">
      <input type="hidden" name="code_challenge" value="${code_challenge || ''}">
      <div class="form-group">
        <label>Full Name</label>
        <input type="text" name="name" placeholder="Your Name" required>
      </div>
      <div class="form-group">
        <label>Email Address</label>
        <input type="email" name="email" placeholder="user@gmail.com" required>
      </div>
      <button type="submit" class="btn">Continue to MaaCare</button>
    </form>
  </div>
</body>
</html>`;
  res.send(html);
});

// OAuth Mock Callback → deep link redirect
app.get('/api/auth/oauth-mock/callback', async (req, res) => {
  try {
    const { email, name, redirect_uri, code_challenge } = req.query;
    if (!email || !redirect_uri) return res.status(400).send('Missing email or redirect_uri');
    const code = crypto.randomUUID();
    // ✅ Store OAuth code in MongoDB (TTL index = auto-expire in 10 min)
    await db.collection('oauth_codes').insertOne({
      code,
      email,
      name,
      code_challenge,
      created_at: new Date(),
    });
    const target = `${redirect_uri}?code=${code}`;
    res.redirect(target);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// OAuth Code Exchange (PKCE)
app.post('/api/auth/oauth/exchange', async (req, res) => {
  try {
    const { code, code_verifier } = req.body;
    // ✅ Fetch from MongoDB (persistent across restarts)
    const oauthData = await db.collection('oauth_codes').findOne({ code });
    if (!oauthData) return res.status(400).json({ error: 'Invalid or expired auth code' });

    // Verify PKCE
    if (oauthData.code_challenge) {
      const calculatedChallenge = crypto.createHash('sha256').update(code_verifier).digest('base64url').replace(/=/g, '');
      if (calculatedChallenge !== oauthData.code_challenge) {
        return res.status(400).json({ error: 'PKCE verification failed' });
      }
    }

    // Single-use: delete code
    await db.collection('oauth_codes').deleteOne({ code });

    const authCollection = db.collection('auth_users');
    let user = await authCollection.findOne({ email: oauthData.email });
    let userId;
    if (!user) {
      userId = crypto.randomUUID();
      const hashedPassword = await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10);
      await authCollection.insertOne({ _id: userId, id: userId, email: oauthData.email, password: hashedPassword, created_at: new Date() });
      await db.collection('users').insertOne({ _id: userId, id: userId, email: oauthData.email, name: oauthData.name || oauthData.email.split('@')[0], points: 0, streak: 1, language: 'en', created_at: new Date() });
    } else {
      userId = user.id || user._id;
    }

    const token = jwt.sign({ id: userId, email: oauthData.email }, JWT_SECRET, { expiresIn: '7d' });
    const refreshToken = jwt.sign({ id: userId, email: oauthData.email, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
    res.status(200).json({ accessToken: token, refreshToken });
  } catch (err) {
    console.error('OAuth Exchange Error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// Token Refresh / Apple Sign-In
app.post('/api/auth/token', async (req, res) => {
  try {
    const { grant_type } = req.query;

    if (grant_type === 'id_token') {
      const { id_token } = req.body;
      let email, name;
      if (!id_token) return res.status(400).json({ error: 'Apple id_token is required' });
      try {
        const parts = id_token.split('.');
        if (parts.length !== 3) return res.status(401).json({ error: 'Invalid Apple token format' });
        const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf-8'));
        if (payload.iss !== 'https://appleid.apple.com') return res.status(401).json({ error: 'Invalid Apple token issuer' });
        if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) return res.status(401).json({ error: 'Apple token has expired' });
        email = payload.email;
        name = payload.name || (email ? email.split('@')[0] : undefined);
        if (!email) return res.status(401).json({ error: 'Email not found in Apple token' });
      } catch (err) {
        return res.status(401).json({ error: 'Failed to parse Apple token' });
      }
      const authCollection = db.collection('auth_users');
      let user = await authCollection.findOne({ email });
      let userId;
      if (!user) {
        userId = crypto.randomUUID();
        const hashedPassword = await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10);
        await authCollection.insertOne({ _id: userId, id: userId, email, password: hashedPassword, created_at: new Date() });
        await db.collection('users').insertOne({ _id: userId, id: userId, email, name, points: 0, streak: 1, language: 'en', created_at: new Date() });
      } else {
        userId = user.id || user._id;
      }
      const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '7d' });
      const refreshToken = jwt.sign({ id: userId, email, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
      return res.status(200).json({ accessToken: token, refreshToken });
    }

    if (grant_type === 'refresh_token') {
      const { refresh_token } = req.body;
      if (!refresh_token) return res.status(400).json({ error: 'refresh_token is required' });
      try {
        const decoded = jwt.verify(refresh_token, JWT_SECRET);
        if (decoded.type !== 'refresh') return res.status(401).json({ error: 'Invalid token type.' });
        const newToken = jwt.sign({ id: decoded.id, email: decoded.email }, JWT_SECRET, { expiresIn: '7d' });
        const newRefreshToken = jwt.sign({ id: decoded.id, email: decoded.email, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
        return res.status(200).json({ accessToken: newToken, refreshToken: newRefreshToken });
      } catch (err) {
        return res.status(401).json({ error: 'Invalid or expired refresh token. Please log in again.' });
      }
    }

    res.status(400).json({ error: 'Unsupported grant_type' });
  } catch (err) {
    console.error('Token Route Error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// ────────────────────────────────────────────────────────────────
// 2. DATABASE GENERIC RECORDS ENDPOINTS
// ────────────────────────────────────────────────────────────────

const USER_SCOPED_TABLES = ['chats', 'conversations', 'symptoms', 'vaccinations', 'menstrual_logs', 'user_subscriptions', 'bmi_logs', 'notifications'];
const PUBLIC_READ_TABLES = ['doctors', 'doctor_profiles'];
const POST_SCOPED_TABLES = ['posts'];

// GET — public or authenticated
app.get('/api/database/records/:table', async (req, res) => {
  const { table } = req.params;
  const { query, options } = parsePostgrestQuery(req.query);

  if (query.id) {
    const idVal = query.id; delete query.id;
    query.$or = [{ id: idVal }, { _id: idVal }];
  }

  if (PUBLIC_READ_TABLES.includes(table)) {
    try {
      const collection = db.collection(table);
      let cursor = collection.find(query);
      if (options.sort) cursor = cursor.sort(options.sort);
      if (options.skip) cursor = cursor.skip(options.skip);
      if (options.limit) cursor = cursor.limit(options.limit);
      const results = (await cursor.toArray()).map(mapDoc);
      return res.status(200).json(results);
    } catch (err) {
      return res.status(500).json({ error: err.message });
    }
  }

  return authenticateToken(req, res, async () => {
    try {
      if (table === 'appointments') {
        if (!query.doctor_id) query.user_id = req.user.id;
      } else if (USER_SCOPED_TABLES.includes(table)) {
        query.user_id = req.user.id;
      } else if (POST_SCOPED_TABLES.includes(table)) {
        if (query.user_id) query.user_id = req.user.id;
      } else if (table === 'users') {
        query.$or = [{ id: req.user.id }, { _id: req.user.id }];
      }
      if (query.id) {
        const idVal = query.id; delete query.id;
        query.$or = [{ id: idVal }, { _id: idVal }];
      }
      const collection = db.collection(table);
      let cursor = collection.find(query);
      if (options.sort) cursor = cursor.sort(options.sort);
      if (options.skip) cursor = cursor.skip(options.skip);
      if (options.limit) cursor = cursor.limit(options.limit);
      const results = (await cursor.toArray()).map(mapDoc);
      res.status(200).json(results);
    } catch (err) {
      console.error(`Fetch Error on ${table}:`, err);
      res.status(500).json({ error: err.message });
    }
  });
});

// POST — insert records
app.post('/api/database/records/:table', authenticateToken, async (req, res) => {
  try {
    const { table } = req.params;
    const records = Array.isArray(req.body) ? req.body : [req.body];
    const processedRecords = records.map(r => {
      const record = { ...r };
      if (USER_SCOPED_TABLES.includes(table)) record.user_id = req.user.id;
      if (table === 'users') record.id = req.user.id;
      return record;
    });
    const collection = db.collection(table);
    const onConflict = req.query.on_conflict;
    if (onConflict) {
      const results = [];
      for (const record of processedRecords) {
        const conflictValue = record[onConflict];
        if (conflictValue) {
          const filter = { [onConflict]: conflictValue };
          const id = record.id || record._id || crypto.randomUUID();
          const upsertRecord = { ...record, id, _id: id };
          await collection.replaceOne(filter, upsertRecord, { upsert: true });
          results.push(upsertRecord);
          // Broadcast upsert
          broadcastDbChange(table, 'INSERT', upsertRecord);
        }
      }
      return res.status(201).json(results);
    }
    const insertData = processedRecords.map(r => {
      const id = r.id || crypto.randomUUID();
      return { ...r, id, _id: id };
    });
    await collection.insertMany(insertData);
    // Broadcast inserts
    insertData.forEach(record => {
      broadcastDbChange(table, 'INSERT', record);
    });
    res.status(201).json(insertData);
  } catch (err) {
    console.error(`Insert Error on ${req.params.table}:`, err);
    res.status(500).json({ error: err.message });
  }
});

// PATCH — update records
app.patch('/api/database/records/:table', authenticateToken, async (req, res) => {
  try {
    const { table } = req.params;
    const { query } = parsePostgrestQuery(req.query);
    if (USER_SCOPED_TABLES.includes(table)) query.user_id = req.user.id;
    if (table === 'users') query.$or = [{ id: req.user.id }, { _id: req.user.id }];
    if (query.id) {
      const idVal = query.id; delete query.id;
      query.$or = [{ id: idVal }, { _id: idVal }];
    }
    const collection = db.collection(table);
    // Fetch affected records before updating to broadcast them
    const affectedRecords = await collection.find(query).toArray();
    await collection.updateMany(query, { $set: req.body });
    // Broadcast updates
    affectedRecords.forEach(oldRecord => {
      const updatedRecord = { ...oldRecord, ...req.body };
      broadcastDbChange(table, 'UPDATE', updatedRecord, oldRecord);
    });
    res.status(204).end();
  } catch (err) {
    console.error(`Update Error on ${req.params.table}:`, err);
    res.status(500).json({ error: err.message });
  }
});

// DELETE — delete records
app.delete('/api/database/records/:table', authenticateToken, async (req, res) => {
  try {
    const { table } = req.params;
    const { query } = parsePostgrestQuery(req.query);
    if (USER_SCOPED_TABLES.includes(table)) query.user_id = req.user.id;
    if (table === 'users') query.$or = [{ id: req.user.id }, { _id: req.user.id }];
    if (query.id) {
      const idVal = query.id; delete query.id;
      query.$or = [{ id: idVal }, { _id: idVal }];
    }
    const collection = db.collection(table);
    // Fetch records to delete to broadcast delete event
    const recordsToDelete = await collection.find(query).toArray();
    await collection.deleteMany(query);
    // Broadcast delete
    recordsToDelete.forEach(record => {
      broadcastDbChange(table, 'DELETE', record, record);
    });
    res.status(204).end();
  } catch (err) {
    console.error(`Delete Error on ${req.params.table}:`, err);
    res.status(500).json({ error: err.message });
  }
});

// ────────────────────────────────────────────────────────────────
// 3. STORAGE ENDPOINTS (AWS S3 or Local Disk)
// ────────────────────────────────────────────────────────────────

// Upload File (PUT) — requires auth
app.put('/api/storage/buckets/:bucket/objects/:file', authenticateToken, upload.single('file'), async (req, res) => {
  try {
    let fileUrl;
    if (USE_S3 && s3Client && req.file && req.file.location) {
      // S3 upload: multer-s3 gives location property
      fileUrl = req.file.location;
    } else if (req.file) {
      // Local disk: construct URL
      fileUrl = `${req.protocol}://${req.get('host')}/api/storage/buckets/${req.params.bucket}/objects/${req.params.file}`;
    } else {
      return res.status(400).json({ error: 'No file received' });
    }
    res.status(200).json({ success: true, fileName: req.params.file, url: fileUrl });
  } catch (err) {
    console.error('Storage Upload Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Download/View File (GET) — public
app.get('/api/storage/buckets/:bucket/objects/:file', (req, res) => {
  if (USE_S3 && s3Client) {
    // Redirect to S3 public URL
    const { GetObjectCommand } = require('@aws-sdk/client-s3');
    const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
    const command = new GetObjectCommand({ Bucket: S3_BUCKET, Key: `${req.params.bucket}/${req.params.file}` });
    getSignedUrl(s3Client, command, { expiresIn: 3600 }).then(url => {
      res.redirect(url);
    }).catch(_err => {
      res.status(404).json({ error: 'File not found' });
    });
  } else {
    const filePath = path.join(__dirname, 'uploads', req.params.bucket, req.params.file);
    if (fs.existsSync(filePath)) {
      res.sendFile(filePath);
    } else {
      res.status(404).json({ error: 'File not found' });
    }
  }
});

// ────────────────────────────────────────────────────────────────
// 4. EDGE FUNCTIONS
// ────────────────────────────────────────────────────────────────

// Multi-role signup
app.post('/functions/auth_signup', async (req, res) => {
  try {
    const { email, password, name, user_role = '', medical_registration_no, specialization, hospital_affiliation } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' });
    if (password.length < 8) return res.status(400).json({ error: 'Password must be at least 8 characters' });
    const authCollection = db.collection('auth_users');
    const existingUser = await authCollection.findOne({ email });
    if (existingUser) return res.status(400).json({ error: 'Email already registered' });
    const hashedPassword = await bcrypt.hash(password, 12);
    const userId = crypto.randomUUID();
    await authCollection.insertOne({ _id: userId, id: userId, email, password: hashedPassword, created_at: new Date() });
    await db.collection('users').insertOne({ _id: userId, id: userId, email, name: name || email.split('@')[0], user_role, points: 0, streak: 0, language: 'en', created_at: new Date() });
    if (user_role === 'doctor') {
      await db.collection('doctor_profiles').insertOne({ user_id: userId, medical_registration_no: medical_registration_no || '', specialization: specialization || '', hospital_affiliation: hospital_affiliation || '', is_verified: false, created_at: new Date() });
    } else {
      await db.collection('symptoms').insertOne({ user_id: userId, symptoms: [], risk_level: 'low', created_at: new Date() });
    }
    const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '7d' });
    const refreshToken = jwt.sign({ id: userId, email, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
    console.log(`[Signup] New ${user_role || 'user'} registered: ${email}`);
    res.status(200).json({ data: { accessToken: token, refreshToken } });
  } catch (err) {
    console.error('Auth Signup Error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// Update user role (post Google OAuth / onboarding)
app.post('/functions/update_user_role', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { user_role, name, medical_registration_no, specialization, hospital_affiliation, trimester, age_bracket } = req.body;
    const validRoles = ['mother', 'unmarried_girl', 'doctor'];
    if (!user_role || !validRoles.includes(user_role)) {
      return res.status(400).json({ error: `Invalid user_role. Must be one of: ${validRoles.join(', ')}` });
    }
    let computedDueDate = null;
    if (user_role === 'mother' && trimester) {
      const trimesterNum = parseInt(trimester);
      const days = trimesterNum === 1 ? 210 : trimesterNum === 2 ? 126 : 42;
      const targetDate = new Date();
      targetDate.setDate(targetDate.getDate() + days);
      computedDueDate = targetDate;
    }
    const usersCollection = db.collection('users');
    const existingUser = await usersCollection.findOne({ $or: [{ id: userId }, { _id: userId }] });
    const userUpdate = { user_role, trimester: trimester ? parseInt(trimester) : null, age_bracket: age_bracket || null, due_date: computedDueDate };
    if (name) userUpdate.name = name;
    if (!existingUser) {
      await usersCollection.insertOne({ _id: userId, id: userId, points: 0, streak: 0, language: 'en', created_at: new Date(), ...userUpdate });
    } else {
      await usersCollection.updateOne({ $or: [{ id: userId }, { _id: userId }] }, { $set: userUpdate });
    }
    if (user_role === 'doctor') {
      const dpCollection = db.collection('doctor_profiles');
      const existingDp = await dpCollection.findOne({ user_id: userId });
      const dpBody = { user_id: userId, medical_registration_no: medical_registration_no || '', specialization: specialization || '', hospital_affiliation: hospital_affiliation || '', is_verified: false, created_at: new Date() };
      if (!existingDp) {
        await dpCollection.insertOne(dpBody);
      } else {
        await dpCollection.updateOne({ user_id: userId }, { $set: { medical_registration_no: medical_registration_no || '', specialization: specialization || '', hospital_affiliation: hospital_affiliation || '' } });
      }
    } else {
      const existingSym = await db.collection('symptoms').findOne({ user_id: userId });
      if (!existingSym) await db.collection('symptoms').insertOne({ user_id: userId, symptoms: [], risk_level: 'low', created_at: new Date() });
    }
    console.log(`[Role Update] User ${userId} → ${user_role}`);
    return res.status(200).json({ success: true, user_role, message: 'User role updated successfully' });
  } catch (err) {
    console.error('Update User Role Error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// Push Notification sender (OneSignal REST API integration with graceful mock fallback)
app.post('/functions/send-notification', async (req, res) => {
  try {
    const { title, body: notifBody, type = 'general', player_ids, route, data, action1_label, action1_route, image_url } = req.body;
    console.log(`[Notification] "${title}": "${notifBody}" -> player_ids: ${JSON.stringify(player_ids || [])}`);

    const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
    const ONESIGNAL_API_KEY = process.env.ONESIGNAL_API_KEY;

    if (!ONESIGNAL_APP_ID || !ONESIGNAL_API_KEY) {
      console.warn('OneSignal not configured in environment variables (ONESIGNAL_APP_ID/ONESIGNAL_API_KEY missing) – notification simulated');
      return res.status(200).json({ success: true, warning: 'OneSignal not configured (simulated)', title, type });
    }

    // Build OneSignal REST API Payload
    const osPayload = {
      app_id: ONESIGNAL_APP_ID,
      headings: { en: title },
      contents: { en: notifBody },
      data: {
        type,
        route: route || '/home',
        data: data || {},
        action1_label,
        action1_route,
      },
      ios_badgeType: 'Increase',
      ios_badgeCount: 1,
      android_accent_color: 'FFFF69B4',
    };

    if (player_ids && player_ids.length > 0) {
      osPayload.include_subscription_ids = player_ids;
    } else {
      console.warn('No player_ids provided to send-notification');
      return res.status(400).json({ error: 'No recipients: provide player_ids' });
    }

    if (image_url) {
      osPayload.big_picture = image_url;
      osPayload.ios_attachments = { id1: image_url };
    }

    // Send HTTP POST request to OneSignal
    const osRes = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${ONESIGNAL_API_KEY}`,
      },
      body: JSON.stringify(osPayload),
    });

    const osData = await osRes.json();

    if (!osRes.ok) {
      console.error('OneSignal REST API error:', JSON.stringify(osData));
      return res.status(502).json({ error: 'OneSignal error', details: osData });
    }

    console.log(`[Notification] Sent successfully | type: ${type} | os_id: ${osData.id}`);
    res.status(200).json({ success: true, onesignal_id: osData.id, recipients: osData.recipients });
  } catch (err) {
    console.error('Notification endpoint error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

app.post('/functions/send_push_notification', async (req, res) => {
  try {
    const { token, title, body: notifBody } = req.body;
    console.log(`[Push] to "${token}": "${title}" → "${notifBody}"`);
    res.status(200).json({ success: true, message: 'FCM push sent (simulated)' });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Razorpay Payment
app.post('/functions/razorpay', authenticateToken, async (req, res) => {
  try {
    const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET;
    const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID;
    if (!RAZORPAY_KEY_SECRET || !RAZORPAY_KEY_ID) {
      return res.status(500).json({ error: 'Payment gateway not configured on server' });
    }
    const { action } = req.body;
    const VALID_PLANS = { 'monthly': 19900, 'yearly': 149900 };

    if (action === 'create_order') {
      const { plan, amount: reqAmount, currency = 'INR' } = req.body;
      let amount;
      if (plan) {
        amount = VALID_PLANS[plan];
        if (!amount) return res.status(400).json({ error: `Invalid plan. Valid: ${Object.keys(VALID_PLANS).join(', ')}` });
      } else if (reqAmount) {
        amount = parseInt(reqAmount, 10);
        if (isNaN(amount) || amount <= 0) return res.status(400).json({ error: 'Invalid amount.' });
      } else {
        return res.status(400).json({ error: 'Either plan or amount must be specified.' });
      }
      const credentials = Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString('base64');
      const response = await fetch('https://api.razorpay.com/v1/orders', {
        method: 'POST',
        headers: { 'Authorization': `Basic ${credentials}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount, currency, receipt: `maacare_${req.user.id}_${Date.now()}` }),
      });
      const order = await response.json();
      return res.status(response.status).json(order);
    }

    if (action === 'verify_payment') {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature, plan } = req.body;
      let isValid = false;
      if (razorpay_signature && razorpay_signature.trim().length > 0) {
        const generatedSignature = crypto.createHmac('sha256', RAZORPAY_KEY_SECRET).update(`${razorpay_order_id}|${razorpay_payment_id}`).digest('hex');
        isValid = generatedSignature === razorpay_signature;
      } else {
        try {
          const credentials = Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString('base64');
          const payResp = await fetch(`https://api.razorpay.com/v1/payments/${razorpay_payment_id}`, { headers: { 'Authorization': `Basic ${credentials}` } });
          if (payResp.ok) {
            const payData = await payResp.json();
            isValid = (payData.status === 'authorized' || payData.status === 'captured') && payData.order_id === razorpay_order_id;
          }
        } catch (e) { console.error('[Payment] Web verification error:', e); }
      }
      if (isValid && plan) {
        await db.collection('users').updateOne(
          { $or: [{ id: req.user.id }, { _id: req.user.id }] },
          { $set: { is_premium: true, premium_plan: plan, payment_id: razorpay_payment_id, premium_since: new Date() } }
        );
        console.log(`[Payment] Premium granted to ${req.user.email} — plan: ${plan}`);
      }
      return res.status(200).json({ success: isValid, message: isValid ? 'Payment verified' : 'Invalid payment signature' });
    }

    return res.status(400).json({ error: 'Unknown action' });
  } catch (err) {
    console.error('Razorpay Error:', err);
    res.status(500).json({ error: 'Payment processing error' });
  }
});

// ────────────────────────────────────────────────────────────────
// 5. AI ENDPOINTS
// ────────────────────────────────────────────────────────────────

// ── AI Provider: Gemini 2.5 Flash (Primary) + NVIDIA NIM (Fallback) ──────────
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || 'AIzaSyBelxMKHhhdeOaO22DzPCPrGD1XKOEiTpc';
const NVIDIA_API_KEY = process.env.NVIDIA_API_KEY || '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';

async function callGemini(messages, systemPrompt) {
  try {
    const geminiContents = messages.map(msg => ({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }]
    }));

    const body = {
      contents: geminiContents,
      generationConfig: { temperature: 0.7, maxOutputTokens: 512 }
    };
    if (systemPrompt) {
      body.systemInstruction = { parts: [{ text: systemPrompt }] };
    }

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-goog-api-key': GEMINI_API_KEY },
        body: JSON.stringify(body),
      }
    );

    if (response.ok) {
      const data = await response.json();
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (text) { console.log('✅ Gemini 2.5 Flash responded'); return text; }
    } else {
      console.warn('Gemini API error:', response.status, await response.text().catch(() => ''));
    }
  } catch (e) {
    console.error('Gemini call failed:', e.message);
  }
  return null;
}

async function callNvidiaAI(messages, systemPrompt) {
  try {
    const payloadMessages = [];
    if (systemPrompt) payloadMessages.push({ role: 'system', content: systemPrompt });
    payloadMessages.push(...messages);

    const response = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${NVIDIA_API_KEY}` },
      body: JSON.stringify({ model: 'meta/llama-3.1-70b-instruct', messages: payloadMessages, temperature: 0.7, max_tokens: 512 }),
    });

    if (response.ok) {
      const data = await response.json();
      const text = data?.choices?.[0]?.message?.content;
      if (text) { console.log('✅ NVIDIA NIM responded'); return text; }
    } else {
      console.warn('NVIDIA API error:', response.status);
    }
  } catch (e) {
    console.error('NVIDIA call failed:', e.message);
  }
  return null;
}

// Master AI function: Gemini first → NVIDIA fallback → local fallback
async function callOpenAI(messages, systemPrompt) {
  let result = await callGemini(messages, systemPrompt);
  if (result) return result;
  result = await callNvidiaAI(messages, systemPrompt);
  if (result) return result;
  return null; // will use local fallback
}



function generateLocalAiResponse(messages, systemPrompt = '') {
  const userMessages = messages.filter(m => m.role === 'user');
  const lastMsg = userMessages.length > 0 ? userMessages[userMessages.length - 1].content.toLowerCase() : '';
  const isBabyMode = systemPrompt.toLowerCase().includes('pyara sa unborn baby') || systemPrompt.toLowerCase().includes('baby');
  if (isBabyMode) {
    if (lastMsg.includes('nausea') || lastMsg.includes('vomit')) return "Oh Mama, sorry you feel sick! I am growing strong inside, please rest and drink ginger water. Love you! 👶🍼";
    if (lastMsg.includes('kick') || lastMsg.includes('move')) return "Yes Mama! I am playing inside because I love you so much! 👶👣";
    if (lastMsg.includes('tired') || lastMsg.includes('sleep')) return "Mama, please take a warm bath and rest. I will sleep with you too. 🌙👶";
    return "Mama, I am growing healthy inside! Can't wait to see you soon. 💕👶";
  } else {
    if (lastMsg.includes('kick') || lastMsg.includes('move')) return "Feeling baby movements is beautiful, Mama! Active kicks usually start between 16-25 weeks. 💕👶";
    if (lastMsg.includes('nausea') || lastMsg.includes('morning sickness')) return "Morning sickness is very common in first trimester. Try ginger tea and small frequent meals. 🌸";
    if (lastMsg.includes('tired') || lastMsg.includes('fatigue')) return "Your body is working hard to grow a new life! Rest well and eat iron-rich foods. 😴💕";
    if (lastMsg.includes('headache') || lastMsg.includes('pain')) return "Drink plenty of water and rest in a dark room. Consult your doctor before taking any painkillers. 💆‍♀️";
    if (lastMsg.includes('diet') || lastMsg.includes('food')) return "Focus on calcium, iron, protein and folic acid. Green vegetables, milk, nuts and lentils are great! 🍎🥦";
    return "You are doing amazing, Mama! Take your prenatal vitamins, stay hydrated, and rest well. 💕🌸";
  }
}

app.post('/api/ai/chat/completion', async (req, res) => {
  try {
    const { messages, systemPrompt } = req.body;
    let content = await callOpenAI(messages, systemPrompt);
    if (!content) content = generateLocalAiResponse(messages, systemPrompt);
    res.status(200).json({ success: true, content });
  } catch (err) {
    console.error('AI Chat Error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/functions/v1/maa-ai-chat', async (req, res) => {
  try {
    const { system, message } = req.body;
    const messages = [{ role: 'user', content: message }];
    let reply = await callOpenAI(messages, system);
    if (!reply) reply = generateLocalAiResponse(messages, system);
    res.status(200).json({ success: true, reply, content: reply });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/functions/ai_chat', async (req, res) => {
  try {
    const { messages, system_prompt } = req.body;
    let content = await callOpenAI(messages, system_prompt);
    if (!content) content = generateLocalAiResponse(messages, system_prompt);
    res.status(200).json({
      data: {
        choices: [{ message: { role: 'assistant', content } }],
        free_ai_chat_count: 5,
        triage_status: 'normal',
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/functions/generate_nutrition_plan', (req, res) => {
  try {
    const { fullName, age, diet, goals } = req.body;
    const name = fullName || 'Mama';
    const ageStr = age || '28';
    const dietType = diet || 'Vegetarian';
    const goalList = Array.isArray(goals) ? goals.join(', ') : 'Healthy Pregnancy';
    const data = {
      profile_summary: `Personalized plan for ${name} (${ageStr} yrs, ${dietType} diet, goals: ${goalList})`,
      calculated_needs: { calories: '2200 kcal', protein: '75g' },
      daily_plan: {
        morning_wake_up: 'Warm water with lemon and soaked almonds.',
        breakfast: 'Vegetable oats upma / stuffed paratha with curd.',
        mid_morning: 'A seasonal fresh fruit + coconut water.',
        lunch: 'Brown rice/chapati, mixed dal, spinach sabji, and fresh curd salad.',
        evening_snack: 'Roasted makhana or chana with green tea.',
        dinner: 'Moong dal khichdi or grilled tofu/paneer with steamed broccoli.',
        bedtime: 'Warm milk with turmeric.',
      },
      shopping_list: ['Soaked Almonds & Walnuts', 'Oats & Whole wheat flour', 'Green leafy vegetables', 'Lentils (Moong, Chana)', 'Curd, Paneer, Milk', 'Seasonal fresh fruits'],
      tips: 'Stay hydrated. Avoid processed food. Follow regular exercise and sleep routines. 💕',
    };
    res.status(200).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/functions/symptom_webhook', (_req, res) => {
  res.status(200).json({ success: true, message: 'Webhook processed successfully' });
});
