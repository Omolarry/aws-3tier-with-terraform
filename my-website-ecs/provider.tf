provider "aws" {
  region = var.region
  profile = "default"

  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = var.my_project_name
      "Environment" = var.environment
    }
  }
}