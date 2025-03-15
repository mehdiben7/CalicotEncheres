provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-dev-calicot-cc-${var.code_identification}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "snet_web" {
  name                 = "snet-dev-web-cc-${var.code_identification}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.snet_web_address_prefix
}

resource "azurerm_subnet" "snet_db" {
  name                 = "snet-dev-db-cc-${var.code_identification}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.snet_db_address_prefix
}

# Groupe de sécurité réseau pour le sous-réseau web (HTTP & HTTPS autorisés)
resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-dev-web-cc-${var.code_identification}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "Allow-HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg_web.name
}

resource "azurerm_network_security_rule" "allow_https" {
  name                        = "Allow-HTTPS"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg_web.name
}

resource "azurerm_subnet_network_security_group_association" "snet_web_nsg" {
  subnet_id                 = azurerm_subnet.snet_web.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

# Groupe de sécurité réseau pour le sous-réseau DB (aucun accès externe)
resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-dev-db-cc-${var.code_identification}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "snet_db_nsg" {
  subnet_id                 = azurerm_subnet.snet_db.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}