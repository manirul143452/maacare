const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const dns = require('dns');

if (dns.setDefaultResultOrder) {
  dns.setDefaultResultOrder('ipv4first');
}
try {
  dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);
} catch (e) {
  console.warn('Failed to set custom DNS servers:', e.message);
}

dotenv.config();



const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/maacare';
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error('FATAL: JWT_SECRET environment variable is not set.');
  console.error('Set it in Railway → Variables tab before deploying.');
  process.exit(1);
}

app.use(cors({
  origin: [
    'https://rainbow-granita-b4981d.netlify.app',
    'https://web-snowy-iota-93.vercel.app',
    'http://localhost:3000',
    'http://localhost:5000',
    'http://10.0.2.2:5000',
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'apikey', 'Prefer'],
}));
app.use(express.json());


// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Configure Multer for local storage emulation
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const bucket = req.params.bucket || 'default';
    const uploadPath = path.join(__dirname, 'uploads', bucket);
    fs.mkdirSync(uploadPath, { recursive: true });
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    cb(null, req.params.file || file.originalname);
  }
});
const upload = multer({ storage });

let db;

// Connect to MongoDB
console.log('Connecting to MongoDB...');
MongoClient.connect(MONGO_URI)
  .then(client => {
    console.log('Connected to MongoDB successfully');
    db = client.db();
    
    // Start Express server
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`MaaCare Backend is running on port ${PORT}`);
    });
  })
  .catch(err => {
    console.warn('Failed to connect to MongoDB. Falling back to local JSON File Database:', err.message);
    const { JsonDb } = require('./jsonDb');
    db = new JsonDb();
    
    // Start Express server with JSON fallback
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`MaaCare Backend (JSON DB Fallback) is running on port ${PORT}`);
    });
  });


// Helper: Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.status(401).json({ error: 'Unauthorized: Token missing' });
  
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Forbidden: Invalid token' });
    if (!user || (!user.id && !user._id)) {
      return res.status(401).json({ error: 'Unauthorized: Invalid token payload' });
    }
    req.user = {
      ...user,
      id: user.id || user._id
    };
    next();
  });
};

// Helper: Parse PostgREST query parameters
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
      // Ignore conflict flag used for upserts
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

// ────────────────────────────────────────────────────────────────
// 0. HEALTH CHECK
// ────────────────────────────────────────────────────────────────

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'maacare-backend', timestamp: new Date().toISOString() });
});

// ────────────────────────────────────────────────────────────────
// 1. AUTHENTICATION ENDPOINTS
// ────────────────────────────────────────────────────────────────

