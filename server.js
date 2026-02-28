const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const https = require('https');

const PORT = 5000;
const ROOT = path.resolve('./build/web');

const LINE_CHANNEL_ID = (process.env.LINE_CHANNEL_ID || '').trim();
const LINE_CHANNEL_SECRET = (process.env.LINE_CHANNEL_SECRET || '').trim();

const REPLIT_DOMAIN = process.env.REPLIT_DEV_DOMAIN || '';
const BASE_URL = REPLIT_DOMAIN ? `https://${REPLIT_DOMAIN}` : `http://localhost:${PORT}`;
const CALLBACK_URL = `${BASE_URL}/auth/line/callback`;

let admin;
try {
  admin = require('firebase-admin');
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccountJson) {
    const serviceAccount = JSON.parse(serviceAccountJson);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('Firebase Admin SDK initialized with service account');
  } else {
    console.error('FIREBASE_SERVICE_ACCOUNT is not set. Custom token creation will not work.');
    admin.initializeApp({ projectId: 'alba-work' });
  }
} catch (e) {
  console.error('Firebase Admin SDK initialization failed:', e.message);
  admin = null;
}

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.wasm': 'application/wasm',
};

// --- セキュリティヘッダー ---
function getSecurityHeaders() {
  const headers = {
    'X-Content-Type-Options': 'nosniff',
    'X-XSS-Protection': '0',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Content-Security-Policy': [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://apis.google.com https://www.gstatic.com",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' https://fonts.gstatic.com",
      "img-src 'self' data: https: blob:",
      "connect-src 'self' https://*.googleapis.com https://*.firebaseio.com https://*.cloudfunctions.net wss://*.firebaseio.com https://api.line.me https://firestore.googleapis.com",
      "frame-src 'self' https://*.firebaseapp.com https://accounts.google.com",
    ].join('; '),
  };

  // 本番環境のみ HSTS を設定
  if (REPLIT_DOMAIN) {
    headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains';
  }

  return headers;
}

const securityHeaders = getSecurityHeaders();

const stateStore = new Map();
const tokenStore = new Map();

// --- IP取得（プロキシ対応）---
function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded) {
    // X-Forwarded-For の最初のIPを取得（クライアントIP）
    return forwarded.split(',')[0].trim();
  }
  return req.socket.remoteAddress || 'unknown';
}

// --- レートリミット（IP単位）---
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX_REQUESTS = 10;

function isRateLimited(req) {
  const ip = getClientIp(req);
  const now = Date.now();

  if (!rateLimitMap.has(ip)) {
    rateLimitMap.set(ip, { count: 1, windowStart: now });
    return false;
  }

  const entry = rateLimitMap.get(ip);
  if (now - entry.windowStart > RATE_LIMIT_WINDOW_MS) {
    entry.count = 1;
    entry.windowStart = now;
    return false;
  }

  entry.count++;
  return entry.count > RATE_LIMIT_MAX_REQUESTS;
}

// --- カスタムトークン生成のレートリミット（UID単位, 5回/10分）---
const tokenRateLimitMap = new Map();
const TOKEN_RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
const TOKEN_RATE_LIMIT_MAX = 5;

function isTokenRateLimited(uid) {
  const now = Date.now();

  if (!tokenRateLimitMap.has(uid)) {
    tokenRateLimitMap.set(uid, { count: 1, windowStart: now });
    return false;
  }

  const entry = tokenRateLimitMap.get(uid);
  if (now - entry.windowStart > TOKEN_RATE_LIMIT_WINDOW_MS) {
    entry.count = 1;
    entry.windowStart = now;
    return false;
  }

  entry.count++;
  return entry.count > TOKEN_RATE_LIMIT_MAX;
}

