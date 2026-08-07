#################################
# DATABASE
#################################
module "database" {
  source = "./modules/database"

  database_name = var.database_name
}


#################################
# WAREHOUSE
#################################
module "warehouse" {
  source = "./modules/warehouse"

  warehouse_name = "EMP_WH"
  size           = "XSMALL"
  auto_suspend   = 60
}

#################################
# SCHEMAS
#################################
module "schemas" {
  source = "./modules/schema"

  database_name = module.database.database_name

  schemas = var.schemas
}


#################################
# TABLE (EMPLOYEES)
#################################
module "employee_table" {
  source = "./modules/table"

  database_name = module.database.database_name
  schema_name   = var.schemas[0] # Using the first schema (BRONZE) for table
  # schema_name   = snowflake_schema.bronze.name
  # depends_on = [snowflake_schema.bronze]
  table_name = var.emp_table

  columns = [
    { name = "EMP_ID", type = "NUMBER" },
    { name = "NAME", type = "STRING" },
    { name = "DEPT_ID", type = "NUMBER" },
    { name = "SALARY", type = "NUMBER" },
    { name = "JOIN_DATE", type = "DATE" }
  ]
}



#################################
# TABLE (BRONZE.COUNTRY)
#################################
module "country_table" {
  source = "./modules/table"

  database_name = module.database.database_name
  schema_name   = var.schemas[0] # Using the first schema (BRONZE) for table
  # schema_name   = snowflake_schema.bronze.name
  # depends_on = [snowflake_schema.bronze]
  table_name = "COUNTRY"

  columns = [
    { name = "country_id", type = "NUMBER" },
    { name = "name", type = "STRING" },
    { name = "std", type = "STRING" },
    { name = "capital", type = "STRING" }
  ]
}


#################################
# TABLE (BRONZE.GENDER)
#################################
module "gender_table" {
  source = "./modules/table"

  database_name = module.database.database_name
  schema_name   = var.schemas[0] # Using the first schema (BRONZE) for table
  # schema_name   = snowflake_schema.bronze.name
  # depends_on = [snowflake_schema.bronze]
  table_name = "GENDER"

  columns = [
    { name = "gender_id", type = "NUMBER" },
    { name = "name", type = "STRING" },
    { name = "active", type = "STRING" }
  ]
}



#################################
# TABLE (BRONZE.DEPARTMENT)
#################################
module "department_table" {
  source = "./modules/table"

  database_name = module.database.database_name
  # schema_name   = snowflake_schema.bronze.name
  schema_name = var.schemas[0] # Using the first schema (BRONZE) for table

  table_name = var.dept_table

  columns = [
    { name = "DEPT_ID", type = "NUMBER" },
    { name = "DEPT_NAME", type = "STRING" },
    { name = "LOCATION", type = "STRING" },
    { name = "CONTACT", type = "STRING" }
  ]
}


#################################
# TABLE (EMPLOYEES)
#################################
module "emp_silver_table" {
  source = "./modules/table"

  database_name = module.database.database_name
  schema_name   = var.schemas[1] # Using the schema (SILVER) for table
  # schema_name   = snowflake_schema.silver.name
  table_name = var.emp_silver_table
  # depends_on = [snowflake_schema.silver]

  columns = [
    { name = "EMP_ID", type = "NUMBER" },
    { name = "NAME", type = "STRING" },
    { name = "DEPT_ID", type = "NUMBER" },
    { name = "SALARY", type = "NUMBER" },
    { name = "JOIN_DATE", type = "DATE" }
  ]
}

#################################
# FILE FORMAT
#################################
module "file_format" {
  source = "./modules/file_format"

  database_name = module.database.database_name
  schema_name   = var.schemas[0] # Using the first schema (BRONZE) for file format
  name          = "CSV_FORMAT"
}

#################################
# STAGE
#################################
module "stage" {
  source = "./modules/stage"

  database_name = module.database.database_name
  schema_name   = var.schemas[0] # Using the first schema (BRONZE) for stage

  stage_name = "BRONZE_STAGE"
  # url        = "s3://your-bucket/path/"
}


#################################
# PIPE
#################################
locals {
  emp_table    = "${module.database.database_name}.${var.schemas[0]}.${module.employee_table.table_name}"
  bronze_stage = "@${module.database.database_name}.${var.schemas[0]}.${module.stage.stage_name}"
  csvformat    = "${module.database.database_name}.${var.schemas[0]}.${module.file_format.format_name}"
}

module "pipe" {
  source = "./modules/pipe"

  database_name = module.database.database_name
  schema_name   = var.schemas[0]

  pipe_name   = "EMP_PIPE"
  stage_name  = module.stage.stage_name
  table_name  = module.employee_table.table_name
  file_format = module.file_format.format_name

  copy_statement = <<EOT
    COPY INTO ${local.emp_table}
    FROM ${local.bronze_stage}
    FILE_FORMAT = (FORMAT_NAME = ${local.csvformat})
EOT
}

#################################
# TASK (BRONZE → SILVER)
#################################

locals {
  emp_silver_table = "${module.database.database_name}.${var.schemas[1]}.${module.emp_silver_table.table_name}"
}

module "task" {
  source = "./modules/task"

  database_name = module.database.database_name
  schema_name   = var.schemas[1] # Using the second schema (SILVER) for task

  task_name      = "BRONZE_TO_SILVER_TASK"
  warehouse_name = module.warehouse.warehouse_name

  sql_statement = <<EOT
    INSERT INTO ${local.emp_silver_table} 
    SELECT *
    FROM ${local.emp_table}  
EOT
}

#################################
# STREAM
#################################
module "stream" {
  source = "./modules/stream"

  database_name = module.database.database_name
  schema_name   = var.schemas[0] # Using the first schema (BRONZE) for stream

  stream_name = "EMP_STREAM"
  table_name  = local.emp_table
}
