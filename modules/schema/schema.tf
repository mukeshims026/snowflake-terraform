resource "snowflake_schema" "schemas" {
  for_each = toset(var.schemas)

  name     = each.value
  database = var.database_name
}

variable "database_name" {}
variable "schemas" {
  type = list(string)
}