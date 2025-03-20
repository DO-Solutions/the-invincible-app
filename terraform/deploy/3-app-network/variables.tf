variable "app_name" {
  description = "name used to generate labels and other ids"
}

variable "parent_domain" {
  description = "DNS domain in which a the child domain used for the GLB will be created. Must be a DO managed domain."
}

variable "primary_region" {
  description = "DO region for the primary region where the DB cluster is deployed"
}

variable "secondary_region" {
  description = "DO region for the secondary region where the DB replica is deployed"
}

variable "image_repository" {
  description = "URL for the container repo with the invincible app container."
}