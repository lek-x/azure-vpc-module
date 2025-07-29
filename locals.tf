locals {
  subnet_sec_map = {

    for subnet in var.vnet_cfg.subnets :
    subnet.name => {
      security_rules = subnet.security_rules != null ? subnet.security_rules : null
    }
  }
  subnets_with_nat_map = {
    for subnet in var.vnet_cfg.subnets :
    subnet.name => {
      enable_nat_gateway = subnet.enable_nat_gateway != null ? subnet.enable_nat_gateway : false
      tags               = subnet.tags != null ? subnet.tags : null
    }

  }
}
