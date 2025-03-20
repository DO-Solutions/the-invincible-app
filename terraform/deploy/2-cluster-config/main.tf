module "primary_k8s_cluster" {
  source = "../../resource/cluster-config"
  app_name = var.app_name
  region = var.primary_region
  db_cluster_name = "${var.app_name}-${var.primary_region}"
  db_replica_name = "${var.app_name}-${var.secondary_region}"
}

module "secondary_k8s_cluster" {
  source = "../../resource/cluster-config"
  app_name = var.app_name
  region = var.secondary_region
  db_cluster_name = "${var.app_name}-${var.primary_region}"
  db_replica_name = "${var.app_name}-${var.secondary_region}"
}
