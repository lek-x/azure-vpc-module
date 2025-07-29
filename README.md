# Azure VPC Module

This Terraform module creates a configurable Virtual Private Cloud (VPC) environment in Azure, including VNet, subnets, NAT Gateway, NSGs, and optionally route tables for fine-grained egress control.

## Features

- Creates a Virtual Network (VNet) with custom address space and DNS servers
- Creates multiple subnets with individual configurations
- Creates Network Security Groups (NSG) with custom security rules
- Associates NSGs to corresponding subnets
- Optionally associates subnets with a NAT Gateway for outbound internet access
- Optionally attaches route tables to subnets for advanced routing scenarios

## Requirements

- Terraform >= 1.9.8
- AzureRM provider >= 3.x

## Usage

```hcl
module "azure-vpc" {
  source  = "git::https://github.com/lek-x/azure-vpc-module.git"

  subscription_id     = "your_current_subscription_id"
  resource_group_name = "your_current_resource_group"
  location            = "your_azure_region"

  vnet_cfg = {
    name             = "vnet1"
    address_prefixes = ["10.0.0.0/16"]
    dns_servers      = ["8.8.8.8", "1.1.1.1"]
    tags = {
      environment = "dev"
    }

    subnets = [
      {
        name                             = "subnet1"
        address_prefixes                 = ["10.0.1.0/24"]
        default_outbound_access_enabled  = true
        private_endpoint_network_policies = "Enabled"
        enable_nat_gateway               = true
        tags = {
          network = "pub"
        }
        security_rules = [
          {
            name                       = "allow-ssh"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "22"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          },
          {
            name                       = "allow-https"
            priority                   = 101
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          }
        ]
      },
      {
        name                             = "subnet2"
        address_prefixes                 = ["10.0.2.0/24"]
        default_outbound_access_enabled  = false  # disables default outbound to force NAT routing
        private_endpoint_network_policies = "Enabled"
        enable_nat_gateway               = true
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
        routes = [
          {
            name            = "default"
            address_prefix  = "0.0.0.0/0"
            next_hop_type   = "Internet"
          }
        ]
      }
    ]
  }
}
```

## Notes
enable_nat_gateway must be true for subnets that require outbound internet access through a NAT Gateway.

When default_outbound_access_enabled is set to false, a custom route to the Internet or NVA is required.

NAT Gateway and Public IP use Standard SKU to support zone redundancy.

NSGs and route tables are created only if corresponding configurations are specified in the subnet block.

## Outputs
You may optionally expose outputs like:

Virtual Network ID

Subnet IDs

NAT Gateway ID

NSG IDs