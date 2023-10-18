output "training_ip" {
    value = aws_instance.training_node[*].public_ip
}

output "private_ip" {
    value = aws_instance.training_node[*].private_ip
}

output "public_subnet_id" {
    value = aws_subnet.training_public_subnet.id
}

output "training_vpc_id" {
    value = aws_vpc.training_vpc.id
}

output "training_public_subnet_cidr_block" {
    value = aws_subnet.training_public_subnet.cidr_block
}

output "training_public_rt_id" {
    value=aws_route_table.training_public_rt.id
}

output "training_public_subnet_id" {
    value = aws_subnet.training_public_subnet.id
}