#!/bin/bash
cd /home/runner/workspace
flutter clean 2>&1
flutter pub get 2>&1
flutter build web --release --pwa-strategy=none 2>&1
rm -f build/web/flutter_service_worker.js
node server.js
