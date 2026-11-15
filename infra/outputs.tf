output "zone_id" {
  description = "The stiborsky.cz zone."
  value       = local.zone_id
}

output "dnssec_ds_record" {
  description = "The DS record, for the registrar (README.md, Bootstrap, DNSSEC)."
  value       = cloudflare_zone_dnssec.site.ds
}

output "web_analytics_site_tag" {
  description = "The Web Analytics site, for the dashboard and a manual beacon if automatic setup can't inject it."
  value       = cloudflare_web_analytics_site.site.site_tag
}
