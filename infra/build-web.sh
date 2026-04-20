#!/bin/bash
set -e
cd "$(dirname "$0")/../apps/mobile"
flutter build web \
  --dart-define=API_BASE_URL=https://api-vaulted.casacam.net/api/ \
  --dart-define=WS_BASE_URL=https://api-vaulted.casacam.net \
  --release
echo "Build complete → apps/mobile/build/web"
firebase deploy --only hosting --project vaulted-prod-2026
