module "public_subnet" {
    count = var.num_vpcs

    source = "./modules/public_subnet"
    num_wintak_machines = 2
    aws_access_ip = var.aws_access_ip
    count_index = count.index
    key_name = aws_key_pair.training_auth.key_name
}

resource "aws_key_pair" "training_auth" {
  key_name   = "trainingkey"
  public_key = file("~/.ssh/trainingkey.pub")
}

/*module "public_subnet2" {
    source = "./modules/public_subnet2"
    num_wintak_machines = 2
}*/

##########################################################
# Transit Gateway for multicast                          #
##########################################################

resource "aws_ec2_transit_gateway" "training-multicast-tgw" {
  description = "transit gateway to enable multicast for the training environment"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  multicast_support = "enable"

  tags = {
    Name = "training-multicast-tgw"
  }
}

resource "aws_ec2_transit_gateway_multicast_domain" "training-multicast-domain" {
  transit_gateway_id = aws_ec2_transit_gateway.training-multicast-tgw.id

  igmpv2_support = "enable"

  tags = {
    Name = "training-multicast-domain"
  }
}

###################################################################
# attach vpc 0 and subnet 0 to transit gateway and multicast domain #
###################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "training-multicast-tgw-vpc-attachment_0" {
  subnet_ids = [module.public_subnet[0].public_subnet_id]
  vpc_id = module.public_subnet[0].training_vpc_id
  transit_gateway_id = aws_ec2_transit_gateway.training-multicast-tgw.id

  tags = {
    Name = "training-multicast-tgw-vpc-attachment_0"
  }
}

resource "aws_ec2_transit_gateway_multicast_domain_association" "training-multicast-tgw-domain-association_0" {
  subnet_id                           = module.public_subnet[0].training_public_subnet_id
  transit_gateway_attachment_id       = aws_ec2_transit_gateway_vpc_attachment.training-multicast-tgw-vpc-attachment_0.id
  transit_gateway_multicast_domain_id = aws_ec2_transit_gateway_multicast_domain.training-multicast-domain.id
}

###################################################################
# attach vpc and subnet 1 to transit gateway and multicast domain #
###################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "training-multicast-tgw-vpc-attachment_1" {
  subnet_ids = [module.public_subnet[1].public_subnet_id]
  vpc_id = module.public_subnet[1].training_vpc_id
  transit_gateway_id = aws_ec2_transit_gateway.training-multicast-tgw.id

  tags = {
    Name = "training-multicast-tgw-vpc-attachment_1"
  }
}

resource "aws_ec2_transit_gateway_multicast_domain_association" "training-multicast-tgw-domain-association_1" {
  subnet_id                           = module.public_subnet[1].training_public_subnet_id
  transit_gateway_attachment_id       = aws_ec2_transit_gateway_vpc_attachment.training-multicast-tgw-vpc-attachment_1.id
  transit_gateway_multicast_domain_id = aws_ec2_transit_gateway_multicast_domain.training-multicast-domain.id
}

#########################################################################
# Create routes from vpc,subnet 0 <-> vpc,subnet 1  via transit gateway #
#########################################################################

resource "aws_route" "route_0_to_1" {
  route_table_id         = module.public_subnet[0].training_public_rt_id
  destination_cidr_block = module.public_subnet[1].training_public_subnet_cidr_block
  transit_gateway_id = aws_ec2_transit_gateway.training-multicast-tgw.id
}

resource "aws_route" "route_1_to_0" {
  route_table_id         = module.public_subnet[1].training_public_rt_id
  destination_cidr_block = module.public_subnet[0].training_public_subnet_cidr_block
  transit_gateway_id = aws_ec2_transit_gateway.training-multicast-tgw.id
}