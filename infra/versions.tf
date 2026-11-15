terraform {
  # The exact version is pinned in .tool-versions; CI installs that one.
  required_version = ">= 1.10"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.29.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.13.0"
    }
  }

  # State lives in a Cloudflare R2 bucket, created once by hand (README.md, Bootstrap).
  # The endpoint names the account, so it isn't written here: it comes from
  # AWS_ENDPOINT_URL_S3 (https://<account_id>.r2.cloudflarestorage.com), and the R2 keys
  # from AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
  backend "s3" {
    bucket = "stiborsky-cz-tfstate"
    key    = "stiborsky.cz/terraform.tfstate"
    region = "auto"

    # Lock with a lock file next to the state (S3 conditional writes, which R2 supports).
    use_lockfile = true

    # R2 is not AWS: no STS, no IMDS, no AWS regions or checksums.
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

# Token from CLOUDFLARE_API_TOKEN. Its permissions: README.md.
provider "cloudflare" {}

# Token from GITHUB_TOKEN (in CI, the TF_GITHUB_TOKEN secret). Its permissions: README.md.
provider "github" {
  owner = "stibi"
}
