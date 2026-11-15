# The GitHub repository stibi/stiborsky.cz. Created by hand and imported on the first apply.
# Actions secrets are not managed here: their values would land in the state. They are
# listed in README.md.

locals {
  repository = "stiborsky.cz"
}

resource "github_repository" "site" {
  name         = local.repository
  description  = "Osobní web stiborsky.cz: DevOps, infrastruktura a provoz aplikací. Statický web na Cloudflare Workers, zóna a repozitář v Terraformu."
  homepage_url = "https://stiborsky.cz"
  topics = [
    "website",
    "static-site",
    "cloudflare-workers",
    "terraform",
    "devops",
  ]
  visibility = "public"

  has_issues      = true
  has_discussions = false
  has_projects    = false
  has_wiki        = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = false
  delete_branch_on_merge = true
  allow_forking          = true

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  # Never delete the repository: a destroy archives it instead, and Terraform refuses to
  # plan a destroy at all.
  archive_on_destroy = true
  lifecycle {
    prevent_destroy = true
  }
}

# Dependabot alerts, and pull requests that fix them.
resource "github_repository_vulnerability_alerts" "site" {
  repository = github_repository.site.name
  enabled    = true
}

resource "github_repository_dependabot_security_updates" "site" {
  repository = github_repository.site.name
  enabled    = true

  # Security updates need the alerts first.
  depends_on = [github_repository_vulnerability_alerts.site]
}

# main can't be deleted or force-pushed. Nothing else: pushes go straight to main;
# only infra/ changes go through a pull request, for the plan.
resource "github_repository_ruleset" "main" {
  repository  = github_repository.site.name
  name        = "main"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }
}

# The environment the infra workflow applies in, only from main. Add required reviewers
# here to make every apply wait for an approval.
resource "github_repository_environment" "infra" {
  repository  = github_repository.site.name
  environment = "infra"

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "infra_main" {
  repository     = github_repository.site.name
  environment    = github_repository_environment.infra.environment
  branch_pattern = "main"
}
