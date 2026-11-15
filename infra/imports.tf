# What was set up by hand before Terraform, imported so the first apply adopts it instead
# of creating it again. Once applied, this whole file can be deleted.

# Zone settings always exist, so they are imported, never created.
import {
  for_each = local.zone_settings
  to       = cloudflare_zone_setting.site[each.key]
  id       = "${local.zone_id}/${each.key}"
}

import {
  to = cloudflare_zone_setting.hsts
  id = "${local.zone_id}/security_header"
}

# DNSSEC has a state whether it's on or off.
import {
  to = cloudflare_zone_dnssec.site
  id = local.zone_id
}

# The Proton Mail records, found by type, name and a part of their content. Each lookup
# must find exactly one record, or the plan fails and says which one.
data "cloudflare_dns_records" "existing_mail" {
  for_each = local.mail_records

  zone_id = local.zone_id
  type    = each.value.type
  name    = { exact = each.value.name }
  content = { contains = each.value.match }
}

import {
  for_each = local.mail_records
  to       = cloudflare_dns_record.mail[each.key]
  id       = "${local.zone_id}/${one(data.cloudflare_dns_records.existing_mail[each.key].result).id}"
}

# --- GitHub -----------------------------------------------------------------------------

import {
  to = github_repository.site
  id = local.repository
}

import {
  to = github_repository_vulnerability_alerts.site
  id = local.repository
}

import {
  to = github_repository_dependabot_security_updates.site
  id = local.repository
}
