variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ci-cd-lab-cluster"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "unsplash_access_key" {
  description = "Unsplash API access key"
  type        = string
  sensitive   = true
}