// 定期クリーンアップ（5分ごと）
setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of rateLimitMap.entries()) {
    if (now - entry.windowStart > RATE_LIMIT_WINDOW_MS * 2) {
      rateLimitMap.delete(ip);
    }
  }
  for (const [uid, entry] of tokenRateLimitMap.entries()) {
    if (now - entry.windowStart > TOKEN_RATE_LIMIT_WINDOW_MS * 2) {
      tokenRateLimitMap.delete(uid);
    }
  }
}, 5 * 60 * 1000);

// --- CORS ---
function getAllowedOrigin() {
  if (REPLIT_DOMAIN) return `https://${REPLIT_DOMAIN}`;
  return `http://localhost:${PORT}`;
}

function applyCors(req, res) {
  const origin = req.headers.origin;
  const allowed = getAllowedOrigin();
  if (origin === allowed) {
    res.setHeader('Access-Control-Allow-Origin', allowed);
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Max-Age', '86400');
}

function cleanupExpired(store, maxAgeMs) {
  const now = Date.now();
  for (const [key, entry] of store.entries()) {
    const ts = typeof entry === 'number' ? entry : entry.createdAt;
    if (now - ts > maxAgeMs) store.delete(key);
  }
}

function httpsRequest(url, options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data: data });
        }
      });
    });
    req.on('error', reject);
    req.setTimeout(10000, () => {
      req.destroy(new Error('Request timeout'));
    });
    if (postData) req.write(postData);
    req.end();
  });
}

// --- exchangeCode のフォーマット検証 ---
function isValidExchangeCode(code) {
  if (typeof code !== 'string') return false;
  // 64文字の16進数文字列（crypto.randomBytes(32).toString('hex')）
  return /^[a-f0-9]{64}$/.test(code);
}

function handleAuthLineStart(req, res) {
  if (!LINE_CHANNEL_ID || !LINE_CHANNEL_SECRET) {
    res.writeHead(503, { 'Content-Type': 'application/json', ...securityHeaders });
    res.end(JSON.stringify({ error: 'line_not_configured' }));
    return;
  }

  const state = crypto.randomBytes(32).toString('hex');
  stateStore.set(state, Date.now());
  cleanupExpired(stateStore, 10 * 60 * 1000);

  const params = new URLSearchParams({
    response_type: 'code',
    client_id: LINE_CHANNEL_ID,
    redirect_uri: CALLBACK_URL,
    state: state,
    scope: 'profile openid',
  });

  const lineAuthUrl = `https://access.line.me/oauth2/v2.1/authorize?${params.toString()}`;
  res.writeHead(302, { Location: lineAuthUrl, ...securityHeaders });
  res.end();
}

