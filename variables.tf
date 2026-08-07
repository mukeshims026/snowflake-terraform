variable "snowflake_organization" {
  default = "NOHZSYP"
}
variable "snowflake_account" {
  default = "WU68667"
}
variable "username" {
  default = "MUKESHIMS026"
}
variable "password" {
  default = "Welcomemukesh1986"
}
variable "role" {
  default = "ACCOUNTADMIN"
}

variable "database_name" {
  default = "HRDB"
}
variable "database_salesdb_name" {
  default = "SALESDB"
}

variable "schemas" {
  default = ["BRONZE", "SILVER", "GOLD"]
}

variable "emp_table" {
  default = "EMPLOYEES"
}

variable "emp_silver_table" {
  default = "EMP_SILVER"
}

variable "dept_table" {
  default = "DEPARTMENT"
}