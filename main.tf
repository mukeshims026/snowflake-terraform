#################################
# DATABASE
#################################
module "hr_database" {
  source        = "./modules/database"
  database_name = var.database_name
}


module "test_database" {
  source        = "./modules/database"
  database_name = var.database_report_name
}

#################################
# WAREHOUSE
#################################
module "warehouse" {
  source         = "./modules/warehouse"
  warehouse_name = "EMP_WH"
  size           = "XSMALL"
  auto_suspend   = 60
}

#################################
# SCHEMAS
#################################
module "schemas" {
  source        = "./modules/schema"
  database_name = module.hr_database.database_name
  schemas       = var.schemas

  depends_on = [module.hr_database]
}

#################################
# TABLE (EMPLOYEES)
#################################
module "employee_table" {
  source        = "./modules/table"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0] # Using the first schema (BRONZE) for table
  table_name    = var.emp_table

  columns = [
    { name = "EMP_ID", type = "NUMBER" },
    { name = "NAME", type = "STRING" },
    { name = "DEPT_ID", type = "NUMBER" },
    { name = "SALARY", type = "NUMBER" },
    { name = "JOIN_DATE", type = "DATE" }
  ]

  depends_on = [module.schemas]
}

#################################
# TABLE (BRONZE.COUNTRY)
#################################
module "country_table" {
  source        = "./modules/table"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]
  table_name    = "COUNTRY"

  columns = [
    { name = "country_id", type = "NUMBER" },
    { name = "name", type = "STRING" },
    { name = "std", type = "STRING" },
    { name = "capital", type = "STRING" }
  ]

  depends_on = [module.schemas]
}

#################################
# TABLE (BRONZE.GENDER)
#################################
module "gender_table" {
  source        = "./modules/table"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]
  table_name    = "GENDER"

  columns = [
    { name = "gender_id", type = "NUMBER" },
    { name = "name", type = "STRING" },
    { name = "active", type = "STRING" }
  ]

  depends_on = [module.schemas]
}

#################################
# TABLE (BRONZE.DEPARTMENT)
#################################
module "department_table" {
  source        = "./modules/table"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]
  table_name    = var.dept_table

  columns = [
    { name = "DEPT_ID", type = "NUMBER" },
    { name = "DEPT_NAME", type = "STRING" },
    { name = "LOCATION", type = "STRING" },
    { name = "CONTACT", type = "STRING" }
  ]

  depends_on = [module.schemas]
}

#################################
# TABLE (BRONZE.COUNTRY)
#################################
module "order_raw_table" {
  source        = "./modules/table"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]
  table_name    = "ORDER_RAW"

  columns = [
    { name = "ORDERID", type = "NUMBER" },
    { name = "ORDERDATE", type = "STRING" },
    { name = "CUSTOMERID", type = "STRING" },
    { name = "CUSTOMERNAME", type = "STRING" },
    { name = "ITEMID", type = "STRING" },

    { name = "ITEMNAME", type = "STRING" },
    { name = "QUANTITY", type = "STRING" },
    { name = "RATE", type = "STRING" },
    { name = "ADDRESS", type = "STRING" },
    { name = "CITY", type = "STRING" },
    { name = "COUNTRY", type = "STRING" },
  ]

  depends_on = [module.schemas]
}

#################################
# TABLE (SILVER.EMPLOYEES)
#################################
module "emp_silver_table" {
  source        = "./modules/table"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[1] # Using the schema (SILVER) for table
  table_name    = var.emp_silver_table

  columns = [
    { name = "EMP_ID", type = "NUMBER" },
    { name = "NAME", type = "STRING" },
    { name = "DEPT_ID", type = "NUMBER" },
    { name = "SALARY", type = "NUMBER" },
    { name = "JOIN_DATE", type = "DATE" }
  ]

  depends_on = [module.schemas]
}

#################################
# FILE FORMAT
#################################
module "file_format" {
  source        = "./modules/file_format"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]
  name          = "CSV_FORMAT"
  parse_header  = true

  depends_on = [module.schemas]
}

#################################
# STAGE
#################################
module "stage" {
  source        = "./modules/stage"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]
  stage_name    = "BRONZE_STAGE"

  depends_on = [module.schemas, module.file_format]
}

#################################
# PIPE
#################################
locals {
  emp_table    = "${module.hr_database.database_name}.${var.schemas[0]}.${module.employee_table.table_name}"
  bronze_stage = "@${module.hr_database.database_name}.${var.schemas[0]}.${module.stage.stage_name}"
  csvformat    = "${module.hr_database.database_name}.${var.schemas[0]}.${module.file_format.format_name}"
}

module "pipe" {
  source        = "./modules/pipe"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]

  pipe_name   = "EMP_PIPE"
  stage_name  = module.stage.stage_name
  table_name  = module.employee_table.table_name
  file_format = module.file_format.format_name

  copy_statement = <<EOT
    COPY INTO ${local.emp_table}
    FROM ${local.bronze_stage}
    FILE_FORMAT = (FORMAT_NAME = ${local.csvformat}
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE)
EOT

  depends_on = [module.stage, module.employee_table, module.file_format]
}

locals {
  ORDER_RAW = "${module.hr_database.database_name}.${var.schemas[0]}.${module.order_raw_table.table_name}"
}

module "ORDER_RAW_PIPE" {
  source        = "./modules/pipe"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]

  pipe_name   = "ORDER_RAW_PIPE"
  stage_name  = module.stage.stage_name
  table_name  = module.employee_table.table_name
  file_format = module.file_format.format_name

  copy_statement = <<EOT
    COPY INTO ${local.ORDER_RAW}
    FROM ${local.bronze_stage}
    FILE_FORMAT = (FORMAT_NAME = ${local.csvformat})
EOT

  depends_on = [module.stage, module.employee_table, module.file_format]
}

#################################
# TASK (BRONZE → SILVER)
#################################
locals {
  emp_silver_table = "${module.hr_database.database_name}.${var.schemas[1]}.${module.emp_silver_table.table_name}"
}

module "task" {
  source        = "./modules/task"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[1]

  task_name      = "BRONZE_TO_SILVER_TASK"
  warehouse_name = module.warehouse.warehouse_name

  sql_statement = <<EOT
    INSERT INTO ${local.emp_silver_table} 
    SELECT *
    FROM ${local.emp_table}  
EOT

  depends_on = [module.employee_table, module.emp_silver_table, module.warehouse]
}

locals {
  l_ORDER_RAW_PIPE = "${module.hr_database.database_name}.${var.schemas[0]}.${module.ORDER_RAW_PIPE.pipe_name}"
}

module "TASK_LOAD_RAW_ORDER" {
  source        = "./modules/task"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]

  task_name      = "TASK_LOAD_RAW_ORDER"
  warehouse_name = module.warehouse.warehouse_name

  sql_statement = <<EOT
    alter pipe ${local.l_ORDER_RAW_PIPE} refresh
EOT

  depends_on = [module.order_raw_table, module.warehouse, module.ORDER_RAW_PIPE]
}

#################################
# STREAM
#################################
module "stream" {
  source        = "./modules/stream"
  database_name = module.hr_database.database_name
  schema_name   = var.schemas[0]
  stream_name   = "EMP_STREAM"
  table_name    = local.emp_table

  depends_on = [module.employee_table]
}
