variable "gcp_credentials" {
  description = "The path to the GCP credentials JSON file"
  type        = string
}


variable "project_id" {
  description = "time-api-1"
  type        = string
}

variable "region" {
  description = "The region to deploy resources"
  default     = "us-central1"
}