async function handleAuthLineCallback(req, res) {
  try {
    const url = new URL(req.url, BASE_URL);
    const code = url.searchParams.get('code');
    const state = url.searchParams.get('state');
    const error = url.searchParams.get('error');

    if (error) {
      console.error('LINE auth error:', error, url.searchParams.get('error_description'));
      res.writeHead(302, { Location: '/#line_error=auth_denied', ...securityHeaders });
      res.end();
      return;
    }

    if (!state || !stateStore.has(state)) {
      res.writeHead(302, { Location: '/#line_error=invalid_state', ...securityHeaders });
      res.end();
      return;
    }
    stateStore.delete(state);

    if (!code) {
      res.writeHead(302, { Location: '/#line_error=no_code', ...securityHeaders });
      res.end();
      return;
    }

    const tokenParams = new URLSearchParams({
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: CALLBACK_URL,
      client_id: LINE_CHANNEL_ID,
      client_secret: LINE_CHANNEL_SECRET,
    });

    const tokenRes = await httpsRequest('https://api.line.me/oauth2/v2.1/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    }, tokenParams.toString());

    if (tokenRes.status !== 200 || !tokenRes.data.access_token) {
      console.error('LINE token exchange failed:', tokenRes.status);
      res.writeHead(302, { Location: '/#line_error=token_failed', ...securityHeaders });
      res.end();
      return;
    }

    const accessToken = tokenRes.data.access_token;

    const profileRes = await httpsRequest('https://api.line.me/v2/profile', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    if (profileRes.status !== 200 || !profileRes.data.userId) {
      console.error('LINE profile fetch failed:', profileRes.status);
      res.writeHead(302, { Location: '/#line_error=profile_failed', ...securityHeaders });
      res.end();
      return;
    }

    const lineUser = profileRes.data;

    // userId のフォーマット検証（LINEのuserIdは英数字）
    if (typeof lineUser.userId !== 'string' || !/^U[a-f0-9]{32}$/.test(lineUser.userId)) {
      console.error('Invalid LINE userId format');
      res.writeHead(302, { Location: '/#line_error=invalid_profile', ...securityHeaders });
      res.end();
      return;
    }

    const firebaseUid = `line:${lineUser.userId}`;

    // UID単位のレートリミット
    if (isTokenRateLimited(firebaseUid)) {
      console.warn('Token rate limited:', firebaseUid.substring(0, 12));
      res.writeHead(302, { Location: '/#line_error=rate_limited', ...securityHeaders });
      res.end();
      return;
    }

    console.log('LINE login successful:', { uid: firebaseUid.substring(0, 12) });

    if (!admin) {
      res.writeHead(302, { Location: '/#line_error=server_config', ...securityHeaders });
      res.end();
      return;
    }

    try {
      await admin.auth().getUser(firebaseUid);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        await admin.auth().createUser({
          uid: firebaseUid,
          displayName: (lineUser.displayName || 'LINEユーザー').substring(0, 100),
          photoURL: lineUser.pictureUrl || null,
        });
        console.log('Created new Firebase user for LINE:', firebaseUid.substring(0, 12));
      } else {
        throw e;
      }
    }

    await admin.auth().updateUser(firebaseUid, {
      displayName: (lineUser.displayName || 'LINEユーザー').substring(0, 100),
      photoURL: lineUser.pictureUrl || null,
    });

    const customToken = await admin.auth().createCustomToken(firebaseUid, {
      provider: 'line',
      lineUserId: lineUser.userId,
    });

    const exchangeCode = crypto.randomBytes(32).toString('hex');
    tokenStore.set(exchangeCode, {
      customToken,
      profile: {
        displayName: (lineUser.displayName || '').substring(0, 100),
        photoUrl: lineUser.pictureUrl || '',
        provider: 'line',
      },
      createdAt: Date.now(),
    });
    cleanupExpired(tokenStore, 5 * 60 * 1000);

    res.writeHead(302, {
      Location: `/#line_code=${exchangeCode}`,
      ...securityHeaders,
    });
    res.end();

  } catch (e) {
    console.error('LINE callback error:', e.message);
    res.writeHead(302, { Location: '/#line_error=server_error', ...securityHeaders });
    res.end();
  }
}

const MAX_BODY_SIZE = 1024;

function handleTokenExchange(req, res) {
  // Content-Type 検証
  const contentType = (req.headers['content-type'] || '').toLowerCase();
  if (!contentType.includes('application/json')) {
    res.writeHead(400, { 'Content-Type': 'application/json', ...securityHeaders });
    res.end(JSON.stringify({ error: 'invalid_content_type' }));
    return;
  }

  let body = '';
  let bodySize = 0;
  let aborted = false;

  req.on('data', (chunk) => {
    if (aborted) return;
    bodySize += chunk.length;
    if (bodySize > MAX_BODY_SIZE) {
      aborted = true;
      res.writeHead(413, { 'Content-Type': 'application/json', ...securityHeaders });
      res.end(JSON.stringify({ error: 'payload_too_large' }));
      req.destroy();
      return;
    }
    body += chunk;
  });
  req.on('end', () => {
    if (aborted) return;
    try {
      const { code } = JSON.parse(body);

      // exchangeCode のフォーマット検証
      if (!isValidExchangeCode(code)) {
        res.writeHead(400, { 'Content-Type': 'application/json', ...securityHeaders });
        res.end(JSON.stringify({ error: 'invalid_code_format' }));
        return;
      }

      if (!tokenStore.has(code)) {
        res.writeHead(400, { 'Content-Type': 'application/json', ...securityHeaders });
        res.end(JSON.stringify({ error: 'invalid_code' }));
        return;
      }

      const entry = tokenStore.get(code);
      tokenStore.delete(code);

      if (Date.now() - entry.createdAt > 5 * 60 * 1000) {
        res.writeHead(400, { 'Content-Type': 'application/json', ...securityHeaders });
        res.end(JSON.stringify({ error: 'code_expired' }));
        return;
      }

      res.writeHead(200, { 'Content-Type': 'application/json', ...securityHeaders });
      res.end(JSON.stringify({
        customToken: entry.customToken,
        profile: entry.profile,
      }));
    } catch (e) {
      res.writeHead(400, { 'Content-Type': 'application/json', ...securityHeaders });
      res.end(JSON.stringify({ error: 'invalid_request' }));
    }
  });
}

function serveStaticFile(req, res) {
  let urlPath;
  try {
    urlPath = decodeURIComponent(req.url.split('?')[0].split('#')[0]);
  } catch (e) {
    res.writeHead(400, { 'Content-Type': 'text/plain', ...securityHeaders });
    res.end('Bad Request');
    return;
  }

  const requestedPath = path.resolve(ROOT, '.' + urlPath);
  if (!requestedPath.startsWith(ROOT)) {
    res.writeHead(403, { 'Content-Type': 'text/plain', ...securityHeaders });
    res.end('Forbidden');
    return;
  }

  const filePath = urlPath === '/' ? path.join(ROOT, 'index.html') : requestedPath;
  const ext = path.extname(filePath).toLowerCase();
  const contentType = mimeTypes[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      fs.readFile(path.join(ROOT, 'index.html'), (e2, fallback) => {
        if (e2) {
          res.writeHead(500, { 'Content-Type': 'text/plain', ...securityHeaders });
          res.end('Internal Server Error');
          return;
        }
        res.writeHead(200, { 'Content-Type': 'text/html', ...securityHeaders });
        res.end(fallback);
      });
    } else {
      // 静的アセットにはキャッシュヘッダーを設定
      const responseHeaders = { 'Content-Type': contentType, ...securityHeaders };
      if (ext !== '.html') {
        responseHeaders['Cache-Control'] = 'public, max-age=31536000, immutable';
      }
      res.writeHead(200, responseHeaders);
      res.end(content);
    }
  });
}

