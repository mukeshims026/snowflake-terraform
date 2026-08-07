resource "snowflake_task" "task" {
  name     = var.task_name
  database = var.database_name
  schema   = var.schema_name

  warehouse = var.warehouse_name
  started = true
  schedule {
    minutes = 60
  }
  sql_statement = var.sql_statement
}