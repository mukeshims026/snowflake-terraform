variable "database_name" {}
variable "schema_name" {}
variable "table_name" {}

variable "columns" {
  type = list(object({
    name = string
    type = string
  }))
}