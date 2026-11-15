# stiborsky.cz

Personal website: <https://stiborsky.cz>. A static page (HTML, CSS, a bit of JavaScript,
no build step) served as [Cloudflare Workers static assets](https://developers.cloudflare.com/workers/static-assets/).
The Cloudflare zone and this GitHub repository are managed by Terraform in
[`infra/`](infra/README.md).

| Path | What |
|---|---|
| `site/` | Everything that is served: `index.html`, `styles.css`, the scripts, `404.html`, `robots.txt` |
| `site/_headers` | Response headers: Content-Security-Policy and other security headers (not served itself) |
| `wrangler.jsonc` | Cloudflare config: assets only, no Worker code, custom domain `stiborsky.cz` |
| `infra/` | Terraform: zone settings, DNS (incl. Proton Mail), `www` redirect, DNSSEC, Web Analytics, the GitHub repository |
| `docs/obsah.md` | The site's content as text |
| `.github/workflows/` | `ci.yml` checks, `website.yml` deploys, `infra.yml` plans and applies |

## Commands

```bash
pnpm install
pnpm run check     # html-validate and an internal link and #fragment check
pnpm run dev       # wrangler dev: serves site/ with _headers and 404 handling, on :8787
```

The Content-Security-Policy allows scripts and styles from the site itself only (plus the
Cloudflare Web Analytics beacon), with no `'unsafe-inline'`: no inline `<script>`,
`<style>` or `style=""`. Setting `element.style` from a script file is fine.

## Deploying

Every push to `main` that touches `site/`, `wrangler.jsonc` or the dependencies runs
`.github/workflows/website.yml`: `pnpm run check`, then `wrangler deploy`. If the check
fails, nothing is deployed. Run it by hand from the Actions tab (**Run workflow**) to
redeploy.

The deploy creates or updates the Worker `stiborsky-cz-website` and the custom domain
`stiborsky.cz` from `routes` in `wrangler.jsonc`; Cloudflare adds the DNS record and the
certificate. `www.stiborsky.cz` is redirected to the apex by a rule in Terraform. Unknown
paths get `404.html` with status 404.

Setup, once:

1. **Zone.** `stiborsky.cz` is already an active zone in the Cloudflare account. The apex
   must not have an A, AAAA or CNAME record, or the custom domain can't be attached.
2. **API token.** My Profile → API Tokens → Create Token → Custom token, named
   "stiborsky.cz deploy", with only these permissions:

   | Scope | Permission | Access |
   |---|---|---|
   | Account | Workers Scripts | Edit |
   | Account | Account Settings | Read |
   | Zone | Workers Routes | Edit |

   Account resources: only this account. Zone resources: Specific zone → `stiborsky.cz`.
3. **GitHub secrets.** Repository → Settings → Secrets and variables → Actions:
   - `CLOUDFLARE_API_TOKEN`: the token.
   - `CLOUDFLARE_ACCOUNT_ID`: the account ID (the zone's overview page, right column).
4. **First deploy.** Push to `main`, or Actions → Website → Run workflow. Then
   <https://stiborsky.cz> serves the site.
5. **Check.** `curl -sI https://stiborsky.cz` gives `200` with the `content-security-policy`
   header; once Terraform has applied, `curl -sI 'https://www.stiborsky.cz/a?b=c'` gives
   `301` to `https://stiborsky.cz/a?b=c`.