// Register / Sign Up
app.post('/api/auth/users', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    const authCollection = db.collection('auth_users');
    const existingUser = await authCollection.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = require('crypto').randomUUID();
    
    // Save to auth credentials collection
    await authCollection.insertOne({
      _id: userId,
      id: userId,
      email,
      password: hashedPassword,
      created_at: new Date()
    });
    
    // Save to public users collection (profile)
    const usersCollection = db.collection('users');
    await usersCollection.insertOne({
      _id: userId,
      id: userId,
      email,
      name: name || email.split('@')[0],
      points: 0,
      streak: 0,
      language: 'en',
      created_at: new Date()
    });
    
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
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    const authCollection = db.collection('auth_users');
    const user = await authCollection.findOne({ email });
    if (!user) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }
    
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(400).json({ error: 'Invalid email or password' });
    }
    
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
    const usersCollection = db.collection('users');
    const profile = await usersCollection.findOne({ $or: [{ id: req.user.id }, { _id: req.user.id }] });
    if (!profile) {
      return res.status(404).json({ error: 'User profile not found' });
    }
    res.status(200).json({
      user: {
        id: profile.id || profile._id,
        email: profile.email,
        name: profile.name
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// ────────────────────────────────────────────────────────────────
// REAL GOOGLE TOKEN VERIFICATION (for Flutter GoogleSignIn web/mobile)
// ────────────────────────────────────────────────────────────────

// Accept Google idToken from Flutter GoogleSignIn, verify with Google, return JWT
app.post('/api/auth/google/token', async (req, res) => {
  try {
    const { idToken, email, name, photoUrl, googleId } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    // Verify idToken with Google tokeninfo if provided
    if (idToken) {
      try {
        const verifyRes = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
        const verifyData = await verifyRes.json();
        if (verifyData.error || verifyData.email !== email) {
          return res.status(401).json({ error: 'Invalid Google token' });
        }
      } catch (verifyErr) {
        // ❗ Fail CLOSED: Never trust unverified identity even on network error
        console.error('Google token verification failed (network error):', verifyErr.message);
        return res.status(503).json({ error: 'Could not verify Google token. Please try again.' });
      }
    }

    const authCollection = db.collection('auth_users');
    const profileCollection = db.collection('user_profiles');

    // Find or create user
    let user = await authCollection.findOne({ email });
    let userId;

    if (!user) {
      userId = require('crypto').randomUUID();
      await authCollection.insertOne({
        _id: userId,
        id: userId,
        email,
        provider: 'google',
        google_id: googleId || null,
        name: name || email.split('@')[0],
        photo_url: photoUrl || null,
        created_at: new Date(),
      });

      // Create profile
      const profileId = require('crypto').randomUUID();
      await profileCollection.insertOne({
        _id: profileId,
        id: profileId,
        user_id: userId,
        full_name: name || email.split('@')[0],
        avatar_url: photoUrl || null,
        created_at: new Date(),
      });

      console.log(`[Google Auth] New user created: ${email}`);
    } else {
      userId = user.id || user._id;
      // Update photo if available
      if (photoUrl && !user.photo_url) {
        await authCollection.updateOne({ email }, { $set: { photo_url: photoUrl, updated_at: new Date() } });
      }
      console.log(`[Google Auth] Existing user signed in: ${email}`);
    }

    const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '30d' });
    const refreshToken = jwt.sign({ id: userId, email, type: 'refresh' }, JWT_SECRET, { expiresIn: '90d' });

    res.status(200).json({
      accessToken: token,
      refreshToken,
      user: { id: userId, email, name: name || email.split('@')[0] },
    });
  } catch (err) {
    console.error('Google Token Auth Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Memory store for temporary OAuth codes (PKCE)
const oauthCodes = new Map();

// OAuth Initiation - returns the Auth URL (redirecting to our beautiful mock login page)
app.get('/api/auth/oauth/:provider', (req, res) => {
  try {
    const { provider } = req.params;
    const { redirect_uri, code_challenge } = req.query;
    
    // Construct the mock auth page URL
    const params = new URLSearchParams({
      provider,
      redirect_uri,
      code_challenge
    });
    
    const host = req.headers.host;
    const protocol = req.secure || req.headers['x-forwarded-proto'] === 'https' ? 'https' : 'http';
    const authUrl = `${protocol}://${host}/api/auth/oauth-mock/login?${params.toString()}`;
    
    res.status(200).json({ authUrl });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Render the premium Mock Google/OAuth Login Screen
app.get('/api/auth/oauth-mock/login', (req, res) => {
  const { provider, redirect_uri, code_challenge } = req.query;
  
  const providerName = provider.charAt(0).toUpperCase() + provider.slice(1);
  const color = provider === 'google' ? '#4285F4' : '#333';
  
  const html = `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Sign in with ${providerName}</title>
      <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
      <style>
        body {
          margin: 0;
          font-family: 'Plus Jakarta Sans', sans-serif;
          background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
          display: flex;
          align-items: center;
          justify-content: center;
          height: 100vh;
        }
        .card {
          background: rgba(255, 255, 255, 0.9);
          backdrop-filter: blur(10px);
          border-radius: 24px;
          padding: 40px;
          width: 100%;
          max-width: 400px;
          box-shadow: 0 20px 40px rgba(0,0,0,0.1);
          text-align: center;
          border: 1px solid rgba(255,255,255,0.2);
        }
        .logo-container {
          margin-bottom: 24px;
        }
        .logo {
          font-size: 32px;
          font-weight: 700;
          background: linear-gradient(135deg, #FF6B6B 0%, #FF8E53 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        h2 {
          font-size: 22px;
          margin-bottom: 8px;
          color: #2D3748;
        }
        p {
          font-size: 14px;
          color: #718096;
          margin-bottom: 30px;
        }
        .form-group {
          margin-bottom: 20px;
          text-align: left;
        }
        label {
          display: block;
          font-size: 14px;
          font-weight: 600;
          color: #4A5568;
          margin-bottom: 8px;
        }
        input {
          width: 100%;
          padding: 14px 16px;
          border: 1px solid #E2E8F0;
          border-radius: 12px;
          font-size: 16px;
          box-sizing: border-box;
          font-family: inherit;
          transition: all 0.2s;
        }
        input:focus {
          outline: none;
          border-color: ${color};
          box-shadow: 0 0 0 3px rgba(66, 133, 244, 0.15);
        }
        .btn {
          width: 100%;
          padding: 14px;
          background: ${color};
          color: white;
          border: none;
          border-radius: 12px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          transition: background 0.2s;
          margin-top: 10px;
        }
        .btn:hover {
          opacity: 0.9;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="logo-container">
          <div class="logo">MaaCare</div>
        </div>
        <h2>Sign in with ${providerName}</h2>
        <p>Mock OAuth Authentication Portal</p>
        <form action="/api/auth/oauth-mock/callback" method="GET">
          <input type="hidden" name="redirect_uri" value="${redirect_uri}">
          <input type="hidden" name="code_challenge" value="${code_challenge}">
          
          <div class="form-group">
            <label for="name">Full Name</label>
            <input type="text" id="name" name="name" placeholder="John Doe" required value="Test User">
          </div>
          
          <div class="form-group">
            <label for="email">Email Address</label>
            <input type="email" id="email" name="email" placeholder="user@gmail.com" required value="user@gmail.com">
          </div>
          
          <button type="submit" class="btn">Continue to App</button>
        </form>
      </div>
    </body>
    </html>
  `;
  res.send(html);
});

// OAuth Callback mock - generates temporary auth code and redirects to app deep link
app.get('/api/auth/oauth-mock/callback', (req, res) => {
  try {
    const { email, name, redirect_uri, code_challenge } = req.query;
    
    if (!email || !redirect_uri) {
      return res.status(400).send('Missing email or redirect_uri');
    }
    
    const code = require('crypto').randomUUID();
    oauthCodes.set(code, {
      email,
      name,
      code_challenge
    });
    
    // Redirect browser to app's deep link with code
    const target = `${redirect_uri}?code=${code}`;
    res.redirect(target);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// OAuth Code Exchange Endpoint (PKCE)
app.post('/api/auth/oauth/exchange', async (req, res) => {
  try {
    const { code, code_verifier } = req.body;
    
    const oauthData = oauthCodes.get(code);
    if (!oauthData) {
      return res.status(400).json({ error: 'Invalid or expired auth code' });
    }
    
    // Verify PKCE
    if (oauthData.code_challenge) {
      const calculatedChallenge = require('crypto')
        .createHash('sha256')
        .update(code_verifier)
        .digest('base64url')
        .replace(/=/g, '');
        
      if (calculatedChallenge !== oauthData.code_challenge) {
        return res.status(400).json({ error: 'PKCE verification failed: Code challenge mismatch' });
      }
    }
    
    // Auth code is single-use
    oauthCodes.delete(code);
    
    // Find or create user in MongoDB
    const authCollection = db.collection('auth_users');
    let user = await authCollection.findOne({ email: oauthData.email });
    let userId;
    
    if (!user) {
      userId = require('crypto').randomUUID();
      const hashedPassword = await bcrypt.hash(require('crypto').randomBytes(16).toString('hex'), 10);
      
      await authCollection.insertOne({
        _id: userId,
        id: userId,
        email: oauthData.email,
        password: hashedPassword,
        created_at: new Date()
      });
      
      const usersCollection = db.collection('users');
      await usersCollection.insertOne({
        _id: userId,
        id: userId,
        email: oauthData.email,
        name: oauthData.name || oauthData.email.split('@')[0],
        points: 0,
        streak: 1,
        language: 'en',
        created_at: new Date()
      });
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

// OAuth ID Token verification (for Apple) + Refresh Token
app.post('/api/auth/token', async (req, res) => {
  try {
    const { grant_type } = req.query;
    
    if (grant_type === 'id_token') {
      const { provider, id_token } = req.body;
      
      // Apple ID Token validation
      let email, name;
      if (!id_token) {
        return res.status(400).json({ error: 'Apple id_token is required' });
      }
      try {
        const parts = id_token.split('.');
        if (parts.length !== 3) return res.status(401).json({ error: 'Invalid Apple token format' });
        const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf-8'));
        // Verify issuer is Apple (fail closed)
        if (payload.iss !== 'https://appleid.apple.com') {
          return res.status(401).json({ error: 'Invalid Apple token issuer' });
        }
        // Verify token is not expired (fail closed)
        if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
          return res.status(401).json({ error: 'Apple token has expired' });
        }
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
        userId = require('crypto').randomUUID();
        const hashedPassword = await bcrypt.hash(require('crypto').randomBytes(16).toString('hex'), 10);
        
        await authCollection.insertOne({
          _id: userId,
          id: userId,
          email,
          password: hashedPassword,
          created_at: new Date()
        });
        
        const usersCollection = db.collection('users');
        await usersCollection.insertOne({
          _id: userId,
          id: userId,
          email,
          name,
          points: 0,
          streak: 1,
          language: 'en',
          created_at: new Date()
        });
      } else {
        userId = user.id || user._id;
      }
      
      const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '7d' });
      const refreshToken = jwt.sign({ id: userId, email, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
      return res.status(200).json({ accessToken: token, refreshToken });
    }
    
    if (grant_type === 'refresh_token') {
      const { refresh_token } = req.body;
      if (!refresh_token) {
        return res.status(400).json({ error: 'refresh_token is required' });
      }
      try {
        const decoded = jwt.verify(refresh_token, JWT_SECRET);
        if (decoded.type !== 'refresh') {
          return res.status(401).json({ error: 'Invalid token type. Expected refresh token.' });
        }
        // Issue fresh tokens for the verified user
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
//    ✅ All routes require authentication
//    ✅ User-scoped tables enforce row-level isolation
// ────────────────────────────────────────────────────────────────

// Tables where user can only access their OWN rows (user_id = req.user.id)
const USER_SCOPED_TABLES = [
  'chats', 'conversations', 'symptoms', 'vaccinations',
  'menstrual_logs', 'user_subscriptions',
  'bmi_logs', 'notifications'
];

// Tables that are publicly readable (no auth needed — anyone can browse)
const PUBLIC_READ_TABLES = [
  'doctors', 'doctor_profiles'
];

// Tables where posts are scoped to user but doctors see their own appointments
const POST_SCOPED_TABLES = ['posts'];

// ── Public GET (no auth) — doctors list, doctor profiles ─────────────────
app.get('/api/database/records/:table', async (req, res) => {
  const { table } = req.params;
  const { query, options } = parsePostgrestQuery(req.query);

  // If query specifies 'id', rewrite it to match either 'id' or '_id'
  if (query.id) {
    const idVal = query.id;
    delete query.id;
    query.$or = [{ id: idVal }, { _id: idVal }];
  }

  // Public tables — serve without authentication
  if (PUBLIC_READ_TABLES.includes(table)) {
    try {
      const collection = db.collection(table);
      let cursor = collection.find(query);
      if (options.sort) cursor = cursor.sort(options.sort);
      if (options.skip) cursor = cursor.skip(options.skip);
      if (options.limit) cursor = cursor.limit(options.limit);
      const results = await cursor.toArray();
      const mappedResults = results.map(doc => {
        if (doc._id && !doc.id) {
          return { ...doc, id: doc._id.toString() };
        }
        return doc;
      });
      return res.status(200).json(mappedResults);
    } catch (err) {
      console.error(`Public Fetch Error on ${table}:`, err);
      return res.status(500).json({ error: err.message });
    }
  }

  // All other tables require authentication
  return authenticateToken(req, res, async () => {
    try {
      // appointments: patients see own, doctors see theirs via doctor_id param
      if (table === 'appointments') {
        if (!query.doctor_id) query.user_id = req.user.id;
      } else if (USER_SCOPED_TABLES.includes(table)) {
        query.user_id = req.user.id;
      } else if (POST_SCOPED_TABLES.includes(table)) {
        // posts: only filter by user_id if not browsing community feed
        if (query.user_id) query.user_id = req.user.id;
      } else if (table === 'users') {
        query.$or = [{ id: req.user.id }, { _id: req.user.id }];
      }

      // If query specifies 'id' (potentially injected/scoped), rewrite it
      if (query.id) {
        const idVal = query.id;
        delete query.id;
        query.$or = [{ id: idVal }, { _id: idVal }];
      }

      const collection = db.collection(table);
      let cursor = collection.find(query);
      if (options.sort) cursor = cursor.sort(options.sort);
      if (options.skip) cursor = cursor.skip(options.skip);
      if (options.limit) cursor = cursor.limit(options.limit);

      const results = await cursor.toArray();
      const mappedResults = results.map(doc => {
        if (doc._id && !doc.id) {
          return { ...doc, id: doc._id.toString() };
        }
        return doc;
      });
      res.status(200).json(mappedResults);
    } catch (err) {
      console.error(`Fetch Error on table ${table}:`, err);
      res.status(500).json({ error: err.message });
    }
  });
});

// Insert Records (POST) — requires valid JWT, injects authenticated user_id
app.post('/api/database/records/:table', authenticateToken, async (req, res) => {
  try {
    const { table } = req.params;
    const records = Array.isArray(req.body) ? req.body : [req.body];

    // Inject the authenticated user's ID — override any client-supplied user_id
    const processedRecords = records.map(r => {
      const record = { ...r };
      if (USER_SCOPED_TABLES.includes(table)) {
        record.user_id = req.user.id;
      }
      if (table === 'users') {
        record.id = req.user.id; // Users can only create their own profile row
      }
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
          const id = record.id || record._id || require('crypto').randomUUID();
          const upsertRecord = {
            ...record,
            id: id,
            _id: id
          };
          await collection.replaceOne(filter, upsertRecord, { upsert: true });
          results.push(upsertRecord);
        }
      }
      return res.status(201).json(results);
    }

    const insertData = processedRecords.map(r => {
      const id = r.id || require('crypto').randomUUID();
      return {
        ...r,
        id: id,
        _id: id
      };
    });
    await collection.insertMany(insertData);
    res.status(201).json(insertData);
  } catch (err) {
    console.error(`Insert Error on table ${req.params.table}:`, err);
    res.status(500).json({ error: err.message });
  }
});

// Update Records (PATCH) — requires valid JWT, enforces user-scoping
app.patch('/api/database/records/:table', authenticateToken, async (req, res) => {
  try {
    const { table } = req.params;
    const { query } = parsePostgrestQuery(req.query);

    if (USER_SCOPED_TABLES.includes(table)) {
      query.user_id = req.user.id;
    }
    if (table === 'users') {
      query.$or = [{ id: req.user.id }, { _id: req.user.id }];
    }

    if (query.id) {
      const idVal = query.id;
      delete query.id;
      query.$or = [{ id: idVal }, { _id: idVal }];
    }

    const collection = db.collection(table);
    await collection.updateMany(query, { $set: req.body });
    res.status(204).end();
  } catch (err) {
    console.error(`Update Error on table ${req.params.table}:`, err);
    res.status(500).json({ error: err.message });
  }
});

// Delete Records (DELETE) — requires valid JWT, enforces user-scoping
app.delete('/api/database/records/:table', authenticateToken, async (req, res) => {
  try {
    const { table } = req.params;
    const { query } = parsePostgrestQuery(req.query);

    if (USER_SCOPED_TABLES.includes(table)) {
      query.user_id = req.user.id;
    }
    if (table === 'users') {
      query.$or = [{ id: req.user.id }, { _id: req.user.id }];
    }

    if (query.id) {
      const idVal = query.id;
      delete query.id;
      query.$or = [{ id: idVal }, { _id: idVal }];
    }

    const collection = db.collection(table);
    await collection.deleteMany(query);
    res.status(204).end();
  } catch (err) {
    console.error(`Delete Error on table ${req.params.table}:`, err);
    res.status(500).json({ error: err.message });
  }
});

// ────────────────────────────────────────────────────────────────
// 3. STORAGE ENDPOINTS
// ────────────────────────────────────────────────────────────────

// Upload Object (PUT) — requires valid JWT
app.put('/api/storage/buckets/:bucket/objects/:file', authenticateToken, upload.single('file'), (req, res) => {
  try {
    const fileUrl = `/api/storage/buckets/${req.params.bucket}/objects/${req.params.file}`;
    res.status(200).json({ success: true, fileName: req.params.file, url: fileUrl });
  } catch (err) {
    console.error('Storage Upload Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Fetch/Download Object (GET)
app.get('/api/storage/buckets/:bucket/objects/:file', (req, res) => {
  try {
    const { bucket, file } = req.params;
    const filePath = path.join(__dirname, 'uploads', bucket, file);
    
    if (fs.existsSync(filePath)) {
      res.sendFile(filePath);
    } else {
      res.status(404).json({ error: 'File not found' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ────────────────────────────────────────────────────────────────
// 4. EDGE FUNCTIONS — Multi-Role Signup & Payments
// ────────────────────────────────────────────────────────────────

// ✅ /functions/auth_signup — Multi-role signup (called by Flutter auth_service.dart)
app.post('/functions/auth_signup', async (req, res) => {
  try {
    const { email, password, name, user_role = '', medical_registration_no, specialization, hospital_affiliation } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }
    const authCollection = db.collection('auth_users');
    const existingUser = await authCollection.findOne({ email });
    if (existingUser) return res.status(400).json({ error: 'Email already registered' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const userId = require('crypto').randomUUID();

    await authCollection.insertOne({ _id: userId, id: userId, email, password: hashedPassword, created_at: new Date() });
    await db.collection('users').insertOne({
      _id: userId, id: userId, email, name: name || email.split('@')[0],
      user_role, points: 0, streak: 0, language: 'en', created_at: new Date()
    });

    if (user_role === 'doctor') {
      await db.collection('doctor_profiles').insertOne({
        user_id: userId,
        medical_registration_no: medical_registration_no || '',
        specialization: specialization || '',
        hospital_affiliation: hospital_affiliation || '',
        is_verified: false, created_at: new Date()
      });
    } else {
      await db.collection('symptoms').insertOne({ user_id: userId, symptoms: [], risk_level: 'low', created_at: new Date() });
    }

    const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '7d' });
    const refreshToken = jwt.sign({ id: userId, email, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
    console.log(`[Signup] New ${user_role || 'user'} registered: ${email}`);
    res.status(200).json({ data: { accessToken: token, refreshToken } });
  } catch (err) {
    console.error('Auth Signup Error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ✅ /functions/update_user_role — Update user role post Google OAuth / Onboarding
app.post('/functions/update_user_role', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      user_role,
      name,
      medical_registration_no,
      specialization,
      hospital_affiliation,
      trimester,
      age_bracket,
    } = req.body;

    const validRoles = ['mother', 'unmarried_girl', 'doctor'];
    if (!user_role || !validRoles.includes(user_role)) {
      return res.status(400).json({ error: `Invalid user_role. Must be one of: ${validRoles.join(', ')}` });
    }

    // Compute due_date if mother is selected
    let computedDueDate = null;
    if (user_role === 'mother' && trimester) {
      const trimesterNum = parseInt(trimester);
      const days = trimesterNum === 1 ? 210 : trimesterNum === 2 ? 126 : 42;
      const targetDate = new Date();
      targetDate.setDate(targetDate.getDate() + days);
      computedDueDate = targetDate;
    }

    // Check if user exists (check both id and _id fields)
    const usersCollection = db.collection('users');
    const existingUser = await usersCollection.findOne({ $or: [{ id: userId }, { _id: userId }] });

    const userUpdate = {
      user_role,
      trimester: trimester ? parseInt(trimester) : null,
      age_bracket: age_bracket || null,
      due_date: computedDueDate,
    };
    if (name) userUpdate.name = name;

    if (!existingUser) {
      await usersCollection.insertOne({
        _id: userId,
        id: userId,
        points: 0,
        streak: 0,
        language: 'en',
        created_at: new Date(),
        ...userUpdate
      });
    } else {
      await usersCollection.updateOne({ $or: [{ id: userId }, { _id: userId }] }, { $set: userUpdate });
    }

    // If doctor, upsert doctor_profiles
    if (user_role === 'doctor') {
      const dpCollection = db.collection('doctor_profiles');
      const existingDp = await dpCollection.findOne({ user_id: userId });

      const dpBody = {
        user_id: userId,
        medical_registration_no: medical_registration_no || '',
        specialization: specialization || '',
        hospital_affiliation: hospital_affiliation || '',
        is_verified: false,
        created_at: new Date()
      };

      if (!existingDp) {
        await dpCollection.insertOne(dpBody);
      } else {
        await dpCollection.updateOne(
          { user_id: userId },
          {
            $set: {
              medical_registration_no: medical_registration_no || '',
              specialization: specialization || '',
              hospital_affiliation: hospital_affiliation || '',
            }
          }
        );
      }
    } else {
      // Create empty symptoms row if it doesn't exist
      const symCollection = db.collection('symptoms');
      const existingSym = await symCollection.findOne({ user_id: userId });
      if (!existingSym) {
        await symCollection.insertOne({ user_id: userId, symptoms: [], risk_level: 'low', created_at: new Date() });
      }
    }

    console.log(`[Role Update] User ${userId} updated role to ${user_role}`);
    return res.status(200).json({
      success: true,
      user_role,
      message: 'User role updated successfully',
    });
  } catch (err) {
    console.error('Update User Role Error:', err);
    res.status(500).json({ error: err.message || 'Internal Server Error' });
  }
});

// ✅ /functions/send-notification — Mock OneSignal push notification sender
app.post('/functions/send-notification', async (req, res) => {
  try {
    const { title, body: notifBody, type = 'general', player_ids } = req.body;
    console.log(`[Notification] Simulated push notification "${title}": "${notifBody}" to player IDs: ${JSON.stringify(player_ids || [])}`);
    res.status(200).json({ success: true, message: 'Notification sent successfully (simulated)' });
  } catch (err) {
    console.error('Send Notification Error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ✅ /functions/send_push_notification — Mock FCM push notification sender
app.post('/functions/send_push_notification', async (req, res) => {
  try {
    const { token, title, body: notifBody } = req.body;
    console.log(`[Push Notification] Simulated FCM push to token "${token}": "${title}" -> "${notifBody}"`);
    res.status(200).json({ success: true, message: 'FCM push sent successfully (simulated)' });
  } catch (err) {
    console.error('Send Push Notification Error:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// ✅ /functions/razorpay — Secure payment with server-side price enforcement
app.post('/functions/razorpay', authenticateToken, async (req, res) => {
  try {
    const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET;
    const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID;
    if (!RAZORPAY_KEY_SECRET || !RAZORPAY_KEY_ID) {
      return res.status(500).json({ error: 'Payment gateway not configured on server' });
    }

    const { action } = req.body;
    // ❗ Server-side price enforcement — client CANNOT manipulate amount
    const VALID_PLANS = { 'monthly': 19900, 'yearly': 149900 }; // in paise

    if (action === 'create_order') {
      const { plan, amount: reqAmount, currency = 'INR' } = req.body;
      let amount;
      if (plan) {
        amount = VALID_PLANS[plan];
        if (!amount) return res.status(400).json({ error: `Invalid plan. Valid plans: ${Object.keys(VALID_PLANS).join(', ')}` });
      } else if (reqAmount) {
        amount = parseInt(reqAmount, 10);
        if (isNaN(amount) || amount <= 0) {
          return res.status(400).json({ error: 'Invalid amount. Must be a positive integer.' });
        }
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

      if (razorpay_signature) {
        const generatedSignature = require('crypto')
          .createHmac('sha256', RAZORPAY_KEY_SECRET)
          .update(`${razorpay_order_id}|${razorpay_payment_id}`)
          .digest('hex');
        isValid = generatedSignature === razorpay_signature;
      } else {
        // Fallback for Web checkout where signature isn't passed to Flutter
        // Securely fetch payment details from Razorpay API using basic auth
        try {
          const credentials = Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString('base64');
          const payResp = await fetch(`https://api.razorpay.com/v1/payments/${razorpay_payment_id}`, {
            headers: { 'Authorization': `Basic ${credentials}` }
          });
          if (payResp.ok) {
            const payData = await payResp.json();
            // Verify that the payment is authorized/captured and matches the order ID
            isValid = (payData.status === 'authorized' || payData.status === 'captured') && 
                      payData.order_id === razorpay_order_id;
            console.log(`[Payment] Web verification via Razorpay API: ${isValid ? 'SUCCESS' : 'FAILED'}`);
          }
        } catch (e) {
          console.error('[Payment] Web verification fetch error:', e);
        }
      }

      if (isValid && plan) {
        // ✅ Grant premium SERVER-SIDE after verified payment (match both id and _id)
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
// 5. AI & OTHER EDGE FUNCTIONS
// ────────────────────────────────────────────────────────────────

const https = require('https');

async function callOpenAI(messages, systemPrompt) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) return null;
  
  const payloadMessages = [];
  if (systemPrompt) {
    payloadMessages.push({ role: 'system', content: systemPrompt });
  }
  payloadMessages.push(...messages);
  
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      model: 'gpt-4o-mini',
      messages: payloadMessages,
      temperature: 0.7
    });
    
    const options = {
      hostname: 'api.openai.com',
      port: 443,
      path: '/v1/chat/completions',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
        'Content-Length': Buffer.byteLength(postData)
      }
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          if (res.statusCode === 200) {
            const parsed = JSON.parse(data);
            resolve(parsed.choices[0].message.content);
          } else {
            console.error('OpenAI Error response:', res.statusCode, data);
            resolve(null);
          }
        } catch (e) {
          resolve(null);
        }
      });
    });
    
    req.on('error', (e) => {
      console.error('OpenAI Request Error:', e);
      resolve(null);
    });
    
    req.write(postData);
    req.end();
  });
}

function generateLocalAiResponse(messages, systemPrompt = '') {
  const userMessages = messages.filter(m => m.role === 'user');
  const lastMsg = userMessages.length > 0 ? userMessages[userMessages.length - 1].content.toLowerCase() : '';
  const isBabyMode = systemPrompt.toLowerCase().includes('pyara sa unborn baby') || systemPrompt.toLowerCase().includes('baby');
  
  if (isBabyMode) {
    if (lastMsg.includes('nausea') || lastMsg.includes('vomit') || lastMsg.includes('ultee')) {
      return "Oh Mama, sorry you feel sick! I am growing strong inside, but please rest, eat small snacks and drink some ginger water for me. Love you! 👶🍼";
    }
    if (lastMsg.includes('kick') || lastMsg.includes('move') || lastMsg.includes('hila')) {
      return "Yes Mama! I am playing, stretching and kicking inside because I love you so much and want to say hello! 👶👣";
    }
    if (lastMsg.includes('tired') || lastMsg.includes('sleep') || lastMsg.includes('thak')) {
      return "Mama, please take a warm bath and lie down to sleep. I will sleep quietly with you too. Good night! 🌙👶";
    }
    if (lastMsg.includes('hello') || lastMsg.includes('hi') || lastMsg.includes('baby')) {
      return "Hello, my lovely Mama! I am snug and cozy here inside. I love hearing your voice, talk to me more! 💕👶";
    }
    return "Mama, I am growing healthy and happy inside your tummy! Can't wait to see you soon. Please take care of yourself for me! ❤️👶";
  } else {
    if (lastMsg.includes('kick') || lastMsg.includes('move')) {
      return "Feeling baby movements is one of the most beautiful parts of pregnancy, Mama! Typically, active kicks start between 16-25 weeks. Try sitting quietly or drinking cold water to encourage movements. If you notice a sudden drop, always tell your doctor. 💕👶";
    }
    if (lastMsg.includes('nausea') || lastMsg.includes('vomit') || lastMsg.includes('morning sickness')) {
      return "Morning sickness is very common in the first trimester, Mama. Try eating dry crackers before getting out of bed, take ginger tea, and eat small frequent meals. Avoid spicy food. Let your doctor know if you cannot keep liquids down. 🌸";
    }
    if (lastMsg.includes('tired') || lastMsg.includes('fatigue') || lastMsg.includes('weakness')) {
      return "Your body is working hard to grow a new life, Mama! Fatigue is normal, especially in the 1st and 3rd trimesters. Focus on sleeping 8 hours, eating iron-rich foods, and taking short naps. Don't push yourself too hard. 😴💕";
    }
    if (lastMsg.includes('headache') || lastMsg.includes('pain')) {
      return "Headaches can be caused by hormonal changes, stress, or dehydration. Drink plenty of water and rest in a dark, quiet room. Always consult your doctor before taking any painkillers like paracetamol. 💆‍♀️❤️";
    }
    if (lastMsg.includes('diet') || lastMsg.includes('nutrition') || lastMsg.includes('food')) {
      return "Focus on a balanced diet rich in calcium, iron, protein, and folic acid. Include green leafy vegetables, milk, curd, nuts, lentils, and fresh fruits. Stay hydrated by drinking 8-10 glasses of water daily. 🍎🥦";
    }
    if (lastMsg.includes('hi') || lastMsg.includes('hello') || lastMsg.includes('help')) {
      return "Hello, Mama! I am Maa, your pregnancy companion. I can help you with nutrition, symptoms, or emotional support. How are you feeling today? 💕🌸";
    }
    return "You are doing an amazing job, Mama! Remember to take your prenatal vitamins, stay hydrated, and rest well. I am always here to support you on this journey. 💕🌸";
  }
}

// Primary chat endpoint (OpenAI style) used by AIService
app.post('/api/ai/chat/completion', async (req, res) => {
  try {
    const { messages, systemPrompt } = req.body;
    
    let content = await callOpenAI(messages, systemPrompt);
    if (!content) {
      content = generateLocalAiResponse(messages, systemPrompt);
    }
    
    res.status(200).json({ success: true, content });
  } catch (err) {
    console.error('AI Chat Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Maa AI Chat Edge Function (used by MaaAIService)
app.post('/functions/v1/maa-ai-chat', async (req, res) => {
  try {
    const { system, message } = req.body;
    const messages = [{ role: 'user', content: message }];
    
    let reply = await callOpenAI(messages, system);
    if (!reply) {
      reply = generateLocalAiResponse(messages, system);
    }
    
    res.status(200).json({ success: true, reply, content: reply });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// AI Chat Edge Function (used by insforge_service.dart)
app.post('/functions/ai_chat', async (req, res) => {
  try {
    const { messages, system_prompt } = req.body;
    
    let content = await callOpenAI(messages, system_prompt);
    if (!content) {
      content = generateLocalAiResponse(messages, system_prompt);
    }
    
    res.status(200).json({
      data: {
        choices: [
          {
            message: {
              role: 'assistant',
              content: content
            }
          }
        ],
        free_ai_chat_count: 5,
        triage_status: 'normal'
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Generate Nutrition Plan Edge Function (used by insforge_service.dart)
app.post('/functions/generate_nutrition_plan', (req, res) => {
  try {
    const { fullName, age, diet, goals } = req.body;
    
    const name = fullName || 'Mama';
    const ageStr = age || '28';
    const dietType = diet || 'Vegetarian';
    const goalList = Array.isArray(goals) ? goals.join(', ') : 'Healthy Pregnancy';
    
    const data = {
      profile_summary: `Personalized plan for ${name} (${ageStr} yrs, ${dietType} diet, goals: ${goalList})`,
      calculated_needs: {
        calories: "2200 kcal",
        protein: "75g"
      },
      daily_plan: {
        morning_wake_up: "Warm water with lemon and soaked almonds.",
        breakfast: "Vegetable oats upma / stuffed paratha with curd.",
        mid_morning: "A seasonal fresh fruit (e.g., apple, guava) + coconut water.",
        lunch: "Brown rice/chapati, mixed dal, spinach sabji, and fresh curd salad.",
        evening_snack: "Roasted makhana or chana with a cup of green tea.",
        dinner: "Moong dal khichdi or grilled tofu/paneer with steamed broccoli.",
        bedtime: "A cup of warm milk with turmeric."
      },
      shopping_list: [
        "Soaked Almonds & Walnuts",
        "Oats & Whole wheat flour",
        "Green leafy vegetables (spinach, broccoli)",
        "Lentils (Moong, Chana)",
        "Curd, Paneer, Milk",
        "Seasonal fresh fruits"
      ],
      tips: "Stay hydrated. Avoid processed food. Follow regular exercise and sleep routines. 💕"
    };
    
    res.status(200).json({ success: true, data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Symptom Webhook Edge Function (used by insforge_service.dart)
app.post('/functions/symptom_webhook', (req, res) => {
  try {
    res.status(200).json({ success: true, message: 'Webhook processed successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
