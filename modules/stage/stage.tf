resource "snowflake_stage" "stage" {
  name     = var.stage_name
  database = var.database_name
  schema   = var.schema_name

}