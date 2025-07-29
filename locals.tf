locals {
  subnet_sec_map = {

    for subnet in var.vnet_cfg.subnets :
    subnet.name => {
      security_rules = subnet.security_rules != null ? subnet.security_rules : null
    }
  }
}
