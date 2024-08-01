variable "db_username" {
  description = ""
  type        = string
  default     = "admin"
}

variable "region" {
  description = ""
  type        = string
  default     = "eu-west-2"
}

# To replace dynamic fetch of availability zones
# data "aws_availability_zones" "available" {}
variable "availability_zones" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"] # Replace with your desired AZs  
}
