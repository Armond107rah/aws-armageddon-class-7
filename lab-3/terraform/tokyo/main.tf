
# Tokyo networking foundation
# Reuses the networking module from Lab 2.

module "networking" {
  source = "../../../lab-2/infrastructure/modules/networking"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr

  public_subnet_cidrs = var.public_subnet_cidrs

  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
}
