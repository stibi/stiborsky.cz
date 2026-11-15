#!/usr/bin/env bash
# Turns site/ into the dev preview, in place: no indexing (robots.txt and an
# X-Robots-Tag header) and a visible note with the pull request and commit.
# Run only in CI, right before `wrangler deploy --env dev`; never commit the result.
#
#   scripts/mark-dev.sh <pr-number> <short-sha>
set -euo pipefail
cd "$(dirname "$0")/.."
pr=${1:?pull request number}
sha=${2:?commit}

printf 'User-agent: *\nDisallow: /\n' > site/robots.txt

# The header goes on every path: right below the "/*" line of site/_headers.
sed -i 's|^/\*$|/*\n  X-Robots-Tag: noindex, nofollow|' site/_headers
grep -q 'X-Robots-Tag' site/_headers

# A small badge, so a preview is never mistaken for production. Styled by .dev-badge in
# styles.css; no inline style (the CSP forbids it).
for f in site/*.html; do
  sed -i "s|<body\([^>]*\)>|<body\1>\n  <div class=\"dev-badge\" role=\"note\">preview · PR #${pr} · ${sha}</div>|" "$f"
done
grep -q 'dev-badge' site/index.html
