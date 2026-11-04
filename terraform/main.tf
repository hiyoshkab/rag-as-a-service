# Generate random resource group name
data "azurerm_client_config" "current" {}

resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

resource "random_pet" "azurerm_kubernetes_cluster_name" {
  prefix = "cluster"
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

resource "azurerm_user_assigned_identity" "aks_control_plane" {
  location            = azurerm_resource_group.rg.location
  name                = "${random_pet.azurerm_kubernetes_cluster_name.id}-identity"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "random_uuid" "aks_subnet_role_assignment" {}

resource "azurerm_kubernetes_cluster" "aks" {
  location            = azurerm_resource_group.rg.location
  name                = random_pet.azurerm_kubernetes_cluster_name.id
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix.id
  sku_tier            = var.aks_sku_tier

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_laws.id
  }

  monitor_metrics {
    annotations_allowed = "prometheus.io/scrape,prometheus.io/path,prometheus.io/port"
    labels_allowed = null
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_control_plane.id]
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = true

  default_node_pool {
    name           = "agentpool"
    vm_size        = var.node_sku
    node_count     = var.node_count
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = var.aks_pod_cidr
    service_cidr        = var.aks_service_cidr
    dns_service_ip      = var.aks_dns_service_ip
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  depends_on = [
    azurerm_role_assignment.aks_subnet_network_contributor
  ]
}

resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  name                 = random_uuid.aks_subnet_role_assignment.result
  scope                = azurerm_subnet.aks_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_control_plane.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "aks_cluster_admin" {
  name                 = random_uuid.aks_cluster_admin_role_assignment.result
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.aks_admin_group_object_id
  principal_type       = var.aks_admin_group_principal_type
}

resource "random_uuid" "aks_cluster_admin_role_assignment" {}

resource "azurerm_role_assignment" "github_actions_aks_cluster_user" {
  name                 = random_uuid.github_actions_aks_cluster_user_role_assignment.result
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.gha_service_principal_object_id
  principal_type       = "ServicePrincipal"
}

resource "random_uuid" "github_actions_aks_cluster_user_role_assignment" {}

resource "azurerm_role_assignment" "github_actions_aks_namespace_writer" {
  name                 = random_uuid.github_actions_aks_namespace_writer_role_assignment.result
  scope                = "${azurerm_kubernetes_cluster.aks.id}/namespaces/raas"
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = var.gha_service_principal_object_id
  principal_type       = "ServicePrincipal"
}

resource "random_uuid" "github_actions_aks_namespace_writer_role_assignment" {}

resource "azurerm_user_assigned_identity" "app" {
  location            = azurerm_resource_group.rg.location
  name                = var.app_identity_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_federated_identity_credential" "app" {
  name                      = "${var.app_identity_name}-federation"
  user_assigned_identity_id = azurerm_user_assigned_identity.app.id
  issuer                    = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.app_namespace}:${var.app_service_account_name}"
  audience                  = ["api://AzureADTokenExchange"]
}