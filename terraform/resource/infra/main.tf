terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_project" "project" {
  name = var.app_name
}

resource "digitalocean_vpc" "primary" {
  name   = "${var.app_name}-${var.primary_region}"
  region = var.primary_region
}

resource "digitalocean_vpc" "secondary" {
  name   = "${var.app_name}-${var.secondary_region}"
  region = var.secondary_region
}

resource "digitalocean_vpc_peering" "peering" {
  name = var.app_name
  vpc_ids = [
    digitalocean_vpc.primary.id,
    digitalocean_vpc.secondary.id
  ]
}

resource "digitalocean_database_cluster" "primary" {
  name                 = "${var.app_name}-${var.primary_region}"
  engine               = "pg"
  version              = "16"
  size                 = var.db_size
  region               = var.primary_region
  node_count           = 2
  private_network_uuid = digitalocean_vpc.primary.id
  project_id           = digitalocean_project.project.id
}

resource "digitalocean_database_firewall" "allow_vpc_primary" {
  cluster_id = digitalocean_database_cluster.primary.id

  rule {
    type  = "ip_addr"
    value = digitalocean_vpc.primary.ip_range
  }

  rule {
    type  = "ip_addr"
    value = digitalocean_vpc.secondary.ip_range
  }
}

resource "digitalocean_database_replica" "secondary" {
  cluster_id           = digitalocean_database_cluster.primary.id
  name                 = "${var.app_name}-${var.secondary_region}"
  size                 = var.db_size
  region               = var.secondary_region
  private_network_uuid = digitalocean_vpc.secondary.id
}

resource "digitalocean_database_firewall" "allow_vpc_secondary" {
  cluster_id = digitalocean_database_replica.secondary.uuid

  rule {
    type  = "ip_addr"
    value = digitalocean_vpc.primary.ip_range
  }

  rule {
    type  = "ip_addr"
    value = digitalocean_vpc.secondary.ip_range
  }
}

resource "digitalocean_kubernetes_cluster" "primary" {
  name                             = "${var.app_name}-${var.primary_region}"
  region                           = var.primary_region
  version                          = "1.32.2-do.0"
  vpc_uuid                         = digitalocean_vpc.primary.id
  ha                               = true
  destroy_all_associated_resources = true
  registry_integration             = true
  node_pool {
    name       = "${var.app_name}-${var.primary_region}-default"
    size       = var.k8s_worker_size
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 4
    tags       = [var.app_name]
  }
}

resource "digitalocean_kubernetes_cluster" "nyc1" {
  name                             = "${var.app_name}-${var.secondary_region}"
  region                           = var.secondary_region
  version                          = "1.32.2-do.0"
  vpc_uuid                         = digitalocean_vpc.secondary.id
  ha                               = true
  destroy_all_associated_resources = true
  registry_integration             = true
  node_pool {
    name       = "${var.app_name}-${var.secondary_region}-default"
    size       = var.k8s_worker_size
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 4
    tags       = [var.app_name]
  }
}

resource "digitalocean_project_resources" "kubernetes_cluster" {
  project = digitalocean_project.project.id
  resources = [
    digitalocean_kubernetes_cluster.primary.urn,
    digitalocean_kubernetes_cluster.nyc1.urn
  ]
}
