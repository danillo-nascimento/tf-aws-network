locals {
  redes    = csvdecode(file("${path.module}/redes.csv"))
  peerings = csvdecode(file("${path.module}/peerings.csv"))
  routes   = csvdecode(file("${path.module}/routes.csv"))
}

module "network" {
  source        = "./modules/network"
  redes         = local.redes
  peerings      = local.peerings
  routes        = local.routes
  redes_lookup  = { for r in local.redes : r.name => r }
}