#######################################################
# Training VPC                                        #
#######################################################

resource "aws_vpc" "training_vpc" {
  cidr_block           = "11.${var.count_index}.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "training-vpc-${var.count_index}"
  }
}

#########################################################
# Public Subnet                                         #
#########################################################

resource "aws_subnet" "training_public_subnet" {
  vpc_id                  = aws_vpc.training_vpc.id
  cidr_block              = "11.${var.count_index}.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ca-central-1a"

  tags = {
    Name = "training-public-subnet-${var.count_index}"
  }
}

resource "aws_internet_gateway" "training_internet_gateway" {
  vpc_id = aws_vpc.training_vpc.id

  tags = {
    Name = "training-igw-${var.count_index}"
  }
}

resource "aws_route_table" "training_public_rt" {
  vpc_id = aws_vpc.training_vpc.id

  tags = {
    Name = "training-public-rt-${var.count_index}"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.training_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.training_internet_gateway.id
}

resource "aws_route_table_association" "training_public_rt_training_public_subnet_association" {
  subnet_id      = aws_subnet.training_public_subnet.id
  route_table_id = aws_route_table.training_public_rt.id
}


###################################################################
# Security Groups, ingress and egress rules for EC2 Instances     #
###################################################################

resource "aws_security_group" "training_sg" {
  name        = "training-sg"
  description = "training vpc security group"
  vpc_id      = aws_vpc.training_vpc.id

  tags = {
    Name = "training-sg-${var.count_index}"
  }
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "training_sg_egress_rule" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "training_sg_egress_rule-${var.count_index}"
  }
}


# This ingress rule allows all protocol access from the specific ip address
# defined in var.aws_access_ip. This is typically used to remote desktop into
# the EC2 instances from a single external IP address.
resource "aws_vpc_security_group_ingress_rule" "training_sg_ingress_rule_external_access" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "${var.aws_access_ip}/32"
  ip_protocol = "-1"

  tags = {
    Name = "training_sg_ingress_rule_external_access-${var.count_index}"
  }
}

# This ingress rule allows for all traffic from the training vpcs
resource "aws_vpc_security_group_ingress_rule" "training_sg_ingress_rule_all_traffic_subnet" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "11.0.0.0/8"
  ip_protocol = "-1"

  tags = {
    Name = "training_sg_ingress_rule_all_traffic_subnet-${var.count_index}"
  }
}

################################################
#  EC2 Instances                               #
################################################

resource "aws_instance" "training_node" {
  count = var.num_wintak_machines
  instance_type          = "t2.large"
#  ami                    = data.aws_ami.training_ami.id
  ami = "ami-0b387ae0c58e12b95"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.training_sg.id]
  subnet_id              = aws_subnet.training_public_subnet.id
  #user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "training-node-${var.count_index}.${count.index}"
  }

}



