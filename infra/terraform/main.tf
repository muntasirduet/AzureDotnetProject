data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  name_prefix                = lower("${var.project_name}-${var.environment}-${random_string.suffix.result}")
  resource_group_name        = "rg-${local.name_prefix}"
  app_service_plan_name      = "asp-${local.name_prefix}"
  web_app_name               = "app-${local.name_prefix}"
  acr_name                   = substr(replace("acr${var.project_name}${var.environment}${random_string.suffix.result}", "-", ""), 0, 50)
  key_vault_name             = substr(replace("kv-${local.name_prefix}", "-", ""), 0, 24)
  log_analytics_workspace    = "law-${local.name_prefix}"
  app_insights_name          = "appi-${local.name_prefix}"
  postgres_server_name       = "pg-${local.name_prefix}"
  postgres_database_name     = "taskapidb"
  postgres_admin_password    = random_password.postgres_admin.result
  postgres_connection_string = "Host=${local.postgres_server_name}.postgres.database.azure.com;Port=5432;Database=${local.postgres_database_name};Username=${var.postgres_admin_username};Password=${local.postgres_admin_password};Ssl Mode=Require;Trust Server Certificate=true"
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.log_analytics_workspace
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_service_plan" "main" {
  name                = local.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = var.tags
}

resource "azurerm_linux_web_app" "main" {
  name                = local.web_app_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on         = true
    health_check_path = "/health"

    application_stack {
      docker_image_name   = "${var.container_image_name}:${var.container_image_tag}"
      docker_registry_url = "https://${azurerm_container_registry.main.login_server}"
    }
  }

  app_settings = {
    "ASPNETCORE_URLS"                       = "http://+:8080"
    "WEBSITES_PORT"                         = "8080"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "ConnectionStrings__DefaultConnection"  = var.create_postgres ? "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.postgres_connection[0].versionless_id})" : ""
    "Jwt__Issuer"                           = "TaskApi"
    "Jwt__Audience"                         = "TaskApiClients"
    "Jwt__Secret"                           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.jwt_secret.versionless_id})"
    "DemoUser__Username"                    = var.demo_username
    "DemoUser__Password"                    = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.demo_password.versionless_id})"
    "DOCKER_ENABLE_CI"                      = "true"
  }
}

resource "azurerm_role_assignment" "webapp_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

resource "random_password" "postgres_admin" {
  length           = 24
  special          = true
  override_special = "_-!@#%^&*()"
}

resource "azurerm_postgresql_flexible_server" "main" {
  count               = var.create_postgres ? 1 : 0
  name                = local.postgres_server_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  administrator_login    = var.postgres_admin_username
  administrator_password = local.postgres_admin_password

  version                       = "16"
  sku_name                      = var.postgres_sku_name
  storage_mb                    = 32768
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = true

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  count     = var.create_postgres ? 1 : 0
  name      = local.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.main[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  count            = var.create_postgres ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_key_vault" "main" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  enable_rbac_authorization     = false
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

resource "azurerm_key_vault_access_policy" "webapp" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.main.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "demo_password" {
  name         = "demo-user-password"
  value        = var.demo_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "postgres_connection" {
  count        = var.create_postgres ? 1 : 0
  name         = "postgres-connection"
  value        = local.postgres_connection_string
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.current_user,
    azurerm_postgresql_flexible_server_database.main
  ]
}
