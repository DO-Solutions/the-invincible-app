variable "app_name" {
  description = "name used to generate labels and other ids"
}

variable "region" {
  description = "DO region slug where the cluster is deployed"
}

variable "db_cluster_name" {
  description = "Name of the DB Cluster at the primary site."
}

variable "db_replica_name" {
  description = "Name of the DB Replica at the secondary site."
}

variable "letsencrypt_email" {
  description = "Email address used when submitting cert requests to LetsEncrypt. Only needs to be set if you want to get emails about expiration, etc"
  default = "null@digitalocean.com"
}


