# Infra

Terraform for the stiborsky.cz zone on Cloudflare and for this GitHub repository. The
same setup as achtunk8s.io (`stibi/achtunk8s`, `infra/`), with two differences: the domain
receives mail (Proton Mail), and the registrar is Internet CZ, not Cloudflare.

Changes go through a pull request: the `Infra` workflow posts the plan as a comment (and
updates it on every push). Merging applies: a push to `main` that touches `infra/` plans
again and applies exactly that plan, in the GitHub environment `infra`. Never apply from a
laptop. A setting changed in a dashboard is reverted by the next apply; change it here.

## What is managed

| Where | Managed here | Not here |
|---|---|---|
| Cloudflare | Zone settings: Always Use HTTPS, minimum TLS 1.2, TLS 1.3, HSTS (6 months, subdomains, no preload) | The zone itself (looked up, never created or deleted), the nameservers |
| | DNSSEC signing | The DS record at the registry: Internet CZ / CZ.NIC (Bootstrap, step 9) |
| | DNS: Proton Mail (2× MX, SPF, verification TXT, 3× DKIM CNAME, DMARC), `www` (`AAAA 100::`, proxied), the optional Search Console TXT | The Worker `stiborsky-cz-website` and its custom domain `stiborsky.cz` with its DNS record: wrangler (`wrangler.jsonc`) |
| | The `www` → apex redirect rule (301, path and query kept) | |
| | Web Analytics, automatic setup | |
| GitHub | The repository: description, homepage, topics, features, merge settings, secret scanning and push protection | Actions secrets (values would land in the state; listed below) |
| | Dependabot alerts and security updates | |
| | The `main` ruleset: no deletion, no force push | |
| | The environment `infra`, deployable from `main` only | |

**Mail.** The Proton records are imported with the values they have today. If Proton's
dashboard ever asks for different ones, change them here, not in Cloudflare. DMARC stays
at `p=quarantine`; set `dmarc_rua` to get aggregate reports.

### Variables

Set them in `infra/terraform.tfvars` (committed; nothing in them is secret):

```hcl
google_site_verification = "abc123…"                 # Search Console TXT token
dmarc_rua                = "mailto:dmarc@stiborsky.cz" # DMARC aggregate reports
```

`cloudflare_account_id` comes from the `CLOUDFLARE_ACCOUNT_ID` secret.

## Check

```bash
infra/scripts/check.sh    # terraform fmt -check, validate; no credentials or state
```

It runs in CI. Fix the formatting with `terraform -chdir=infra fmt -recursive`.

## Bootstrap, once

1. **State bucket.** Cloudflare dashboard → R2 → Create bucket `stiborsky-cz-tfstate`
   (location automatic, standard storage).
2. **State keys.** R2 → Manage API tokens → Create Account API token, named
   "stiborsky.cz terraform state": permission **Object Read & Write**, applied to the
   bucket `stiborsky-cz-tfstate` only. Keep the Access Key ID and the Secret Access Key.
3. **Cloudflare token.** My Profile → API Tokens → Create Token → Custom token, named
   "stiborsky.cz terraform", separate from the deploy token:

   | Scope | Permission | Access | For |
   |---|---|---|---|
   | Zone | Zone | Read | Looking up the zone |
   | Zone | Zone Settings | Edit | TLS, HTTPS, HSTS |
   | Zone | DNS | Edit | Records and DNSSEC |
   | Zone | Single Redirect | Edit | The `www` redirect rule |
   | Account | Account Settings | Edit | Web Analytics (the API needs it to create a site) |

   Zone resources: Specific zone → `stiborsky.cz`. Account resources: only this account.
4. **GitHub token.** Settings → Developer settings → Fine-grained tokens → Generate,
   named "stiborsky.cz terraform", resource owner `stibi`, Only select repositories →
   `stiborsky.cz`. Repository permissions: **Administration: Read and write** and
   **Metadata: Read**. It expires; renew it before it does.
5. **Secrets.** Repository → Settings → Secrets and variables → Actions:

   | Secret | Value |
   |---|---|
   | `TF_CLOUDFLARE_API_TOKEN` | The Cloudflare token (3) |
   | `CLOUDFLARE_ACCOUNT_ID` | The account ID (shared with the website deploy) |
   | `TF_STATE_ACCESS_KEY_ID` | R2 Access Key ID (2) |
   | `TF_STATE_SECRET_ACCESS_KEY` | R2 Secret Access Key (2) |
   | `TF_GITHUB_TOKEN` | The GitHub token (4) |

6. **Look first.** Run `make ids` (Run locally, below). It lists every DNS record, a
   redirect ruleset and Web Analytics if they exist. On the first apply the existing
   Proton records were adopted with `import` blocks (since removed, see Imports later).
7. **First plan.** `make init && make plan` locally, then open a pull request and read the
   plan in its comment: imports, the new `www` record, the redirect rule, Web Analytics,
   the GitHub settings, and nothing destroyed. Possible noise on the mail records: quotes
   added around TXT contents, or a TTL going to auto (1). Both are harmless. Any
   other change to a mail record means the code doesn't match, so fix the code first.
8. **Apply.** Merge. The `Infra` workflow applies in the environment `infra`.
9. **DNSSEC.** Cloudflare now signs the zone and publishes CDS/CDNSKEY records. The DS
   (in .cz: the KEYSET) still has to reach CZ.NIC. Either:
   - wait: CZ.NIC's automated keyset management picks up CDNSKEY from an unsigned
     domain after watching it for about a week, and notifies the domain holder by email.
     `dig +short CDNSKEY stiborsky.cz` should show the key meanwhile; or
   - do it now: in Internet CZ's domain administration, set DNSSEC (KEYSET) from
     `terraform output dnssec_ds_record` / the Cloudflare dashboard (DNS → Settings →
     DNSSEC).

   Until then plans show `status: "pending" -> "active"`. `dig +short DS stiborsky.cz`
   shows it once it's there.
10. **Check.** `dig +short MX stiborsky.cz` still gives the two Proton servers; a test
    mail arrives; `curl -sI https://www.stiborsky.cz` gives `301`.

## Run locally

```bash
cp infra/.envrc.example infra/.envrc && direnv allow   # then fill in infra/.envrc
cd infra
make ids          # what the zone holds; read-only
make init
make plan         # -lock=false: a local plan doesn't hold the state lock
make plan-file    # the same, into a temp file, with the summary on screen
```

`make help` lists the targets. There is no apply target on purpose: merging applies.

## Imports later

Something made by hand that should be managed: add its resource and an `import` block
(e.g. in a new `imports.tf`) with its ID (`make ids` prints them), and open a pull
request. The plan shows `will be imported`. Once applied, the block can go.
