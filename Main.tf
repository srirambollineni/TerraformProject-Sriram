terraform {

terraform {
  backend "s3" {
    bucket = "testbcuket-1"
    key    = "path/terraform.tfstate"
    region = "us-east-1"
  }
}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


# Create VPC
resource "aws_vpc" "Test_VPC_Terraform" {
  cidr_block       = "10.10.0.0/16"
  
  tags = {
    Name = "Test_VPC_Terraform"
  }
}

# Create Subnets
resource "aws_subnet" "Test_VPC_Terraform-1a" {
  vpc_id     = aws_vpc.Test_VPC_Terraform.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Test_VPC_Terraform-1a"
  }
}

resource "aws_subnet" "Test_VPC_Terraform-1b" {
  vpc_id     = aws_vpc.Test_VPC_Terraform.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "us-east-1a"
   map_public_ip_on_launch = "false"

  tags = {
    Name = "Test_VPC_Terraform-1b"
  }
}

resource "aws_subnet" "Test_VPC_Terraform-1c" {
  vpc_id     = aws_vpc.Test_VPC_Terraform.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "us-east-1b"
   map_public_ip_on_launch = "true"

  tags = {
    Name = "Test_VPC_Terraform-1c"
  }
}
resource "aws_subnet" "Test_VPC_Terraform-1d" {
  vpc_id     = aws_vpc.Test_VPC_Terraform.id
  cidr_block = "10.10.3.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "Test_VPC_Terraform-1d"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "Test_Internet_Gateway" {
  vpc_id = aws_vpc.Test_VPC_Terraform.id
  tags = {
    Name = "Test_Internet_Gateway"
  }
}

# Create Route Table
resource "aws_route_table" "Terraform-RT-Public" {
  vpc_id = aws_vpc.Test_VPC_Terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Test_Internet_Gateway.id
  }

  tags = {
    Name = "Terraform-RT-Public"
  }
}

resource "aws_route_table" "Terraform-RT-Private" {
  vpc_id = aws_vpc.Test_VPC_Terraform.id

  tags = {
    Name = "Terraform-RT-Private"
  }
}
# RT Association
resource "aws_route_table_association" "RT_assoc_Public-1a" {
  subnet_id      = aws_subnet.Test_VPC_Terraform-1a.id
  route_table_id = aws_route_table.Terraform-RT-Public.id
}
resource "aws_route_table_association" "RT_assoc_Private-1b" {
  subnet_id      = aws_subnet.Test_VPC_Terraform-1b.id
  route_table_id = aws_route_table.Terraform-RT-Private.id
  }
resource "aws_route_table_association" "RT_assoc_Public-1c" {
  subnet_id      = aws_subnet.Test_VPC_Terraform-1c.id
  route_table_id = aws_route_table.Terraform-RT-Public.id
}
resource "aws_route_table_association" "RT_assoc_Private-1d" {
  subnet_id      = aws_subnet.Test_VPC_Terraform-1d.id
  route_table_id = aws_route_table.Terraform-RT-Private.id
  }


# Create Security Group
resource "aws_security_group" "Test_Security_Group" {
  name        = "Test_Security_Group"
  description = "Allow https & SSh inbound traffic"
  vpc_id      = aws_vpc.Test_VPC_Terraform.id

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

 ingress {
    description      = "https"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Test_Security_Group"
  }
}

resource "aws_launch_template" "Test_Launch_Template" {
  name = "Test_Launch_Template"
  image_id = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name = aws_key_pair.Key1.id
  vpc_security_group_ids = [aws_security_group.Test_Security_Group.id]
  user_data = filebase64("example.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
    Name = "Test Instance"
    }
  } 
    }
  
# Create Keypair
resource "aws_key_pair" "Key1" {
  key_name   = "key1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBq8j5iTeNaGsIQBh9Cd8e3xkZbjJcoukfLLI5ib3cAqh/qwP9cW32jm/XeguaQJ0KDI30GzxEPsziiOc18mf9BAFzjmltIaie2ToAsheFaKM9eWtBEwq/6Gqo2IfZLWEKIUTYZU3W9dBKqxqLJ4TZz6REFQNJMJ9+5buzL6tg/5xuNrxnqL6S4KCqJO85t0cW0ksyCy91MphLSAd7mOfWnjdlr379zk6OAgDOz5jAid0rFdB7J6VjWqIfxH7N8q0qbuaM14FXvnlTk+moiCl0TOCVhxIcuq7kTPmkIo/J1kO3fm7jzZ4XAPgMKEezzm55U0mGR+Pcd1aAohXbKhc2VcJLvPDHJp7bajKW37hApGsCmM1xmPtkGHAExO7evXJXLPM4DYgVtydTF9cCvoFittENaPEIRefOTRoy0WM8RQe0t8O5vU5gUDYq9ZHM3WBaTI8w/o2FDq7JIGDPTz36gUfxULvNo1Ylh6FONFdcri+pfJ6Jt58KsiDN+ixm2Y0= SRI  RAM@DESKTOP-SUMO9I1"
}  
#   Create ASG
  resource "aws_autoscaling_group" "Test_ASG" {
  vpc_zone_identifier = [aws_subnet.Test_VPC_Terraform-1a.id, aws_subnet.Test_VPC_Terraform-1b.id,aws_subnet.Test_VPC_Terraform-1c.id, aws_subnet.Test_VPC_Terraform-1d.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  name = "Test_ASG"
  target_group_arns = [aws_lb_target_group.LB_Target_Group.arn]

  launch_template {
    id      = aws_launch_template.Test_Launch_Template.id
    version = "$Latest"
  }
}

# Create Target Group
resource "aws_lb_target_group" "LB_Target_Group" {
  name     = "LBTargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.Test_VPC_Terraform.id
}
# Create Listener
resource "aws_lb_listener" "LB_Listener" {
  load_balancer_arn = aws_lb.Test_LB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.LB_Target_Group.arn
    }
}

# Create LB
resource "aws_lb" "Test_LB" {
  name               = "TestLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Test_Security_Group.id]
  subnets            = [aws_subnet.Test_VPC_Terraform-1a.id, aws_subnet.Test_VPC_Terraform-1c.id]

  tags = {
    Environment = "production"
  }
}


