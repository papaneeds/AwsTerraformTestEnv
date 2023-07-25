terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region                   = "ca-central-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "VSCodeServiceAccount"
}