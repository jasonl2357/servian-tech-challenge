variable "aws_region" {
  description = "Name of default AWS region to use"
  type        = string
  default     = "ap-southeast-2"
}
variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}
variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}
variable "dbport" {
  description = "Port which the database should run on"
  default     = 5432
}