terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 0.98"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-mukesh"
    key            = "snowflake/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-mukesh"
    encrypt        = true
    assume_role {
      role_arn = "arn:aws:iam::799722407171:role/SnowflakeAccess"
    }
  }
}



provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name      = var.snowflake_account
  user              = var.username
  password          = var.password
  role              = var.role
}