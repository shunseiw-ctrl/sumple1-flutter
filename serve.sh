#!/bin/bash
cd /home/runner/workspace
flutter build web --release 2>&1
cd /home/runner/workspace/build/web
node -e "
const http = require('http');
const fs = require('fs');
const path = require('path');

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

const server = http.createServer((req, res) => {
  let filePath = '.' + (req.url === '/' ? '/index.html' : req.url.split('?')[0]);
  const ext = path.extname(filePath).toLowerCase();
  const contentType = mimeTypes[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      fs.readFile('./index.html', (e2, fallback) => {
        res.writeHead(200, {
          'Content-Type': 'text/html',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        });
        res.end(fallback);
      });
    } else {
      res.writeHead(200, {
        'Content-Type': contentType,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
      });
      res.end(content);
    }
  });
});

server.listen(5000, '0.0.0.0', () => {
  console.log('Serving Flutter web on http://0.0.0.0:5000');
});
"
