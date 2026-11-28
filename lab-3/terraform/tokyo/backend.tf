
terraform {
  backend "s3" {
    key          = "lab3/tokyo/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
