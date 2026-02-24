#!/bin/bash
cd /home/runner/workspace
flutter build web --release 2>&1
cd /home/runner/workspace/build/web
node -e "
const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve('.');

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
  'X-Frame-Options': 'SAMEORIGIN',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
  'Cache-Control': 'no-cache, no-store, must-revalidate',
};

const server = http.createServer((req, res) => {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405, { 'Content-Type': 'text/plain', ...securityHeaders });
    res.end('Method Not Allowed');
    return;
  }

  let urlPath;
  try {
    urlPath = decodeURIComponent(req.url.split('?')[0]);
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

  let filePath = urlPath === '/' ? path.join(ROOT, 'index.html') : requestedPath;
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
});

server.listen(5000, '0.0.0.0', () => {
  console.log('Serving Flutter web on http://0.0.0.0:5000');
});
"
