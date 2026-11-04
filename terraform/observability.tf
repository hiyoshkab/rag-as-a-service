resource "azurerm_log_analytics_workspace" "aks_laws" {
  name                = "${random_pet.azurerm_kubernetes_cluster_name.id}-laws"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

