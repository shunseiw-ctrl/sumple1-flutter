#!/bin/bash
cd /home/runner/workspace
flutter build web --release --pwa-strategy=none 2>&1
rm -f build/web/flutter_service_worker.js
node server.js
