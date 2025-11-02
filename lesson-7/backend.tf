terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-a3f7d92c"
    key            = "lesson-7/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    profile        = "terraform"
  }
}
