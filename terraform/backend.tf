terraform {
  backend "s3" {
    bucket         = "roboshop-terraform-state-rk1214"
    key            = "roboshop/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "roboshop-terraform-locks"
  }
}