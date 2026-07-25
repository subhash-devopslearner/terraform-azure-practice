terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # 🚀 REMOTE STATE BACKEND: Tests reading/writing state in Azure Blob Storage
  backend "azurerm" {
    resource_group_name  = "subhash-mgmt-rg"
    storage_account_name = "subhashtfstate24547" # <-- REPLACE THIS VALUE
    container_name       = "tfstate"
    key                  = "hello-world.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# 1. Test Resource Group
resource "azurerm_resource_group" "hello_rg" {
  name     = "subhash-helloworld-rg"
  location = "East US"
}

# 2. Test Container Group running public NGINX Hello World
resource "azurerm_container_group" "hello_aci" {
  name                = "subhash-helloworld-aci"
  location            = azurerm_resource_group.hello_rg.location
  resource_group_name = azurerm_resource_group.hello_rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"

  container {
    name   = "hello-world-container"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}

# Output the public IP to prove deployment succeeded
output "container_public_ip" {
  value       = "http://${azurerm_container_group.hello_aci.ip_address}"
  description = "Access your Hello World app here"
}