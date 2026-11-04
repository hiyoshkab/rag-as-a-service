resource "azurerm_log_analytics_workspace" "aks_laws" {
  name                = "${random_pet.azurerm_kubernetes_cluster_name.id}-laws"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_workspace" "aks_monitor" {
  name                = "${random_pet.azurerm_kubernetes_cluster_name.id}-monitor"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_monitor_data_collection_rule" "aks_prometheus" {
  name                = "${random_pet.azurerm_kubernetes_cluster_name.id}-prom"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  destinations {
    azure_monitor_metrics {
      name = "azure-monitor-metrics"
    }
    monitor_account {
      name = "prometheus-destination"
      monitor_account_id = azurerm_monitor_workspace.aks_monitor.id
    }
  }

  data_sources {
    prometheus_forwarder {
      name    = "prometheus-forwarder"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations  = ["azure-monitor-metrics", "prometheus-destination"]
  }
}

resource "azurerm_dashboard_grafana" "aks_grafana" {
  name                = "${random_pet.azurerm_kubernetes_cluster_name.id}-grafana"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  grafana_major_version = "10"

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.aks_monitor.id
  }
}
