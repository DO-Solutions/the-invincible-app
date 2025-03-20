variable "app_name" {
  description = "name used to generate labels and other ids"
}

variable "primary_region" {
  description = "DO region for the primary region where the DB cluster is deployed"
}

variable "secondary_region" {
  description = "DO region for the secondary region where the DB replica is deployed"
}

variable "db_size" {
  description = "Slug for size to use for DB cluster and replica"
}

variable "k8s_worker_size" {
  description = "Slug for size to use for k8s workers"
}