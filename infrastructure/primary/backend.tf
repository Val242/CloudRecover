terraform {
  backend "s3" {
    bucket       = "tinoscriptdevops"
    key          = "cloudrecover/primary/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}