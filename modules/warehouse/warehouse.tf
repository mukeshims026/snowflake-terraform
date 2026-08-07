resource "snowflake_warehouse" "warehouse" {
  name                 = var.warehouse_name
  warehouse_size       = var.size
  auto_suspend         = var.auto_suspend
  auto_resume          = true
  initially_suspended  = true

  min_cluster_count    = 1
  max_cluster_count    = 2
  scaling_policy       = "STANDARD"

  statement_timeout_in_seconds = 300
}
