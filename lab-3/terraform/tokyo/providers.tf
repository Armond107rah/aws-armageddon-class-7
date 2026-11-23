
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-armageddon-lab3"
      Environment = "learning"
      RegionRole  = "tokyo-primary"
      ManagedBy   = "terraform"
    }
  }
}
