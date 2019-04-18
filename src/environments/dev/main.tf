provider "aws" {
  region = "${var.region}"
  max_retries = 5
}

module "persistence" {
  source = "../../modules/persistence"
  environment = "${var.environment}"
}
