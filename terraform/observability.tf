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

resource "azurerm_monitor_data_collection_rule" "aks_container_insights" {
  name                = "${random_pet.azurerm_kubernetes_cluster_name.id}-container-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  destinations {
    log_analytics {
      name                  = "container-insights-workspace"
      workspace_resource_id = azurerm_log_analytics_workspace.aks_laws.id
    }
  }

  data_sources {
    extension {
      name           = "container-insights-extension"
      extension_name = "ContainerInsights"
      streams = [
        "Microsoft-ContainerLog",
        "Microsoft-ContainerLogV2",
        "Microsoft-KubeEvents",
        "Microsoft-KubePodInventory",
        "Microsoft-KubeNodeInventory",
        "Microsoft-KubePVInventory",
        "Microsoft-KubeServices",
        "Microsoft-KubeMonAgentEvents",
        "Microsoft-InsightsMetrics",
        "Microsoft-ContainerInventory",
        "Microsoft-ContainerNodeInventory",
        "Microsoft-Perf",
      ]
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval               = "1m"
          namespaceFilteringMode = "Off"
          namespaces             = []
          enableContainerLogV2   = true
        }
      })
    }
  }

  data_flow {
    streams = [
      "Microsoft-ContainerLog",
      "Microsoft-ContainerLogV2",
      "Microsoft-KubeEvents",
      "Microsoft-KubePodInventory",
      "Microsoft-KubeNodeInventory",
      "Microsoft-KubePVInventory",
      "Microsoft-KubeServices",
      "Microsoft-KubeMonAgentEvents",
      "Microsoft-InsightsMetrics",
      "Microsoft-ContainerInventory",
      "Microsoft-ContainerNodeInventory",
      "Microsoft-Perf",
    ]
    destinations = ["container-insights-workspace"]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "aks_container_insights" {
  name                    = "container-insights"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.aks_container_insights.id
  description             = "Associates the Container Insights DCR with AKS."
}

resource "azurerm_monitor_data_collection_rule" "aks_prometheus" {
  name                = "${random_pet.azurerm_kubernetes_cluster_name.id}-prom"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  destinations {
    monitor_account {
      name               = "prometheus-destination"
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
    destinations = ["prometheus-destination"]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "aks_prometheus" {
  name                    = "prometheus-forwarder"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.aks_prometheus.id
  description             = "Associates the managed Prometheus DCR with AKS."
}

resource "azurerm_dashboard_grafana" "aks_grafana" {
  name                  = "${random_pet.azurerm_kubernetes_cluster_name.id}-gr"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  grafana_major_version = "13"

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.aks_monitor.id
  }
}
