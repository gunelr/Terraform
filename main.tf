terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "9b3f20b6-8feb-4957-97ea-efc62cc6eabc"
}
//Create "Resource Group"
resource "azurerm_resource_group" "mctrrg" {
  name     = "mctrrg"
  location = var.location
}
//Create "VNET" and "SUBNET"
resource "azurerm_virtual_network" "mctrvnet" {
  name                = "mctrvnet"
  address_space       = ["10.50.0.0/16"]
  location            = var.location
  resource_group_name = "mctrrg"
}

resource "azurerm_subnet" "mctrsub" {
  name                 = "mctrsub"
  resource_group_name  = "mctrrg"
  virtual_network_name = azurerm_virtual_network.mctrvnet.name
  address_prefixes     = ["10.50.1.0/24"]
}

resource "azurerm_public_ip" "mctrpip" {
  name                = "mctrpip"
  location            = var.location
  resource_group_name = "mctrrg"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}


//Create "Network Interface" and "IP resource"

resource "azurerm_network_interface" "mctrnic" {
  name                = "mctrnic"
  location            = var.location
  resource_group_name = "mctrrg"


  ip_configuration {
    name                          = "mctrip"
    subnet_id                     = azurerm_subnet.mctrsub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mctrpip.id
  }
}

// Create VM and Enable autoshutdown

resource "azurerm_windows_virtual_machine" "mctrvm" {
  name                  = "mctrvm"
  location              = var.location
  resource_group_name   = "mctrrg"
  network_interface_ids = [azurerm_network_interface.mctrnic.id]
  size                  = "standard_b1s"

  admin_username = "mirceyhun"
  admin_password = var.pass

  source_image_reference {
    publisher = "microsoftwindowsserver"
    offer     = "windowsserver"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
resource "azurerm_dev_test_global_vm_shutdown_schedule" "mctrvm" {
  virtual_machine_id = azurerm_windows_virtual_machine.mctrvm.id
  location           = var.location
  enabled            = true

  daily_recurrence_time = "1100"
  timezone              = "Azerbaijan Standard Time"

  notification_settings {
    enabled = false
  }
}