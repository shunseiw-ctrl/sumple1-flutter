const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const https = require('https');

const PORT = 5000;
const ROOT = path.resolve('./build/web');

const LINE_CHANNEL_ID = process.env.LINE_CHANNEL_ID || '';
const LINE_CHANNEL_SECRET = process.env.LINE_CHANNEL_SECRET || '';

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
    admin.initializeApp({ projectId: 'alba-work' });
    console.log('Firebase Admin SDK initialized without service account (custom tokens will not work until FIREBASE_SERVICE_ACCOUNT is set)');
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

const securityHeaders = {
  'X-Content-Type-Options': 'nosniff',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
  'Cache-Control': 'no-cache, no-store, must-revalidate',
};

const stateStore = new Map();
const tokenStore = new Map();

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
    if (postData) req.write(postData);
    req.end();
  });
}

function handleAuthLineStart(req, res) {
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
      console.error('LINE token exchange failed:', tokenRes.data);
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
      console.error('LINE profile fetch failed:', profileRes.data);
      res.writeHead(302, { Location: '/#line_error=profile_failed', ...securityHeaders });
      res.end();
      return;
    }

    const lineUser = profileRes.data;
    const firebaseUid = `line:${lineUser.userId}`;

    console.log('LINE login successful:', { displayName: lineUser.displayName, uid: firebaseUid });

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
          displayName: lineUser.displayName || 'LINEユーザー',
          photoURL: lineUser.pictureUrl || null,
        });
        console.log('Created new Firebase user for LINE:', firebaseUid);
      } else {
        throw e;
      }
    }

    await admin.auth().updateUser(firebaseUid, {
      displayName: lineUser.displayName || 'LINEユーザー',
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
        displayName: lineUser.displayName || '',
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
    console.error('LINE callback error:', e);
    res.writeHead(302, { Location: '/#line_error=server_error', ...securityHeaders });
    res.end();
  }
}

function handleTokenExchange(req, res) {
  let body = '';
  req.on('data', (chunk) => { body += chunk; });
  req.on('end', () => {
    try {
      const { code } = JSON.parse(body);

      if (!code || !tokenStore.has(code)) {
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
      res.writeHead(200, { 'Content-Type': contentType, ...securityHeaders });
      res.end(content);
    }
  });
}

const server = http.createServer(async (req, res) => {
  const urlPath = req.url.split('?')[0].split('#')[0];

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
