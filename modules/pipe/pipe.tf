resource "snowflake_pipe" "pipe" {
  name     = var.pipe_name
  database = var.database_name
  schema   = var.schema_name

  copy_statement = var.copy_statement
}