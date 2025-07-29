variable "subscription_id" {
  description = "The Azure subscription ID where the resources will be created."
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "The AZURE resource group the resources will be created."
  type        = string
  default     = "maingr"
}

variable "location" {
  description = "The AZURE resource group location"
  type        = string
  default     = "westeurope"
}

variable "vnet_cfg" {
  description = "The CIDR range for the VPC network."
  type = object({
    name             = string
    address_prefixes = list(string)
    dns_servers      = list(string)
    tags             = optional(map(string))
    subnets = list(object({
      name                              = string
      address_prefixes                  = list(string)
      default_outbound_access_enabled   = optional(bool, true)
      private_endpoint_network_policies = optional(string, "Enabled")
      enable_nat_gateway                = optional(bool, false)
      tags                              = optional(map(string))
      security_rules = optional(list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = optional(string, "*")
        destination_port_range     = optional(string, "*")
        source_address_prefix      = optional(string, "*")
        destination_address_prefix = optional(string, "*")
      })))
      routes = optional(list(object({
        name                   = string
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string)
      })))
    }))
  })
  default = {
    name             = "vnet1"
    address_prefixes = ["10.0.0.0/16"]
    dns_servers      = ["8.8.8.8", "1.1.1.1"]
    tags = {
      environment = "dev"
    }
    subnets = [
      {
        name                              = "subnet-public"
        address_prefixes                  = ["10.0.1.0/24"]
        default_outbound_access_enabled   = true
        private_endpoint_network_policies = "Enabled"
        enable_nat_gateway                = true
        security_rules = [
          {
            name                       = "allow-ssh"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_rang      = "22"
            source_address_prefix      = "*"
            destination_address_prefix = "*"

          },
          {
            name                   = "allow-https"
            priority               = 101
            direction              = "Inbound"
            access                 = "Allow"
            protocol               = "Tcp"
            source_port_range      = "*"
            destination_port_range = "443"
            source_address_prefix  = "*"
          destination_address_prefix = "*" }
        ]
        tags = {
          network = "pub"
        }
      },
      {
        name                              = "subnet-private"
        address_prefixes                  = ["10.0.2.0/24"]
        default_outbound_access_enabled   = true
        private_endpoint_network_policies = "Enabled"
        tags = {
          network = "priv"
        }
        security_rules = [
          {
            name                       = "allow-internal-ssh"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "22"
            source_address_prefix      = "10.0.0.0/16"
            destination_address_prefix = "*"
          }
        ]
    }]
  }
}
