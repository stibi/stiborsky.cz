# The stiborsky.cz zone on Cloudflare. The zone itself is set up by hand and only looked
# up here, so Terraform can never delete it. The registrar (Internet CZ) and the
# nameservers live outside Cloudflare. The Worker and its custom domain belong to wrangler
# (wrangler.jsonc), not to Terraform.

locals {
  zone_name = "stiborsky.cz"
  zone_id   = data.cloudflare_zone.site.id

  # Zone settings with a plain value. HSTS (security_header) is an object, below.
  zone_settings = {
    always_use_https = "on"
    min_tls_version  = "1.2"
    tls_1_3          = "on"
  }

  # Proton Mail. These records existed before Terraform and were imported on the first
  # apply; the values match what Proton's dashboard asks for. TXT contents are quoted, as
  # Cloudflare recommends.
  mail_records = {
    mx_primary = {
      type     = "MX"
      name     = local.zone_name
      content  = "mail.protonmail.ch"
      priority = 10
    }
    mx_secondary = {
      type     = "MX"
      name     = local.zone_name
      content  = "mailsec.protonmail.ch"
      priority = 20
    }
    spf = {
      type    = "TXT"
      name    = local.zone_name
      content = "\"v=spf1 include:_spf.protonmail.ch ~all\""
    }
    proton_verification = {
      type    = "TXT"
      name    = local.zone_name
      content = "\"protonmail-verification=99029eb0639973968c948aecc9715ae67dba65a8\""
    }
    dkim1 = {
      type    = "CNAME"
      name    = "protonmail._domainkey.${local.zone_name}"
      content = "protonmail.domainkey.dd4zr2tg7invoxelq6yhaiai657zn3hhszaoxjik7t6ko2lwse7ea.domains.proton.ch"
    }
    dkim2 = {
      type    = "CNAME"
      name    = "protonmail2._domainkey.${local.zone_name}"
      content = "protonmail2.domainkey.dd4zr2tg7invoxelq6yhaiai657zn3hhszaoxjik7t6ko2lwse7ea.domains.proton.ch"
    }
    dkim3 = {
      type    = "CNAME"
      name    = "protonmail3._domainkey.${local.zone_name}"
      content = "protonmail3.domainkey.dd4zr2tg7invoxelq6yhaiai657zn3hhszaoxjik7t6ko2lwse7ea.domains.proton.ch"
    }
    dmarc = {
      type    = "TXT"
      name    = "_dmarc.${local.zone_name}"
      content = var.dmarc_rua == null ? "\"v=DMARC1; p=quarantine\"" : "\"v=DMARC1; p=quarantine; rua=${var.dmarc_rua}\""
    }
  }
}

data "cloudflare_zone" "site" {
  filter = {
    name    = local.zone_name
    account = { id = var.cloudflare_account_id }
  }
}

# --- TLS and HTTPS --------------------------------------------------------------------

resource "cloudflare_zone_setting" "site" {
  for_each = local.zone_settings

  zone_id    = local.zone_id
  setting_id = each.key
  value      = each.value
}

# HSTS: six months, subdomains included, not preloaded (preload is hard to undo).
resource "cloudflare_zone_setting" "hsts" {
  zone_id    = local.zone_id
  setting_id = "security_header"
  value = {
    strict_transport_security = {
      enabled            = true
      max_age            = 15552000
      include_subdomains = true
      preload            = false
      nosniff            = false
    }
  }
}

# Signs the zone. The registrar is Internet CZ, not Cloudflare, so the DS record has to
# reach the .cz registry separately (README.md, Bootstrap, DNSSEC). Until it does,
# Cloudflare reports DNSSEC as pending and resolvers don't validate; nothing breaks.
resource "cloudflare_zone_dnssec" "site" {
  zone_id = local.zone_id
  status  = "active"
}

# --- www redirect -----------------------------------------------------------------------

# www only exists to be redirected: the redirect rule acts on proxied traffic only, and
# 100:: is a placeholder origin that is never reached.
resource "cloudflare_dns_record" "www" {
  zone_id = local.zone_id
  name    = "www.${local.zone_name}"
  type    = "AAAA"
  content = "100::"
  proxied = true
  ttl     = 1
}

# The zone's single-redirect ruleset (one per zone and phase). www → apex with a 301,
# keeping the path and the query string.
resource "cloudflare_ruleset" "redirects" {
  zone_id = local.zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [
    {
      description = "www to apex"
      expression  = "(http.request.full_uri wildcard r\"https://www.${local.zone_name}/*\")"
      action      = "redirect"
      action_parameters = {
        from_value = {
          status_code           = 301
          preserve_query_string = true
          target_url = {
            expression = "wildcard_replace(http.request.full_uri, r\"https://www.${local.zone_name}/*\", r\"https://${local.zone_name}/$${1}\")"
          }
        }
      }
    },
  ]
}

# --- Email (Proton Mail) ----------------------------------------------------------------

resource "cloudflare_dns_record" "mail" {
  for_each = local.mail_records

  zone_id  = local.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  priority = try(each.value.priority, null)
  proxied  = false
  ttl      = 1
}

# --- Google Search Console --------------------------------------------------------------

resource "cloudflare_dns_record" "google_site_verification" {
  count = var.google_site_verification == null ? 0 : 1

  zone_id = local.zone_id
  name    = local.zone_name
  type    = "TXT"
  content = "\"google-site-verification=${var.google_site_verification}\""
  ttl     = 1
}

# --- Web Analytics ----------------------------------------------------------------------

# Cookieless page-view analytics. Automatic setup injects the beacon into proxied HTML;
# the CSP in site/_headers allows static.cloudflareinsights.com and cloudflareinsights.com.
resource "cloudflare_web_analytics_site" "site" {
  account_id   = var.cloudflare_account_id
  zone_tag     = local.zone_id
  auto_install = true
}
