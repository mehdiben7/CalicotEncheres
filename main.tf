terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # Use a version that supports azurerm_sql_server and azurerm_sql_database
    }
  }
}

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

resource "azurerm_network_security_group" "nsg_db" {
  name                = "nsg-dev-db-cc-${var.code_identification}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "snet_db_nsg" {
  subnet_id                 = azurerm_subnet.snet_db.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-dev-calicot-cc-${var.code_identification}"
  location = var.location
}

# Azure App Service Plan
resource "azurerm_app_service_plan" "app_plan" {
  name                = "plan-calicot-dev-${var.code_identification}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Windows"  # Modifier en "Linux" si besoin

  sku {
    tier     = "Standard"
    size     = "S1"
  }

  maximum_elastic_worker_count = 2  # Permet l’auto-scaling
}

resource "azurerm_app_service" "app" {
  name                = "app-calicot-dev-${var.code_identification}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.app_plan.id

  site_config {
    always_on          = true
    min_tls_version    = "1.2"
    http2_enabled      = true
    ftps_state         = "Disabled"
    app_command_line   = ""

    ip_restriction {
      action                    = "Allow"
      ip_address                 = "0.0.0.0/0" # Permettre tout le trafic (à restreindre si nécessaire)
      priority                   = 100
      name                       = "AllowAll"
    }

    cors {
      support_credentials = false
      allowed_origins     = ["*"]
    }
  }

  https_only = true

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "ImageUrl" = "https://stcalicotprod000.blob.core.windows.net/images/"
  }
}

# 1. Créer un serveur SQL Azure
resource "azurerm_sql_server" "sql_server" {
  name                         = "sqlsrv-calicot-dev-${var.code_identification}"  # Nom du serveur SQL
  resource_group_name          = azurerm_resource_group.rg.name  # Doit être défini auparavant (déclaration du groupe de ressources)
  location                     = var.location
  administrator_login          = "sqladmin"  # Utilisateur administrateur
  administrator_login_password = "Polytechnique2025"  # Mot de passe administrateur (utiliser un mot de passe sécurisé)
  version = "12.0"

  tags = {
    environment = "development"
  }
}

# 2. Créer la base de données SQL Azure
resource "azurerm_sql_database" "sql_db" {
  name                = "sqldb-calicot-dev-${var.code_identification}"  # Nom de la base de données
  resource_group_name = azurerm_resource_group.rg.name  # Doit être défini auparavant
  location            = var.location
  server_name         = azurerm_sql_server.sql_server.name  # Référence au serveur SQL créé précédemment

  tags = {
    environment = "development"
  }
}

# Auto-scaling
resource "azurerm_monitor_autoscale_setting" "app_autoscale" {
  name                = "autoscale-app-calicot-dev-${var.code_identification}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  target_resource_id  = azurerm_app_service_plan.app_plan.id

  profile {
    name = "default"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.app_plan.id
        operator           = "GreaterThan"
        threshold          = 70
        time_grain         = "PT1M"
        time_window = "PT5M"
        statistic          = "Average"
        time_aggregation   = "Average"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.app_plan.id
        operator           = "LessThan"
        threshold          = 70
        time_grain         = "PT1M"
        time_window        = "PT5M"
        statistic          = "Average"
        time_aggregation   = "Average"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }
  }
}

resource "azurerm_key_vault" "kv_calicot_dev" {
  name                        = "kv-calicot-dev-${var.code_identification}"
  location                    = "Canada Central"
  resource_group_name         = var.resource_group_name
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  tenant_id       = var.tenant_id
  enable_rbac_authorization = true
}
resource "azurerm_key_vault_access_policy" "calicot_ap" {
  key_vault_id = azurerm_key_vault.kv_calicot_dev.id
  tenant_id    = var.tenant_id
  object_id    = var.client_id

  key_permissions = [
    "Get", "List"
  ]

  secret_permissions = [
    "Get", "List"
  ]
}
