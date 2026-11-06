resource "azurerm_resource_group" "foundry_rg" {
  name     = var.foundry_resource_group_name
  location = var.foundry_location
}

resource "azurerm_cognitive_account" "foundry" {
  name                          = var.foundry_name
  resource_group_name           = azurerm_resource_group.foundry_rg.name
  location                      = var.foundry_location
  kind                          = var.foundry_kind
  sku_name                      = var.foundry_sku_name
  custom_subdomain_name         = var.foundry_custom_subdomain_name
  local_auth_enabled            = false
  public_network_access_enabled = false
  project_management_enabled    = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_deployment" "foundry_model" {
  name                 = var.foundry_deployment_name
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = var.foundry_model_format
    name    = var.foundry_model_name
    version = var.foundry_model_version
  }

  sku {
    name     = var.foundry_deployment_sku_name
    capacity = var.foundry_deployment_capacity
  }
}

resource "random_uuid" "app_foundry_role_assignment" {}

resource "azurerm_role_assignment" "app_foundry_user" {
  name                 = random_uuid.app_foundry_role_assignment.result
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_private_endpoint" "foundry_private_endpoint" {
  name                = "foundry-pe"
  resource_group_name = azurerm_resource_group.foundry_rg.name
  location            = azurerm_virtual_network.aks_vnet.location
  subnet_id           = azurerm_subnet.foundry_subnet.id

  private_service_connection {
    name                           = "foundry-psc"
    private_connection_resource_id = azurerm_cognitive_account.foundry.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "foundry"
    private_dns_zone_ids = [azurerm_private_dns_zone.foundry_private_dns_zone.id]
  }
}

resource "azurerm_private_dns_zone" "foundry_private_dns_zone" {
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = azurerm_resource_group.foundry_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "foundry_private_dns_zone_link" {
  name                = "foundry-dns-link"
  private_dns_zone_id = azurerm_private_dns_zone.foundry_private_dns_zone.id
  virtual_network_id  = azurerm_virtual_network.aks_vnet.id
}
