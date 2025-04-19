variable "redes" {
  type = list(object({
    name                = string
    vpc_cidr            = string
    public_subnet_cidr  = string
    private_subnet_cidr = string
    region              = string
    az                  = string
    enable_vgw          = bool
    enable_tgw          = bool
  }))
}

variable "peerings" {
  type = list(object({
    requester = string
    accepter  = string
  }))
  default = []
}

variable "redes_lookup" {
  type = map(object({
    vpc_cidr = string
    public_subnet_cidr = string
    private_subnet_cidr = string
    region = string
    az = string
    enable_vgw = bool
    enable_tgw = bool
  }))
}

variable "routes" {
  description = "Lista de rotas customizadas"
  type = list(object({
    vpc_name           = string
    route_table_type   = string
    destination_cidr   = string
    target_type        = string
    target_value       = string
  }))
}