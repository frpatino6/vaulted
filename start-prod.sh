#!/bin/bash
set -a
source .env.prod
set +a
docker compose -f docker-compose.prod.yml "$@"
