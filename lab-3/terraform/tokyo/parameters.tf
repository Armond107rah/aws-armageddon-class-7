
# Store Tokyo database configuration in AWS Systems Manager Parameter Store.
#
# Store only the endpoint, port, database name, and a reference to the managed secret.

module "parameters" {
  count = var.enable_tokyo_database ? 1 : 0

  source = "../../../lab-2/infrastructure/modules/parameters"

  project_name = var.project_name

  db_endpoint = module.database[0].rds_endpoint
  db_port     = module.database[0].rds_port
  db_name     = module.database[0].db_name

  master_secret_arn = (
    module.database[0].master_secret_arn
  )

  parameter_path = "/lab3/tokyo/db"
}
