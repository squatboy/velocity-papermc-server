output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "IGW ID"
  value       = aws_internet_gateway.mcserver_igw.id
}

output "availability_zone" {
  description = "가용 영역"
  value       = var.availability_zone
}

output "public_subnet_ids" {
  description = "Public Subnet ID 목록"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet ID 목록"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "Public Subnet CIDR 블록 목록"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "Private Subnet CIDR 블록 목록"
  value       = aws_subnet.private[*].cidr_block
}

# output "nat_gateway_ids" {
#   description = "NAT Gateway ID 목록"
#   value       = aws_nat_gateway.mcserver_nat[*].id
# }

# output "nat_gateway_public_ips" {
#   description = "NAT Gateway Public IP 목록"
#   value       = aws_eip.nat[*].public_ip
# }

output "public_route_table_id" {
  description = "Public 라우팅 테이블 ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private 라우팅 테이블 ID 목록"
  value       = aws_route_table.private[*].id
}
