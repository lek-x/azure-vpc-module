# data "azurerm_resource_group" "main" {
#   name     = var.resource_group_name
# }

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_cfg.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_cfg.address_prefixes
  dns_servers         = var.vnet_cfg.dns_servers

  tags = var.vnet_cfg.tags
}

resource "azurerm_network_security_group" "scgr" {
  for_each            = local.subnet_sec_map
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.security_rules != null ? each.value.security_rules : []
    iterator = rule
    content {
      name                       = rule.value.name
      priority                   = rule.value.priority
      direction                  = rule.value.direction
      access                     = rule.value.access
      protocol                   = rule.value.protocol
      source_port_range          = try(rule.value.source_port_range, "*")
      destination_port_range     = try(rule.value.destination_port_range, "*")
      source_address_prefix      = try(rule.value.source_address_prefix, "*")
      destination_address_prefix = try(rule.value.destination_address_prefix, "*")
    }
  }
}

resource "azurerm_nat_gateway" "ngw" {
  name                = "${var.vnet_cfg.name}-nat-ngw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
}

resource "azurerm_public_ip" "nat_ngw_ip" {
  name                = "${var.vnet_cfg.name}-nat-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.vnet_cfg.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.ngw.id
  public_ip_address_id = azurerm_public_ip.nat_ngw_ip.id
}


resource "azurerm_subnet_nat_gateway_association" "ngw_assoc" {
  for_each = {
    for subnet in var.vnet_cfg.subnets :
    subnet.name => subnet
    if try(subnet.enable_nat_gateway, false)
  }

  subnet_id      = azurerm_subnet.subnet[each.key].id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}

resource "azurerm_subnet" "subnet" {
  for_each = { for subnet in var.vnet_cfg.subnets : subnet.name => subnet }

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes

  service_endpoints = try(each.value.service_endpoints, null)

  private_endpoint_network_policies             = try(each.value.private_endpoint_network_policies, true)
  private_link_service_network_policies_enabled = true
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  for_each = local.subnet_sec_map

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.scgr[each.key].id
}


resource "azurerm_route_table" "rt" {
  for_each = {
    for subnet in var.vnet_cfg.subnets :
    subnet.name => subnet
    if try(length(subnet.routes), 0) > 0
  }

  name                = "${each.key}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = try(each.value.routes, [])
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = try(route.value.next_hop_in_ip_address, null)
    }
  }

  tags = var.vnet_cfg.tags
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each = {
    for subnet in var.vnet_cfg.subnets :
    subnet.name => subnet
    if try(length(subnet.routes), 0) > 0
  }

  subnet_id      = azurerm_subnet.subnet[each.key].id
  route_table_id = azurerm_route_table.rt[each.key].id
}
