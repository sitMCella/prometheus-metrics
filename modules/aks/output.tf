output "vmss_name" {
  description = "The name of the Azure Virtual Machine Scale Set"
  value       = azurerm_kubernetes_cluster.kubernetes_cluster.default_node_pool[0].name
}
