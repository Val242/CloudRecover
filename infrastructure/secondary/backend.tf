terraform {
  backend "s3" {
    bucket       = "tinoscriptdevops"
    key          = "cloudrecover/secondary/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}