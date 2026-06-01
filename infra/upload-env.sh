#!/bin/bash
set -euo pipefail

LOCAL_ENV="${1:-/home/fernando/Documentos/Development/Vaulted/.env.prod}"
REMOTE="${VAULTED_DEPLOY_REMOTE:-frpatino6@tennis-backend:~/vaulted/vaulted/.env.prod}"
ZONE="${GCP_ZONE:-us-central1-c}"
PROJECT="${GCP_PROJECT:-tennis-management-fcd54}"

if [ ! -f "$LOCAL_ENV" ]; then
  echo "Missing env file: $LOCAL_ENV" >&2
  exit 1
fi

chmod 600 "$LOCAL_ENV"

gcloud compute scp "$LOCAL_ENV" "$REMOTE" --zone="$ZONE" --project="$PROJECT"

gcloud compute ssh "${VAULTED_DEPLOY_VM:-tennis-backend}" --zone="$ZONE" --project="$PROJECT" --command='chmod 600 ~/vaulted/vaulted/.env.prod'
