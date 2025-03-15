variable "subscription_id" {
  description = "ID de la souscription Azure"
  type        = string
}

variable "tenant_id" {
  description = "ID du tenant Azure AD"
  type        = string
}

variable "client_id" {
  description = "ID du service principal"
  type        = string
}

variable "client_secret" {
  description = "Secret du service principal"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Nom du groupe de ressources"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
  default     = "canadacentral"
}

variable "code_identification" {
  description = "8"
  type        = string
}

variable "vnet_address_space" {
  description = "Plage d'adresses du Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "snet_web_address_prefix" {
  description = "Plage d'adresses du sous-réseau Web"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "snet_db_address_prefix" {
  description = "Plage d'adresses du sous-réseau DB"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}
