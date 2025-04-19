locals {
  redes_lookup = {
    for rede in var.redes : rede.name => rede
  }
}

# VPC
resource "aws_vpc" "vpc" {
  for_each = { for rede in var.redes : rede.name => rede }
  cidr_block = each.value.vpc_cidr
  tags = { Name = "${each.key}" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  for_each = aws_vpc.vpc
  vpc_id = each.value.id
  tags = { Name = "${each.key}-igw" }
}

# Subnet Pública
resource "aws_subnet" "public_subnet" {
  for_each = { for rede in var.redes : rede.name => rede }
  vpc_id = aws_vpc.vpc[each.key].id
  cidr_block = each.value.public_subnet_cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = true
  tags = { Name = "${each.key}-public-subnet" }
}

# Route Table Pública
resource "aws_route_table" "public_rt" {
  for_each = aws_vpc.vpc
  vpc_id = each.value.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[each.key].id
  }
  tags = { Name = "${each.key}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt[each.key].id
}

# Subnet Privada
resource "aws_subnet" "private_subnet" {
  for_each = { for rede in var.redes : rede.name => rede }
  vpc_id = aws_vpc.vpc[each.key].id
  cidr_block = each.value.private_subnet_cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = false
  tags = { Name = "${each.key}-private-subnet" }
}

# Route Table Privada
resource "aws_route_table" "private_rt" {
  for_each = aws_vpc.vpc
  vpc_id   = each.value.id
  tags     = { Name = "${each.key}-private-rt" }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt[each.key].id
}

# Virtual Private Gateway (VGW)
resource "aws_vpn_gateway" "vgw" {
  for_each = { for rede in var.redes : rede.name => rede if rede.enable_vgw }
  vpc_id = aws_vpc.vpc[each.key].id
  tags = { Name = "${each.key}-vgw" }
}

# Transit Gateway (TGW)
resource "aws_ec2_transit_gateway" "tgw" {
  description = "TGW principal"
  tags        = { Name = "principal-tgw" }
}

# Transit Gateway VPC Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  for_each = { for rede in var.redes : rede.name => rede if rede.enable_tgw }
  subnet_ids         = [aws_subnet.private_subnet[each.key].id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc[each.key].id
  tags = { Name = "${each.key}-tgw-attachment" }
}

# VPC Peering Connections
resource "aws_vpc_peering_connection" "peerings" {
  for_each = {
    for p in var.peerings : "${p.requester}-${p.accepter}" => p
    if p.requester != p.accepter
  }

  vpc_id        = aws_vpc.vpc[each.value.requester].id
  peer_vpc_id   = aws_vpc.vpc[each.value.accepter].id
  auto_accept   = true  # funciona entre VPCs da mesma conta e região

  tags = {
    Name = "${each.value.requester}-to-${each.value.accepter}"
  }
}

# Rota na VPC requester apontando para a VPC accepter
resource "aws_route" "route_requester_to_accepter" {
  for_each = {
    for p in var.peerings : "${p.requester}-${p.accepter}" => p
    if p.requester != p.accepter
  }

  route_table_id         = aws_route_table.private_rt[each.value.requester].id
  destination_cidr_block = var.redes_lookup[each.value.accepter].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peerings[each.key].id
}

# Rota na VPC accepter apontando para a VPC requester
resource "aws_route" "route_accepter_to_requester" {
  for_each = {
    for p in var.peerings : "${p.requester}-${p.accepter}" => p
    if p.requester != p.accepter
  }

  route_table_id         = aws_route_table.private_rt[each.value.accepter].id
  destination_cidr_block = var.redes_lookup[each.value.requester].vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peerings[each.key].id
}

# Criação de rotas customizadas
resource "aws_route" "custom_routes" {
  for_each = {
    for r in var.routes : "${r.vpc_name}-${r.destination_cidr}" => r
  }

  route_table_id = lookup({
    public  = aws_route_table.public_rt,
    private = aws_route_table.private_rt
  }, each.value.route_table_type)[each.value.vpc_name].id

  destination_cidr_block = each.value.destination_cidr

  gateway_id = (
    each.value.target_type == "igw" && each.value.target_value == "auto"
    ? aws_internet_gateway.igw[each.value.vpc_name].id
    : null
  )

  transit_gateway_id = (
    each.value.target_type == "tgw" && each.value.target_value == "auto"
    ? aws_ec2_transit_gateway.tgw.id
    : (each.value.target_type == "tgw" ? each.value.target_value : null)
  )


  vpc_peering_connection_id = (
    each.value.target_type == "vpc_peering"
    ? aws_vpc_peering_connection.peerings[each.value.target_value].id
    : null
  )
}
