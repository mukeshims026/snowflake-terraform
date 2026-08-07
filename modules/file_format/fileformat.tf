resource "snowflake_file_format" "format" {
  name     = var.name
  database = var.database_name
  schema   = var.schema_name

  format_type     = "CSV"
  field_delimiter = ","
  skip_header     = 1
}