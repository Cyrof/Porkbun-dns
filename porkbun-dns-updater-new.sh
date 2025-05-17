#!/usr/bin/env bash
set -euo pipefail

# Load .env
[ -f .env ] && { set -o allexport; source .env; set +o allexport; }

# Required vars
: "${PORKBUN_API_KEY:?Need PORKBUN_API_KEY}"
: "${PORKBUN_API_SECRET:?Need PORKBUN_API_SECRET}"
: "${PORKBUN_DOMAIN:?Need PORKBUN_DOMAIN}"
: "${PORKBUN_SUBDOMAIN:=}"
TTL="${PORKBUN_TTL:-300}"

BASE="https://api.porkbun.com/api/json/v3"   # correct host
IP_URL="https://api.ipify.org"

# Build payload
payload=$(jq -nc \
  --arg apikey    "$PORKBUN_API_KEY" \
  --arg secretkey "$PORKBUN_API_SECRET" \
  '{apikey: $apikey, secretapikey: $secretkey}')
echo "→ Payload: $payload"                    # debug

# Retrieve record ID and old IP
resp=$(curl -s -X POST \
  "$BASE/dns/retrieveByNameType/$PORKBUN_DOMAIN/A/$PORKBUN_SUBDOMAIN" \
  -H "Content-Type: application/json" \
  -d "$payload")
status=$(jq -r .status <<<"$resp")
[[ $status == "SUCCESS" ]] || { echo "Retrieve error: $resp"; exit 1; }

record=$(jq -r .records[0] <<<"$resp")
oldip=$(jq -r .content <<<"$record")
id=$(jq -r .id <<<"$record")

newip=$(curl -s "$IP_URL")
if [[ "$newip" != "$oldip" ]]; then
  echo "IP changed: $oldip → $newip, updating…"
  update_payload=$(jq -nc \
    --arg apikey    "$PORKBUN_API_KEY" \
    --arg secretkey "$PORKBUN_API_SECRET" \
    --arg id        "$id" \
    --arg content   "$newip" \
    --argjson ttl   "$TTL" \
    '{apikey: $apikey, secretapikey: $secretkey, id: $id, content: $content, ttl: $ttl}')
  resp2=$(curl -s -X POST \
    "$BASE/dns/editByNameType/$PORKBUN_DOMAIN/A/$PORKBUN_SUBDOMAIN" \
    -H "Content-Type: application/json" \
    -d "$update_payload")
  [[ "$(jq -r .status <<<"$resp2")" == "SUCCESS" ]] && echo "Update successful" || echo "Update failed: $resp2"
else
  echo "No change: still $newip"
fi

