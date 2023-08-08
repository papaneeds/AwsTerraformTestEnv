resource "aws_vpc" "training_vpc" {
  cidr_block           = "11.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "training-vpc"
  }
}

resource "aws_subnet" "training_public_subnet" {
  vpc_id                  = aws_vpc.training_vpc.id
  cidr_block              = "11.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ca-central-1a"

  tags = {
    Name = "training-public-subnet"
  }
}

resource "aws_internet_gateway" "training_internet_gateway" {
  vpc_id = aws_vpc.training_vpc.id

  tags = {
    Name = "training-igw"
  }
}

resource "aws_route_table" "training_public_rt" {
  vpc_id = aws_vpc.training_vpc.id

  tags = {
    Name = "training-public-rt"
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

resource "aws_security_group" "training_sg" {
  name        = "training-sg"
  description = "training vpc security group"
  vpc_id      = aws_vpc.training_vpc.id

  tags = {
    Name = "training-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "training_sg_egress_rule" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "training_sg_egress_rule"
  }
}

resource "aws_vpc_security_group_ingress_rule" "training_sg_ingress_rule" {
  security_group_id = aws_security_group.training_sg.id

  cidr_ipv4   = "${var.aws_access_ip}/32"
  ip_protocol = "-1"

  tags = {
    Name = "training_sg_ingress_rule"
  }
}

resource "aws_key_pair" "training_auth" {
  key_name   = "trainingkey"
  public_key = file("~/.ssh/trainingkey.pub")
}

resource "aws_instance" "training_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.training_ami.id
  key_name               = aws_key_pair.training_auth.key_name
  vpc_security_group_ids = [aws_security_group.training_sg.id]
  subnet_id              = aws_subnet.training_public_subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 30
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
        hostname = self.public_ip,
        user = "ubuntu",
        identityfile = "~/.ssh/trainingkey"
    }
    )
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }

  tags = {
    Name = "training-node"
  }

}