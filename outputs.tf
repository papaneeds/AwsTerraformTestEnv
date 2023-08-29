output "training_ip" {
    description = "Public IPs of the EC2 instances"
    value = module.public_subnet[*].training_ip
}

output "private_ip" {
    description = "Private IPs of the EC2 instances"
    value = module.public_subnet[*].private_ip
}

/*
output "training_ip2" {
    description = "Public IPs of the public2 instances"
    value = module.public_subnet2.aws_instance.training_node[*].public_ip
}*/