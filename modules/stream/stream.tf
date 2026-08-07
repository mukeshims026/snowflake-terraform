resource "snowflake_stream_on_table" "stream" {
  name     = var.stream_name
  database = var.database_name
  schema   = var.schema_name
  table = var.table_name
}