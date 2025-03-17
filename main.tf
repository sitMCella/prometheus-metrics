locals {
  tags = {
    environment = var.environment
  }
}

resource "azurerm_resource_group" "resource_group" {
  name     = "rg-${var.workload_name}-${var.environment}-${var.location_abbreviation}-001"
  location = var.location
}

module "virtual_network" {
  source = "./modules/network"

  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  location_abbreviation = var.location_abbreviation
  environment           = var.environment
  tags                  = local.tags
}

module "kubernetes_cluster" {
  source = "./modules/aks"

  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  location_abbreviation = var.location_abbreviation
  environment           = var.environment
  dns_prefix            = "${var.workload_name}${var.environment}${var.location_abbreviation}"
  vnet_subnet_id        = module.virtual_network.subnet_aks_id
  authorized_ip_ranges  = var.allowed_public_ip_address_ranges
  tags                  = local.tags
}
