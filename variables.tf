variable "existing_rg_name" {
  description = "Use the existing resource group"
  type        = string
  default     = "Azuredevops"
}

# Networking
variable "vnet_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.40.1.0/24"
}

# Scale & VM basics
variable "vm_count" {
  type    = number
  default = 2
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key (.pub)"
  type        = string
  # Windows path uses forward slashes for Terraform
  default     = "C:/Users/jrob8/.ssh/id_rsa.pub"
}

# Packer managed image (must match what you built)
variable "packer_image_name" {
  type    = string
  default = "udacityWebImage"
}

variable "packer_image_rg" {
  type    = string
  default = "Azuredevops"
}
