
# Generate Private Key
resource "tls_private_key" "devk1" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create AWS Key Pair
resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2-dev-250-key"
  public_key = tls_private_key.devk1.public_key_openssh

  tags = {
    Name = "ec2-dev-tls-key"
  }
}

# Save the Private Key to a .pem File
resource "local_file" "devk1_pem" {
  filename        = "ec2-dev-250-key.pem"
  content         = tls_private_key.devk1.private_key_pem
  file_permission = "0400" # Ensure the file is only readable by the owner
}

output "private_key_path" {
  value = local_file.devk1_pem.filename
}

# Define the VPC using a module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["us-east-2a", "us-east-2a"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  # private_subnets = ["10.0.11.0/24", "10.0.22.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  create_igw = true


  tags = {
    "Terraform" = "true"
    "Environment" = "dev"
  }
}

# Security Group allowing port 80 (HTTP) and 22 (SSH)
resource "aws_security_group" "allow_http_ssh" {
  name        = "allow-http-ssh"
  description = "Allow inbound HTTP and SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP access from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound traffic
  }

  tags = {
    "Name" = "Allow HTTP and SSH"
  }
}

# Use aws_ec2_instance module to create an EC2 instance
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"
  name           = "sandip_vm"
  ami            = "ami-0fae88c1e6794aa17"
  instance_type  = "t2.micro"
  key_name       = "ec2-dev-250-key"
  subnet_id      = module.vpc.public_subnets[0]
  vpc_security_group_ids = [ aws_security_group.allow_http_ssh.id ]
  user_data = <<-EOF
    #!bin/bash
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl enable httpd
    sudo systemctl start httpd
    echo "welcome to web server depolyed using TF" >/var/www/html/index.html
    EOF
  tags = {
    "Name" = "sandip_vm"
  }
}

resource "aws_eip" "dev-eip" {
  instance = module.ec2_instance.id
  # depends_on = [ aws_internet_gateway.dev-igway ]
  tags = {
    Name = "dev-ec2-elastic-IP"
  }
}

data "aws_instance" "my-instance" {
  depends_on = [ module.ec2_instance ]
  instance_id = module.ec2_instance.id
}

data "aws_vpc" "my-vpc" {
  depends_on = [ module.vpc ]
  id = module.vpc.vpc_id
}