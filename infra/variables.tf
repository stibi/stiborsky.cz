variable "cloudflare_account_id" {
  description = "Cloudflare account that holds the stiborsky.cz zone (TF_VAR_cloudflare_account_id)."
  type        = string
  # Kept out of plan output: plans are posted on pull requests of a public repository.
  sensitive = true
}

variable "google_site_verification" {
  description = "Google Search Console verification token, the part after \"google-site-verification=\". Null adds no record."
  type        = string
  default     = null
}

variable "dmarc_rua" {
  description = "Address for DMARC aggregate reports, e.g. \"mailto:dmarc@stiborsky.cz\". Null asks for none."
  type        = string
  default     = null
}
