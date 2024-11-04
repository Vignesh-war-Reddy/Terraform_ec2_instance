provider "aws" {
  region     = "us-west-2"
  access_key = "AKIA47CRVVSB7PCNL7M4"
  secret_key = "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"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_security_group"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "iam_role" {
  name = "my_iam_role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }]
  }
  EOF
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "my_instance_profile"
  role = aws_iam_role.iam_role.name
}

resource "aws_instance" "my_ec2_instance" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  key_name               = "your-key-pair-name"
  subnet_id             = aws_subnet.subnet.id
  security_groups       = [aws_security_group.ec2_sg.name]
  iam_instance_profile   = aws_iam_instance_profile.iam_instance_profile.name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = 10
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name        = "MyEC2Instance"
    Environment = "Development"
  }
}

output "instance_ip_addr" {
  value = aws_instance.my_ec2_instance.public_ip
}

output "instance_id" {
  value = aws_instance.my_ec2_instance.id
}

output "instance_private_ip" {
  value = aws_instance.my_ec2_instance.private_ip
}
