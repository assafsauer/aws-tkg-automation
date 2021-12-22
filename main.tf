variable "awsprops" {
    default = {
    region = "eu-west-1"
    itype = "t3.large"
    publicip = true
    keyname = "sauer-key"
    availability_zone = "eu-west-1a"
  }
}

provider "aws" {
  region = lookup(var.awsprops, "region")
}


resource "aws_vpc" "ownvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

tags = {
    Name = "tkg_vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.ownvpc.id
  cidr_block = "192.168.2.0/24"
  availability_zone = lookup(var.awsprops, "availability_zone") 

tags = {
    Name = "tkg_public_sub"
  }
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.ownvpc.id
    cidr_block = "192.168.0.0/24"
    availability_zone = lookup(var.awsprops, "availability_zone") 

tags = {
    Name = "tkg_private_sub"
  }
}

resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.ownvpc.id

tags = {
    Name = "tkg_gw"
  }
}

resource "aws_route_table" "my_route_table1" {
  vpc_id = aws_vpc.ownvpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw.id
  }

tags = {
    Name = "tkg_route"
  }
}


resource "aws_route_table_association" "route_table_association1" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.my_route_table1.id

}


resource "aws_route_table" "my_route_table2" {
  vpc_id = aws_vpc.ownvpc.id
  depends_on = [aws_nat_gateway.mynatgw]


  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mynatgw.id
  }

tags = {
    Name = "tkg_route_table"
  }
}

resource "aws_eip" "nat" {
  vpc      = true
  depends_on = [aws_internet_gateway.mygw,]

tags = {
    Name = "tkg_nat"
  }
}

resource "aws_nat_gateway" "mynatgw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on = [aws_internet_gateway.mygw,]

tags = {
    Name = "tkg_nat_gw"
  }
}


resource "aws_security_group" "mywebsecurity" {
  name        = "my_web_security"
  description = "Allow http,ssh,icmp"
  vpc_id      = aws_vpc.ownvpc.id

  ingress {
    description = "mgmt-cluster"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "8080"
    from_port   = 8080
    to_port     = 8080
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
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ALL ICMP - IPv4"
    from_port   = -1    
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "tkg_security_group"
  }
}

resource "aws_instance" "tkg" {
  ami           = "ami-08ca3fed11864d6bb"
  instance_type = lookup(var.awsprops, "itype") 
  associate_public_ip_address = true
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = ["${aws_security_group.mywebsecurity.id}"]
  key_name = lookup(var.awsprops, "keyname") 
  availability_zone = lookup(var.awsprops, "availability_zone") 

  connection {
      host        = aws_instance.tkg.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("/Users/sauera/Downloads/terraform/sauer-key.pem")}"
    
    }


  provisioner "file" {
    source      = "prep.sh"
    destination = "/home/ubuntu/prep.sh"
    }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 prep.sh",
      "sudo ./prep.sh",
      
    ]
  } 

tags = {
    Name = "tkg"
  }

  root_block_device {
    volume_size = "30"
  }

}

output "ec2instance" {
  value = aws_instance.tkg.public_ip
}
