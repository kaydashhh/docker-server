# configured aws provider with proper credentials
provider "aws" {
  region    = "us-east-2"
  #shared_config_files      = ["/Users/austi/.aws/conf"]
  #shared_credentials_files = ["/Users/austi/.aws/credentials"]
  profile                  = "default"
}

# Create a remote backend for your terraform 
terraform {
  backend "s3" {
    bucket = "docker-tfstate"
    dynamodb_table = "app-state"
    key    = "LockID"
    region = "us-east-1"
    profile = "default"
  }
}

# Create a Vpc
resource "aws_vpc" "krommVpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "krommVpc"
  }
}
# Create Subnet
resource "aws_subnet" "krommSubnet" {
  vpc_id     = aws_vpc.krommVpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone      = "us-east-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "krommSubnet"
  }
}
# Create internet gateway
resource "aws_internet_gateway" "kromm-IG" {
  vpc_id = aws_vpc.krommVpc.id

  tags = {
    Name = "kromm-IG"
  }
}
# Create Route table
resource "aws_route_table" "Public-RT" {
  vpc_id = aws_vpc.krommVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kromm-IG.id
  }

  tags = {
    Name = "Public-RT"
  }

}

# Associate subnet with route table
resource "aws_route_table_association" "Public-Ass" {
  subnet_id      = aws_subnet.krommSubnet.id
  route_table_id = aws_route_table.Public-RT.id

}

# Create Security group
resource "aws_security_group" "Public-SG" {
  name        = "Public-SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.krommVpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }

  ingress {
    description      = "ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  
  ingress {
    description      = "http from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    description      = "http nginx access"
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Public-SG"
  }

}
# Create instance
# resource "aws_instance" "Server1" {
#  ami                     = "ami-06c4532923d4ba1ec"
#  instance_type           = "t2.micro"
#  vpc_security_group_ids  = [aws_security_group.Public-SG.id]
#  key_name                = "feb-class-key"
#  subnet_id               = aws_subnet.krommSubnet.id
#  availability_zone       = "us-east-2b"

# tags = {
#    Name = "kromm-Server"

#  }

#}


# Create a Tomcat Server
resource "aws_instance" "docker-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Public-SG.id]
  subnet_id              = aws_subnet.krommSubnet.id
  key_name               = "feb-class-key"
  availability_zone      = "us-east-2c"
  user_data              =  "${file("docker-install.sh")}"
  


  tags = {
    Name = "docker-server"
  }
}


# use data source to get a registered ubuntu ami
data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# print the url of the jenkins server
#output "Jenkins_website_url" {
 # value     = join ("", ["http://", aws_instance.jenkins.public_ip, ":", "8080"])
  #description = "Jenkins Server is Jenkins"
#}

# print the url of the tomcat server
#output "Tomcat_website_url1" {
 # value     = join ("", ["http://", aws_instance.tomcat.public_ip, ":", "8080"])
  #description = "Tomcat Server is tomcat"
#}

# print the url of the SonaQube server
#output "SonaQube_website_url3" {
  #value     = join ("", ["http://", aws_instance.Sonarqube.public_ip, ":", "9000"])
  #description = "SonaQube Server is sonarqube"
#}

# print the url of the Nexus server
#output "Nexus_website_url4" {
#  value     = join ("", ["http://", aws_instance.Nexus_server.public_ip, ":", "8081"])
 # description = "Nexus Server is Nexus_server"
