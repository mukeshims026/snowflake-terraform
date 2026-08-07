resource "snowflake_table" "table" {
  name     = var.table_name
  database = var.database_name
  schema   = var.schema_name

  dynamic "column" {
    for_each = var.columns
    content {
      name = column.value.name
      type = column.value.type
    }
  }
}



