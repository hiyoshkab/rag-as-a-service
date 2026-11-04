output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "foundry_endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
}

output "app_identity_client_id" {
  value = azurerm_user_assigned_identity.app.client_id
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.aks_laws.id
}

output "monitor_workspace_id" {
  value = azurerm_monitor_workspace.aks_monitor.id
}

output "grafana_endpoint" {
  value = azurerm_dashboard_grafana.aks_grafana.endpoint
}