output "vpcs_criadas" {
  value = { for k, v in aws_vpc.vpc : k => v.id }
}

output "subnets_publicas" {
  value = { for k, v in aws_subnet.public_subnet : k => v.id }
}

output "subnets_privadas" {
  value = { for k, v in aws_subnet.private_subnet : k => v.id }
}