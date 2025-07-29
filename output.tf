output "vnet_subnet" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.subnet
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = azurerm_nat_gateway.ngw.id
}

output "public_ip_id" {
  description = "ID of the public IP associated with the NAT Gateway"
  value       = azurerm_public_ip.nat_ngw_ip.ip_address
}

output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value = {
    for k, v in azurerm_network_security_group.scgr : k => v.id
  }
}

output "route_table_ids" {
  description = "Map of route table names to their IDs (if defined)"
  value = {
    for k, v in azurerm_route_table.rt : k => v.id
  }
}
