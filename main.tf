variable "awsprops" {
    type = map(string)
    default = {
    region = "eu-west-2"
    vpc = "vpc-5234832d"
    ami = "ami-035469b606478d63d"
    itype = "t2.micro"
    subnet = "subnet-81896c8e"
    publicip = true
    keyname = "spidermanjt"
    secgroupname = "IAC-Sec-Group"
  }
}

provider "aws" {
  region = lookup(var.awsprops, "region")
}

resource "aws_vpc" "mainvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  

  tags = {
    Name = "mainvpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = lookup(var.awsprops, "subnet")
  
  }

  output "subnet id" {
  value = aws_subnet.main.*.id

 # output "subnet_ids" {
 # value       = coalescelist(aws_subnet.private.*.id, aws_subnet.public.*.id)
 # description = "Subnet IDs"
# }
  
}
}
resource "aws_security_group" "project-iac-sg" {
  name = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  # vpc_id = lookup(var.awsprops, "vpc")
  vpc_id = aws_vpc.mainvpc.id
  
    
  
  // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_instance" "project-iac" {
  ami = lookup(var.awsprops, "ami")
  instance_type = lookup(var.awsprops, "itype")
  subnet_id = aws_subnet.main.id #FFXsubnet2
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name = lookup(var.awsprops, "keyname")

vpc_security_group_ids = [
    aws_security_group.project-iac-sg.id
  ]
  #vpc_security_group_ids = ["${aws_security_group.project-iac.id}"]

  
  root_block_device {
    delete_on_termination = true
    volume_size = 50
    volume_type = "gp2"
  }
  tags = {
    Name ="SERVER01"
    Environment = "DEV"
    OS = "UBUNTU"
    Managed = "IAC"
  }

  depends_on = [ aws_security_group.project-iac-sg ]
}


output "ec2instance" {
  value = aws_instance.project-iac.public_ip
}

