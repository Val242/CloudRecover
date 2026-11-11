provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "recovery"
  region = "eu-west-2"
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}