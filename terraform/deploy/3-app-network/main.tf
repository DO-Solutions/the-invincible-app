module "network" {
  source = "../../resource/network"
  app_name = var.app_name
  parent_domain = var.parent_domain
  primary_region = var.primary_region
  secondary_region = var.secondary_region
}

module "primary_app" {
  source = "../../resource/app"
  app_name = var.app_name
  region = var.primary_region
  primary = "true"
  domain = "${var.app_name}.${var.parent_domain}"
  image_repository = var.image_repository
}

module "secondary_app" {
  source = "../../resource/app"
  app_name = var.app_name
  region = var.secondary_region
  primary = "false"
  domain = "${var.app_name}.${var.parent_domain}"
  image_repository = var.image_repository
}