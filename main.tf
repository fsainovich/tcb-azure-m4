#Create Resource Group
resource "azurerm_resource_group" "TCB-AZURE-M4" {
  name     = var.RG_NAME
  location = var.AZURE_LOCATION
}

#Create VNET
resource "azurerm_virtual_network" "MAIN" {
  name                = "VNET-MAIN"
  address_space       = [var.VNET_CIDR]
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION
}

#Create Internal Subnet
resource "azurerm_subnet" "SUBNET-INTERNAL" {
  name                  = "SUBNET-INTERNAL"
  resource_group_name   = var.RG_NAME
  virtual_network_name  = azurerm_virtual_network.MAIN.name
  address_prefixes      = [var.SUBNET_INTERNAL_CIDR]
}

#Create VNIC for WebServer
resource "azurerm_network_interface" "VNIC1" {
  name                = "VNIC1"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION

  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.SUBNET-INTERNAL.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create WebServer
resource "azurerm_virtual_machine" "WebServer" {
  name                  = "Internal-WebServer"
  resource_group_name   = var.RG_NAME
  location              = var.AZURE_LOCATION
  network_interface_ids = [azurerm_network_interface.VNIC1.id]
  vm_size               = "Standard_B1s"
  
  delete_os_disk_on_termination     = true
  delete_data_disks_on_termination  = true  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name   = "webserver"
    admin_username  = "azureuser"
    custom_data     = filebase64("webserver.sh")
    admin_password  = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false        
    ssh_keys {       
        key_data  =  file("key.pub")    
        path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }
}

#Create VNIC for Client Machine
resource "azurerm_network_interface" "VNIC2" {
  name                = "VNIC2"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.SUBNET-INTERNAL.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create Client Machine
resource "azurerm_virtual_machine" "Client" {
  name                  = "Internal-Client"
  resource_group_name   = var.RG_NAME
  location              = var.AZURE_LOCATION
  network_interface_ids = [azurerm_network_interface.VNIC2.id]
  vm_size               = "Standard_B2s"
  
  delete_os_disk_on_termination     = true
  delete_data_disks_on_termination  = true  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name   = "client"
    admin_username  = "azureuser"
    custom_data     = filebase64("client.sh") 
    admin_password  = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false        
    ssh_keys {       
        key_data  =  file("key.pub")    
        path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }
}

# Create VPN Gateway Subnet
resource "azurerm_subnet" "SUBNET-Gateway" {
  name                  = "GatewaySubnet" # mandatory name -do not rename-
  address_prefixes      = [var.SUBNET_VPNDW_CIDR]
  virtual_network_name  = azurerm_virtual_network.MAIN.name
  resource_group_name   = var.RG_NAME
}

#Create Public IP for VPN-GW
resource "azurerm_public_ip" "gateway-ip" {
  name                = "vpn-gw-ip"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION
  allocation_method   = "Dynamic"
}

#Create VPN-GW
resource "azurerm_virtual_network_gateway" "vpn-gateway" {
  depends_on          = [azurerm_subnet.SUBNET-Gateway,azurerm_public_ip.gateway-ip]
  name                = "VPN_GW"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"
  ip_configuration {
    name                          = "VPN-vnet"
    public_ip_address_id          = azurerm_public_ip.gateway-ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.SUBNET-Gateway.id
  }
  vpn_client_configuration {
    address_space         = [var.VPN_CLIENT_ADDRESS]
    vpn_client_protocols  = ["SSTP","IkeV2"]
    root_certificate {
      name              = "VPNROOT"
      public_cert_data  = file("rootcertificate.txt")
    }
  }
}

# Create Azure Firewall Subnet
resource "azurerm_subnet" "AzureFirewallSubnet" {
  name                  = "AzureFirewallSubnet" # mandatory name -do not rename-
  address_prefixes      = [var.SUBNET_FW_CIDR]
  virtual_network_name  = azurerm_virtual_network.MAIN.name
  resource_group_name   = var.RG_NAME
}

#Create Public IP for FW
resource "azurerm_public_ip" "azure_firewall_pip" {
  name                  = "FW-PIP"
  resource_group_name   = var.RG_NAME
  location              = var.AZURE_LOCATION
  allocation_method     = "Static"
  sku                   = "Standard"
}

# Create the Azure Firewall
resource "azurerm_firewall" "azure_firewall" {
  depends_on            = [azurerm_public_ip.azure_firewall_pip, azurerm_virtual_machine.Client]
  name                  = "Azure-Firewall"
  resource_group_name   = var.RG_NAME
  location              = var.AZURE_LOCATION
  ip_configuration {
    name                  = "Azure-Firewall-IP-Config"
    subnet_id             = azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id  = azurerm_public_ip.azure_firewall_pip.id
  }
}

# Create a Azure Firewall Application Rule for Websites
resource "azurerm_firewall_application_rule_collection" "allow-websites" {
  name                = "Allow-Websites"
  azure_firewall_name = azurerm_firewall.azure_firewall.name
  resource_group_name = var.RG_NAME
  priority            = 1001
  action              = "Allow"
  rule {
    name              = "Facebook"
    source_addresses  = ["10.0.1.0/24"]
    target_fqdns      = ["*.facebook.com","*.fbcdn.net","facebook.com"]
    protocol {
      port = "443"
      type = "Https"
    }
  }
  
  rule {
    name              = "Instagram"
    source_addresses  = ["10.0.1.0/24"]
    target_fqdns      = ["*.instagram.com","instagram.com"]
    protocol {
      port = "443"
      type = "Https"
    }
  }
}

#Create Routinf Table for internal subnet
resource "azurerm_route_table" "RT-INTERNAL" {
  name                          = "RT-INTERNAL"
  resource_group_name           = var.RG_NAME
  location                      = var.AZURE_LOCATION
  disable_bgp_route_propagation = false

  route {
    name                    = "Default"
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = azurerm_firewall.azure_firewall.ip_configuration[0].private_ip_address
  } 
}

#Assign RT to Internal Subnet
resource "azurerm_subnet_route_table_association" "RT-SUBNET" {
  subnet_id      = azurerm_subnet.SUBNET-INTERNAL.id
  route_table_id = azurerm_route_table.RT-INTERNAL.id
}