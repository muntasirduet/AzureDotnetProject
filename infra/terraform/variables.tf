variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "project_name" {
  description = "Project prefix for resource names"
  type        = string
  default     = "taskapi"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    owner      = "student"
    purpose    = "devops-learning"
    managed_by = "terraform"
  }
}

variable "app_service_sku" {
  description = "App Service Plan SKU (B1 is minimum for Linux custom container)"
  type        = string
  default     = "B1"
}

variable "container_image_name" {
  description = "Container image repository name"
  type        = string
  default     = "taskapi"
}

variable "container_image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "demo_username" {
  description = "Demo user for JWT login endpoint"
  type        = string
  default     = "student"
}

variable "demo_password" {
  description = "Demo user password"
  type        = string
  sensitive   = true
  default     = "Pass@123"
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "create_postgres" {
  description = "Set true to provision Azure PostgreSQL Flexible Server (costs extra)"
  type        = bool
  default     = true
}

variable "postgres_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "pgadminuser"
}

variable "postgres_sku_name" {
  description = "PostgreSQL SKU. B_Standard_B1ms is lowest burstable option."
  type        = string
  default     = "B_Standard_B1ms"
}
