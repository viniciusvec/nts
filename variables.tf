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
variable "container_source_repo_branch_nts_webapp" {
  description = ""
  type        = string
  default     = "main"
}

variable "container_display_name_nts_webapp" {
  description = ""
  type        = string
  default     = "nts_webapp"
}

# Image repo name for ECR
variable "container_source_repo_name_nts_webapp" {
  description = ""
  type        = string
  default     = "viniciusvec/nginx-buildspec"
}

variable "family" {
  description = ""
  default     = "webapp-task"
}

variable "build_project_source" {
  description = "aws/codebuild/standard:5.0"
  type        = string
  default     = "CODEPIPELINE"
}
