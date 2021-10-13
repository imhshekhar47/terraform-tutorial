variable "ami_dtl" {
    type = object({
        name =  string
        region = string
        source_ami = string
        instance_type = string
        username = string
    })

    default = {
        name = "app-ui"
        region = "us-west-2"
        source_ami = "ami-013a129d325529d4d"
        instance_type = "t2.micro"
        username = "ec2-user"
    }
}
source "amazon-ebs" "ami_ui" {
  ami_name = "app-ui"
  region   = "us-west-2"

  source_ami    = "ami-013a129d325529d4d"
  instance_type = "t2.micro"

  ssh_username = "ec2-user"
}

build {
  name = "ami-app-ui"
  sources = [
    "source.amazon-ebs.ami_ui"
  ]
  provisioner "shell" {
    environment_vars = [
      "AMI_AUTHOR=imhshekhar47",
    ]
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd.x86_64",
      "sudo systemctl start httpd.service",
      "sudo systemctl enable httpd.service",
    ]
  }
}
