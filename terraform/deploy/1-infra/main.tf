module "infra" {
  source = "../../resource/infra"
  app_name = var.app_name
  primary_region = var.primary_region
  secondary_region = var.secondary_region
  db_size = var.db_size
  k8s_worker_size = var.k8s_worker_size
}
