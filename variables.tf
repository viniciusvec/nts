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



##################### Container CI/CD
variable "container_source_repo_branch_nginx" {
  description = ""
  type        = string
  default     = "main"
}

variable "container_display_name_nginx" {
  description = ""
  type        = string
  default     = "nginx"
}

# Image repo name for ECR
variable "container_image_repo_name_nginx" {
  description = ""
  type        = string
  default     = "viniciusvec/nginx-buildspec"
}

variable "stack" {
  description = "Name of the stack."
  default     = "Nginx"
}

variable "build_project_source" {
  description = "aws/codebuild/standard:4.0"
  type        = string
  default     = "CODEPIPELINE"
}
