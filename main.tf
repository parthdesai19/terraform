resource "aws_vpc" "my_vpc" {
  cidr_block = "100.64.0.0/16"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "100.64.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_network_interface" "webserver-eni" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["100.64.1.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "webserver" {
  ami           = "ami-047a51fa27710816e" # us-east-1
  instance_type = "t2.micro"
  key_name = aws_key_pair.webserver-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg.id]

  network_interface {
    network_interface_id = aws_network_interface.webserver-eni.id
    device_index         = 0
  }
    provisioner "remote-exec" {
    inline = [
      "sudo yum -y install httpd && sudo systemctl start httpd",
      "echo '<h1><center>My Test Website With Help From Terraform Provisioner</center></h1>' > index.html",
      "sudo mv index.html /var/www/html/"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
  tag = {
      Name = "webserver"
  }
  credit_specification {
    cpu_credits = "unlimited"
  }
}