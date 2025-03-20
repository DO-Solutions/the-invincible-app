terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
  }
}


data "digitalocean_kubernetes_cluster" "invincible_app" {
  # Param
  name = "${var.app_name}-${var.region}"
}

provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.invincible_app.endpoint
  token = data.digitalocean_kubernetes_cluster.invincible_app.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.invincible_app.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes = {
    host  = data.digitalocean_kubernetes_cluster.invincible_app.endpoint
    token = data.digitalocean_kubernetes_cluster.invincible_app.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.invincible_app.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "helm_release" "app" {
  name       = var.app_name
  namespace  = var.app_name
  chart      = "${path.module}/../../../helm/invincible-app"

  set = [
    {
      name  = "primary"
      value = var.primary
    },
    {
      name  = "domain"
      value = var.domain
    },
    {
      name  = "image.repository"
      value = var.image_repository
    }
  ]
}
