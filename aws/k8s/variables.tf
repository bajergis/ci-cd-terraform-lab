variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "unsplash_access_key" {
  description = "Unsplash API access key"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Postgres password"
  type        = string
  sensitive   = true
}
