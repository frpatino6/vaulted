#!/bin/bash
set -e
cd "$(dirname "$0")/../apps/mobile"

: "${FIREBASE_WEB_API_KEY:?FIREBASE_WEB_API_KEY is required}"
: "${FIREBASE_AUTH_DOMAIN:?FIREBASE_AUTH_DOMAIN is required}"
: "${FIREBASE_PROJECT_ID:?FIREBASE_PROJECT_ID is required}"
: "${FIREBASE_STORAGE_BUCKET:?FIREBASE_STORAGE_BUCKET is required}"
: "${FIREBASE_MESSAGING_SENDER_ID:?FIREBASE_MESSAGING_SENDER_ID is required}"
: "${FIREBASE_WEB_APP_ID:?FIREBASE_WEB_APP_ID is required}"
: "${FIREBASE_WEB_VAPID_KEY:?FIREBASE_WEB_VAPID_KEY is required}"

flutter build web \
  --dart-define=API_BASE_URL=https://api-vaulted.casacam.net/api/ \
  --dart-define=WS_BASE_URL=https://api-vaulted.casacam.net \
  --dart-define=FIREBASE_WEB_API_KEY="$FIREBASE_WEB_API_KEY" \
  --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_WEB_APP_ID="$FIREBASE_WEB_APP_ID" \
  --dart-define=FIREBASE_WEB_VAPID_KEY="$FIREBASE_WEB_VAPID_KEY" \
  --release

# Inject Firebase config into service worker (not processed by Dart compiler)
SW=build/web/firebase-messaging-sw.js
sed -i \
  -e "s|%%FIREBASE_WEB_API_KEY%%|$FIREBASE_WEB_API_KEY|g" \
  -e "s|%%FIREBASE_AUTH_DOMAIN%%|$FIREBASE_AUTH_DOMAIN|g" \
  -e "s|%%FIREBASE_PROJECT_ID%%|$FIREBASE_PROJECT_ID|g" \
  -e "s|%%FIREBASE_STORAGE_BUCKET%%|$FIREBASE_STORAGE_BUCKET|g" \
  -e "s|%%FIREBASE_MESSAGING_SENDER_ID%%|$FIREBASE_MESSAGING_SENDER_ID|g" \
  -e "s|%%FIREBASE_WEB_APP_ID%%|$FIREBASE_WEB_APP_ID|g" \
  "$SW"

echo "Build complete → apps/mobile/build/web"

# Deploy to VM — served by Caddy at https://vaulted.casacam.net
REMOTE_DIR="/home/frpatino6/vaulted-web"
VM="tennis-backend"
ZONE="us-central1-c"
PROJECT="tennis-management-fcd54"

echo "Deploying to VM at ${VM}:${REMOTE_DIR} ..."
gcloud compute ssh "$VM" --zone "$ZONE" --project "$PROJECT" \
  --command "mkdir -p ${REMOTE_DIR} && rm -rf ${REMOTE_DIR:?}/*"
gcloud compute scp --recurse build/web/. \
  "${VM}:${REMOTE_DIR}" \
  --zone "$ZONE" --project "$PROJECT"
echo "Deploy complete → https://vaulted.casacam.net"
