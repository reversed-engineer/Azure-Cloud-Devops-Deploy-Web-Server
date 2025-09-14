terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.existing_rg_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-web"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]
  tags = { env = "dev" }
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-web"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-web"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-VNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
  }

  security_rule {
    name                       = "Deny-Internet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }

  tags = { env = "dev" }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip_lb" {
  name                = "pip-web-lb"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = { env = "dev" }
}

resource "azurerm_lb" "lb" {
  name                = "lb-web"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "fe"
    public_ip_address_id = azurerm_public_ip.pip_lb.id
  }

  tags = { env = "dev" }
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "bepool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "http" {
  name            = "http"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_lb_rule" "http" {
  name                           = "http"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.http.id
}

resource "azurerm_availability_set" "aset" {
  name                = "aset-web"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  managed             = true
  tags                = { env = "dev" }
}

data "azurerm_image" "packer" {
  name                = var.packer_image_name
  resource_group_name = var.packer_image_rg
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "nic-web-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = { env = "dev" }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_to_bepool" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipcfg"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bepool.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.vm_count
  name                            = "vm-web-${count.index}"
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  size                            = var.vm_size
  availability_set_id             = azurerm_availability_set.aset.id
  network_interface_ids           = [azurerm_network_interface.nic[count.index].id]
  admin_username                  = var.admin_username
  disable_password_authentication = true
  source_image_id                 = data.azurerm_image.packer.id

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = { env = "dev" }
}

output "lb_public_ip" {
  value = azurerm_public_ip.pip_lb.ip_address
}
