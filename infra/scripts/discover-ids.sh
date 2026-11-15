#!/usr/bin/env bash
# Prints what the zone holds today, so cloudflare.tf can match it before the first apply.
# Read-only: GET requests only. imports.tf finds the IDs it needs by itself; this is for
# checking that nothing else is there (other records, a redirect ruleset, Web Analytics).
#
# Reads CLOUDFLARE_API_TOKEN (the Terraform token) and CLOUDFLARE_ACCOUNT_ID from the
# environment, e.g. from infra/.envrc via direnv (README.md, Run locally).
set -euo pipefail

: "${CLOUDFLARE_API_TOKEN:?set CLOUDFLARE_API_TOKEN}"
: "${CLOUDFLARE_ACCOUNT_ID:?set CLOUDFLARE_ACCOUNT_ID}"
zone_name=stiborsky.cz
api=https://api.cloudflare.com/client/v4

get() {
  curl -fsS -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" "$api$1"
}

zone_id=$(get "/zones?name=$zone_name&account.id=$CLOUDFLARE_ACCOUNT_ID" | jq -r '.result[0].id // empty')
if [[ -z "$zone_id" ]]; then
  echo "zone $zone_name not found in the account" >&2
  exit 1
fi
echo "zone_id: $zone_id"

echo
echo "== DNS records (each must be in cloudflare.tf, or be left alone on purpose)"
get "/zones/$zone_id/dns_records?per_page=100" |
  jq -r '.result[] | [.id, .type, .name, (.priority // "" | tostring), .content, (if .proxied then "proxied" else "dns only" end), "ttl=\(.ttl)"] | @tsv'

echo
echo "== Redirect ruleset (none expected: Terraform creates it; if there is one, add an import)"
get "/zones/$zone_id/rulesets" |
  jq -c '.result[] | select(.phase == "http_request_dynamic_redirect" and .kind == "zone") | {id, name}'

echo
echo "== DNSSEC"
get "/zones/$zone_id/dnssec" | jq -c '.result | {status, ds}'

echo
echo "== Zone settings changed from their defaults (modified_on is set)"
get "/zones/$zone_id/settings" |
  jq -c '.result[] | select(.modified_on != null) | {id, value, modified_on}'

echo
echo "== Web Analytics sites in the account (if $zone_name is listed, add an import)"
get "/accounts/$CLOUDFLARE_ACCOUNT_ID/rum/site_info/list" |
  jq -c '.result[]? | {site_tag, host: (.ruleset.zone_name // .host), auto_install}'
