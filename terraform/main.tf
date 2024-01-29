terraform {
  backend "azurerm" {}
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

locals {
  sas    = jsondecode(file("./sas.json"))
  acls   = jsondecode(file("./acls.json"))
  apikeys    = jsondecode(file("./apikeys.json"))
  topics = jsondecode(file("./topics.json"))
  schemas    = jsondecode(file("./schemas.json"))
}

locals {
  sas_with_name = [ for sa in local.sas.sas : sa if sa.name != "" ]
}

module "sa" {
  for_each = { for sa in local.sas_with_name : sa.name => sa }
  source   = "./modules/sa"
  sa       = each.value
}

locals {
  apikeys_with_principals = [ for apikey in local.apikeys.apikeys.kafka : apikey if apikey.principal != "" ]
}

module "apikey_kafka" {
  for_each = { for apikey in local.apikeys_with_principals : apikey.principal => apikey }
  source   = "./modules/apikey"
  env_id   = var.confluent_environment
  kafka_id = var.confluent_kafka_cluster
  apikey   = each.value
}

locals {
  acls_with_principals = [ for acl in local.acls.acls : acl if acl.principal != "" ]
}

module "acl" {
  for_each        = { for acl in local.acls_with_principals : format("%s/%s/%s/%s/%#v/%s/%s", acl.principal, acl.resource_type, acl.resource_name, acl.operation, acl.host, acl.pattern_type, acl.permission) => acl }
  source          = "./modules/acl"
  env_id          = var.confluent_environment
  kafka_id        = var.confluent_kafka_cluster
  principal       = each.value.principal
  resource_type   = each.value.resource_type
  resource_name   = each.value.resource_name
  operation       = each.value.operation
  host            = each.value.host
  pattern_type    = each.value.pattern_type
  permission      = each.value.permission
  admin_sa = {
    api_key    = var.kafka_api_key
    api_secret = var.kafka_api_secret
  }
}

locals {
  topics_with_names = [ for topic in local.topics.topics : topic if topic.name != "" ]
}

module "topic" {
  for_each = { for topic in local.topics_with_names : topic.name => topic }
  source   = "./modules/topic"
  env_id   = var.confluent_environment
  kafka_id = var.confluent_kafka_cluster
  topic    = each.value
  admin_sa = {
    api_key    = var.kafka_api_key
    api_secret = var.kafka_api_secret
  }
}

locals {
  sr_apikeys_with_principals = [ for apikey in local.apikeys.apikeys.schema_registry : apikey if apikey.principal != "" ]
}

module "apikey_schema_registry" {
  for_each = { for apikey in local.sr_apikeys_with_principals : apikey.principal => apikey }
  source   = "./modules/sr-apikey"
  env_id   = var.confluent_environment
  schema_id = var.confluent_schema_registry
  apikey   = each.value
}

locals {
  schemas_with_subject = [ for schema in local.schemas.schemas : schema if schema.subject != "" ]
}

module "schema" {
  for_each = { for schema in local.schemas_with_subject : schema.subject => schema }
  source   = "./modules/schema"
  env_id   = var.confluent_environment
  schema_id = var.confluent_schema_registry
  schema    = each.value
  admin_sa = {
    api_key    = var.schema_registry_api_key
    api_secret = var.schema_registry_api_secret
  }
}
