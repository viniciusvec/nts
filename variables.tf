variable "db_username" {
  description = ""
  type        = string
  default     = "admin"
}

# To replace dynamic fetch of availability zones
# data "aws_availability_zones" "available" {}
variable "availability_zones" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"] # Replace with your desired AZs  
}
