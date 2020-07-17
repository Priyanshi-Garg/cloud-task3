provider "aws" {
  region     = "ap-south-1"
  profile    = "mypriyanshi"
}

resource "aws_vpc" "t3-vpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  tags = {
    Name = "t3-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id     = "${aws_vpc.t3-vpc.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id     = "${aws_vpc.t3-vpc.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "t3-igw" {
  vpc_id = "${aws_vpc.t3-vpc.id}"

  tags = {
    Name = "t3-igw"
  }
}

resource "aws_route_table" "t3-route" {
  vpc_id = "${aws_vpc.t3-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.t3-igw.id}"
  }
  tags = {
    Name = "t3-route"
  }
}

resource "aws_route_table_association" "t3-route-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.t3-route.id
}

provider "tls" {}
resource "tls_private_key" "t" {
    algorithm = "RSA"
}
resource "aws_key_pair" "test" {
    key_name   = "task3-key"
    public_key = "${tls_private_key.t.public_key_openssh}"
}
provider "local" {}
resource "local_file" "key" {
    content  = "${tls_private_key.t.private_key_pem}"
    filename = "task3-key.pem"
       
}

resource "aws_security_group" "wp-sg" {
  name        = "wp-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = "${aws_vpc.t3-vpc.id}"
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "wp-sg"
  }
}

resource "aws_instance" "wp-os" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  key_name = "task3-key"
  vpc_security_group_ids = [ aws_security_group.wp-sg.id ]
  subnet_id = aws_subnet.public-subnet.id
  tags = {
    Name = "wp-os"
  }
}

resource "aws_security_group" "mysql-sg" {
  name        = "basic"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.t3-vpc.id}"

  ingress {
    description = "mysql-security_group"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "mysql-sg"
  }
}

resource "aws_instance" "mysql-os" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name      = "task3-key"
  subnet_id =  aws_subnet.private-subnet.id
  vpc_security_group_ids = [ aws_security_group.mysql-sg.id ]
  tags = {
    Name = "mysql-os"
  }
}
