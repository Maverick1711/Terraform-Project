resource "aws_vpc" "Terraform-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = var.tenancy

  tags = {
    Name = "Terraform-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "web-pubsub1" {
  vpc_id     = aws_vpc.Terraform-vpc.id
  cidr_block = var.pub_sub_cidr1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "web-pubsub1"
  }
}

resource "aws_subnet" "web-pubsub2" {
  vpc_id     = aws_vpc.Terraform-vpc.id
  cidr_block = var.pub_sub_cidr2
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "web-pubsub2"
  }
}

resource "aws_subnet" "app-privsub1" {
  vpc_id     = aws_vpc.Terraform-vpc.id
  cidr_block = var.priv_sub_cidr1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "app-privsub1"
  }
}

resource "aws_subnet" "app-privsub2" {
  vpc_id     = aws_vpc.Terraform-vpc.id
  cidr_block = var.priv_sub_cidr2
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "app-privsub2"
  }
}

resource "aws_route_table" "web-pub-route-table" {
  vpc_id = aws_vpc.Terraform-vpc.id

    
  tags = {
    Name = "web-pub-route-table"
  }
}

resource "aws_route_table" "app-priv-route-table" {
  vpc_id = aws_vpc.Terraform-vpc.id
    

  tags = {
    Name = "app-priv-route-table"
  }
}

resource "aws_route_table_association" "web-pub-route-table-association1" {
  subnet_id      = aws_subnet.web-pubsub1.id
  route_table_id = aws_route_table.web-pub-route-table.id
}

resource "aws_route_table_association" "web-pub-route-table-association2" {
  subnet_id      = aws_subnet.web-pubsub2.id
  route_table_id = aws_route_table.web-pub-route-table.id
}

resource "aws_route_table_association" "app-priv-route-table-association1" {
  subnet_id      = aws_subnet.app-privsub1.id
  route_table_id = aws_route_table.app-priv-route-table.id
}

resource "aws_route_table_association" "app-priv-route-table-association2" {
  subnet_id      = aws_subnet.app-privsub2.id
  route_table_id = aws_route_table.app-priv-route-table.id
}

resource "aws_internet_gateway" "Terra-igw" {
  vpc_id = aws_vpc.Terraform-vpc.id

  tags = {
    Name = "Terra-igw"
  }
}

resource "aws_route" "web-pub-igw-route" {
  route_table_id            = aws_route_table.web-pub-route-table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.Terra-igw.id
} 

resource "aws_eip" "Terra-nat-eip" {
  vpc      = true
  tags = {
  }
}

resource "aws_nat_gateway" "Terra-Nat-gateway" {
  allocation_id = aws_eip.Terra-nat-eip.id
  subnet_id     = aws_subnet.web-pubsub1.id

  tags = {
    Name = "Terra-Nat-gateway"
  }
  
}

resource "aws_key_pair" "tf-key-pair" {
key_name = "tf-key-pair"
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "tf-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "tf-key-pair"
}

resource "aws_instance" "web-pub-server" {
  subnet_id     = aws_subnet.web-pubsub1.id
  count         = var.instance_count
  ami           = lookup(var.ami,var.region)
  instance_type = var.instance_type
  key_name      = "tf-key-pair"
  tenancy       = var.tenancy
  vpc_security_group_ids = [aws_security_group.ssh-allowed.id]
#  user_data     = file("install_apache.sh")

  tags = {
    Name  = "Web-pub-server-${count.index + 1}"
  }
}

resource "aws_instance" "app-priv-server" {
  subnet_id     = aws_subnet.app-privsub1.id
  count         = var.instance_count
  ami           = lookup(var.ami,var.region)
  instance_type = var.instance_type
  key_name      = "tf-key-pair"
  tenancy       = var.tenancy
  vpc_security_group_ids = [aws_security_group.ssh-allowed.id]
#  user_data     = file("install_apache.sh")

  tags = {
    Name  = "app-priv-server-${count.index + 1}"
  }
}

resource "aws_security_group" "ssh-allowed" {
    vpc_id = aws_vpc.Terraform-vpc.id
    name        = "ssh-allowed"
    description = "Allow SSH and DB inbound traffic"
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    dynamic "ingress" {
    for_each = [3606,80,22]
    iterator = port
    content {
      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      # Do not use this in production, should be limited to your own IP [10.0.0.0]
    }
  }
    tags = {
        Name = "ssh-allowed"
    }
}

resource "aws_db_subnet_group" "myapp-rds-sub_grp" {
  name       = "myapp-rds-sub_grp"
  subnet_ids = [aws_subnet.app-privsub1.id, aws_subnet.app-privsub2.id]

  tags = {
    Name = "myapp-rds-sub_grp"
  }
}

resource "aws_db_instance" "myapp-rds" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       ="db.${var.instance_type}"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  port                 = "3306"
  db_subnet_group_name = aws_db_subnet_group.myapp-rds-sub_grp.id
  vpc_security_group_ids = [aws_security_group.ssh-allowed.id]
}
