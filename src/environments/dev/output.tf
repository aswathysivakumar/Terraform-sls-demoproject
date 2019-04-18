output "environment" {
  value = "${var.environment}"
}

output "persistence" {
  value = "${module.persistence.tables}"
}