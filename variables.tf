variable "project_id" {
  description = "Google Cloud Platform (GCP) Project ID."
  type        = string
  default     = "myapplication-348521"
}

variable "region" {
  description = "GCP region name."
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP zone name."
  type        = string
  default     = "europe-west1-b"
}

variable "service" {
  description = "GCP api service."
  type        = string
  default     = "compute.googleapis.com"
}

variable "name" {
  description = "Web server name."
  type        = string
  default     = "my-webserver"
}

variable "machine_type" {
  description = "GCP VM instance machine type."
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "GCP machine image"
  type        = string
  default     = "centos-7-v20210420"
}

variable "labels" {
  description = "List of labels to attach to the VM instance."
  type        = map
}
variable "tier" {
  description = "The tier for the master instance."
  type        = string
  default     = "db-n1-standard-1"
}
variable "activation_policy" {
  description = "The activation policy for the master instance. Can be either `ALWAYS`, `NEVER` or `ON_DEMAND`."
  type        = string
  default     = "ALWAYS"
}

variable "availability_type" {
  description = "The availability type for the master instance. Can be either `REGIONAL` or `null`."
  type        = string
  default     = "REGIONAL"
}