const server = http.createServer(async (req, res) => {
  applyCors(req, res);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, securityHeaders);
    res.end();
    return;
  }

  const urlPath = req.url.split('?')[0].split('#')[0];

  // Rate limit auth endpoints
  if (urlPath.startsWith('/auth/')) {
    if (isRateLimited(req)) {
      res.writeHead(429, { 'Content-Type': 'application/json', ...securityHeaders });
      res.end(JSON.stringify({ error: 'too_many_requests' }));
      return;
    }
  }

  if (urlPath === '/auth/line' && req.method === 'GET') {
    handleAuthLineStart(req, res);
    return;
  }

  if (urlPath === '/auth/line/callback' && req.method === 'GET') {
    await handleAuthLineCallback(req, res);
    return;
  }

  if (urlPath === '/auth/line/exchange' && req.method === 'POST') {
    handleTokenExchange(req, res);
    return;
  }

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, { 'Content-Type': 'text/plain', ...securityHeaders });
    res.end('Method Not Allowed');
    return;
  }

  serveStaticFile(req, res);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Serving Flutter web on http://0.0.0.0:${PORT}`);
  console.log(`LINE callback URL: ${CALLBACK_URL}`);
  if (!LINE_CHANNEL_ID || !LINE_CHANNEL_SECRET) {
    console.warn('WARNING: LINE_CHANNEL_ID or LINE_CHANNEL_SECRET not set');
  }
});
