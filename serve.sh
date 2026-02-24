#!/bin/bash
cd /home/runner/workspace
flutter build web --release 2>&1
node server.js
