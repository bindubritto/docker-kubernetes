
# Using Default Security Group

resource "aws_default_security_group" "default-sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = [] // allowing access to vpc endpoints
  }

  tags = {
    Name: "${var.env_prefix}-default-sg"
  }
}


data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name = "Virtualiztion-type"
    values = ["hvm"]
  }
}


resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"

  # public_key = var.my_public_key // way-01
  # public_key = "${file("~/.ssh/id_rsa.pub")}" // way-02
  public_key = file(var.public_key_location) // way-03
}


resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  ## Optional Argument
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entrypoint.sh")

  tags = {
    Name: "${var.env_prefix}-server"
  }
}
