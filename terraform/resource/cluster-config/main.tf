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
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
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

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
}

data "http" "ingress_nginx_values" {
  url = "https://raw.githubusercontent.com/digitalocean/marketplace-kubernetes/master/stacks/ingress-nginx/values.yml"
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"
  values = [
    data.http.ingress_nginx_values.response_body
  ]
  set = [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-name"
      value = "${var.app_name}-${var.region}"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-enable-proxy-protocol"
      value = "true"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-tls-passthrough"
      value = "true"
    },
    {
      name  = "controller.config.use-proxy-protocol"
      value = "true"
    }
  ]
}

resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      name = "cert-manager"
    }
  }
}

data "http" "cert_manager_values" {
  url = "https://raw.githubusercontent.com/digitalocean/marketplace-kubernetes/master/stacks/cert-manager/values.yml"
}


resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.13.3"
  values = [
    data.http.cert_manager_values.response_body
  ]
}


resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.app_name
    labels = {
      name = var.app_name
    }
  }
}

resource "helm_release" "cert_manager_issuer" {
  depends_on = [
    helm_release.cert_manager
  ]
  name       = "cert-manager-letsencrypt-issuer"
  namespace  = kubernetes_namespace_v1.app.metadata[0].name
  chart      = "${path.module}/cert-manager-letsencrypt-issuer"
  set = [
    {
      name  = "acmeEmail"
      value = var.letsencrypt_email
    }
  ]
}


data "digitalocean_database_cluster" "invincible_app" {
  name = var.db_cluster_name
}

data "digitalocean_database_replica" "invincible_app_replica" {
  name  = var.db_replica_name
  cluster_id = data.digitalocean_database_cluster.invincible_app.id
}

data "digitalocean_database_ca" "invincible_app" {
  cluster_id = data.digitalocean_database_cluster.invincible_app.id
}


resource "kubernetes_secret_v1" "invincible_app_db" {
  metadata {
    name = "${var.app_name}-db"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels = {
      name = "${var.app_name}-db"
    }
  }
  data = {
    "USER": data.digitalocean_database_cluster.invincible_app.user
    "PASSWORD": data.digitalocean_database_cluster.invincible_app.password
    "PRIMARY_HOST": data.digitalocean_database_cluster.invincible_app.private_host
    "SECONDARY_HOST": data.digitalocean_database_replica.invincible_app_replica.private_host
    "PORT": data.digitalocean_database_cluster.invincible_app.port
    "DB_NAME": data.digitalocean_database_cluster.invincible_app.database
    "CA_CERT": data.digitalocean_database_ca.invincible_app.certificate
  }
}
