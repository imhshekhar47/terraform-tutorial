resource "tls_private_key" "ec2_pvt_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "ec2_bastion_key" {
  key_name = "bastion-key"
  public_key = tls_private_key.ec2_pvt_key.public_key_openssh

  tags = merge(var.common_tags, {
    Name = "bastion-key"
  })
}

# Generate key-pair file bastion-key.pem
resource "local_file" "ec2_bastion_key_file" {
  content = "${tls_private_key.ec2_pvt_key.private_key_pem}"
  filename = "bastion-key.pem"
  #file_permission = "0400"
  # provisioner "local-exec" {
  #   command = "chmod 400 bastion-key.pem"
  # }
}

# Create security group for bastion
resource "aws_security_group" "ec2_bastion_sg" {
  name = "ec2-bastion-sg"
  description = "Allow ssh from internet"
  vpc_id = var.ec2_bastion_dtl.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }


  tags = merge(var.common_tags, {
    Name = "ec2-bastion-sg"
  })
}

resource "aws_instance" "ec2_bastion_host" {
  subnet_id = var.ec2_bastion_dtl.subnet_id
  ami = var.ec2_bastion_dtl.ami
  instance_type = var.ec2_bastion_dtl.type
  key_name = aws_key_pair.ec2_bastion_key.key_name
  associate_public_ip_address = true
  security_groups = [aws_security_group.ec2_bastion_sg.id]
  user_data = filebase64("${path.module}/boot.sh")

  tags = merge(var.common_tags,  {
    Name = var.ec2_bastion_dtl.name
  })
}