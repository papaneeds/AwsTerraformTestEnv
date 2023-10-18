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

##################################################################
# NACL                                                           #
##################################################################

# The NACL apparently has to be modified for multicast.
#

# 


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

# Allow all outbound traffic to everywhere
resource "aws_vpc_security_group_egress_rule" "training_sg_egress_rule" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "training_sg_egress_rule-${var.count_index}"
  }
}

# Explicitly allow all UDP to the specific multicast address.
# You would think that this was already happening by the "Allow all outbound traffic everywhere"
# but apparently not for multicast!
/*
resource "aws_vpc_security_group_egress_rule" "training_sg_egress_rule_multicast_239_1_1_1_udp" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "239.1.1.1/32"
  ip_protocol = "udp"
  from_port = 1234
  to_port = 1234

  tags = {
    Name = "training_sg_egress_rule_multicast_239_1_1_1_udp-${var.count_index}"
  }
}
*/

# Explicitly allow all IGMP to the transit gateway
# You would think that this was already happening by the "Allow all outbound traffic everywhere"
# but apparently not for multicast!
/*
resource "aws_vpc_security_group_egress_rule" "training_sg_egress_rule_multicast_igmp_tgw" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "0.0.0.0/32"
  ip_protocol = "2"

  tags = {
    Name = "training_sg_egress_rule_multicast_igmp_tgw-${var.count_index}"
  }
}
*/

# Explicitly allow IGMP to the specific multicast address.
# You would think that this was already happening by the "Allow all outbound traffic everywhere"
# but apparently not for multicast!
/*
resource "aws_vpc_security_group_egress_rule" "training_sg_egress_rule_multicast_239_1_1_1_igmp" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "239.1.1.1/32"
  ip_protocol = "2"

  tags = {
    Name = "training_sg_egress_rule_multicast_239_1_1_1_igmp-${var.count_index}"
  }
}
*/


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

# This ingress rule allows for all multicast traffic.
# See https://docs.aws.amazon.com/vpc/latest/tgw/how-multicast-works.html
resource "aws_vpc_security_group_ingress_rule" "training_sg_ingress_rule_all_multicast_traffic" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "224.0.0.0/4"
  ip_protocol = "udp"
  # Allow all ports according to the min and max 
  # from https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
  from_port = 0
  to_port = 49151

  tags = {
    Name = "training_sg_ingress_rule_all_multicast_traffic-${var.count_index}"
  }
}


# This ingress rule allows for IGMP query packets to come from the transit gateway
# See  https://docs.aws.amazon.com/vpc/latest/tgw/tgw-multicast-overview.html
# "The transit gateway sends membership query packets to all the IGMP members so 
# that it can track multicast group membership. The source IP of these IGMP 
# query packets is 0.0.0.0/32, and the destination IP is 224.0.0.1/32 and 
# the protocol is 2. Your security group configuration on the IGMP hosts 
# (instances), and any ACLs configuration on the host subnets must allow 
# these IGMP protocol messages."
# and see https://docs.aws.amazon.com/vpc/latest/tgw/how-multicast-works.html
resource "aws_vpc_security_group_ingress_rule" "training_sg_ingress_rule_igmp_query" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "0.0.0.0/32"
  ip_protocol = "2"

  tags = {
    Name = "training_sg_ingress_rule_igmp_query-${var.count_index}"
  }
}

################################################
#  EC2 Instances                               #
################################################

resource "aws_instance" "training_node" {
  count = var.num_wintak_machines
  instance_type          = "t3.medium"
  ami = "ami-00a472ea118a9486e"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.training_sg.id]
  subnet_id              = aws_subnet.training_public_subnet.id
  source_dest_check      = false

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "training-node-${var.count_index}.${count.index}"
  }

}



