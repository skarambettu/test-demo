variable "project" {
  description = "Project to deploy resources for"
  type        = string
}

variable "project_env" {
  description = "Project environment to deploy resources for"
  type        = string
}

variable "confluent_cloud_api_key" {
  description = "Confluent cloud API Key"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent cloud API Secret"
  type        = string
}

variable "confluent_environment" {
  description = "Confluent cloud environment"
  type        = string
}

variable "confluent_kafka_cluster" {
  description = "Confluent cloud kafka cluster"
  type        = string
}
