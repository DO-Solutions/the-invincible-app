variable "app_name" {
  description = "name used to generate labels and other ids"
}

variable "region" {
  description = "Region where this release will be created"
}

variable "primary" {
  description = "If the helm chart is deployed in the Primary region"
}

variable "domain" {
  description = "Name of the domain used for the GLB"
}

variable "image_repository" {
  description = "Container repo with the application image"
}



