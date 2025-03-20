terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}


resource "digitalocean_domain" "app_domain" {
  name = "${var.app_name}.${var.parent_domain}"
}

data "digitalocean_loadbalancer" "primary" {
  name = "${var.app_name}-${var.primary_region}"
}

resource "digitalocean_record" "primary_lb" {
  domain = digitalocean_domain.app_domain.id
  type   = "A"
  name   = var.primary_region
  value  = data.digitalocean_loadbalancer.primary.ip
  ttl    = 300
}

data "digitalocean_loadbalancer" "secondary" {
  name = "${var.app_name}-${var.secondary_region}"
}

resource "digitalocean_record" "secondary" {
  domain = digitalocean_domain.app_domain.id
  type   = "A"
  name   = var.secondary_region
  value  = data.digitalocean_loadbalancer.secondary.ip
  ttl    = 300
}

data "digitalocean_domain" "parent_domain" {
  name = var.parent_domain
}

resource "digitalocean_record" "ns_records" {
  count  = 3
  domain = data.digitalocean_domain.parent_domain.id
  type   = "NS"
  name   = var.app_name
  value  = "ns${count.index + 1}.digitalocean.com."
  ttl    = 86400
}

data "digitalocean_project" "app" {
  name = var.app_name
}


resource "digitalocean_loadbalancer" "glb" {
  name = "${var.app_name}-glb"
  type = "GLOBAL"
  # need to param project_id
  project_id = data.digitalocean_project.app.id
  target_load_balancer_ids = [
    data.digitalocean_loadbalancer.primary.id,
    data.digitalocean_loadbalancer.secondary.id
  ]
  domains {
      name       = digitalocean_domain.app_domain.name
      is_managed = true
  }
  glb_settings {
    target_protocol = "http"
    target_port = 80
    cdn {
      is_enabled = false
    }
  }
  healthcheck {
    port     = 80
    protocol = "http"
    path = "/health"
  }
}

resource "digitalocean_project_resources" "lbs" {
  project = data.digitalocean_project.app.id
  resources = [
    digitalocean_domain.app_domain.urn,
    data.digitalocean_loadbalancer.primary.urn,
    data.digitalocean_loadbalancer.secondary.urn,
  ]
}