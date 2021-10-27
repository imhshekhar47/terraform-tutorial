variable "common_tags" {
    type = map(string)
}

variable "db_dtl" {
    type = object({
        availability_zone = string,
        subnet_ids = list(string),
        db_password = string
    })
}

resource "aws_db_subnet_group" "db_subnte_grp" {
  name       = "main"
  subnet_ids = var.db_dtl.subnet_ids

  tags = merge(var.common_tags, {
        type = "db-subnet-group"
    })
}

resource "aws_db_instance" "app_db" {
    availability_zone    = var.db_dtl.availability_zone
    db_subnet_group_name = aws_db_subnet_group.db_subnte_grp.name
    allocated_storage    = 10
    engine               = "mysql"
    engine_version       = "5.7"
    instance_class       = "db.t3.micro"
    name                 = "appdb"
    username             = "admin"
    password             = var.db_dtl.db_password
    parameter_group_name = "default.mysql5.7"
    skip_final_snapshot  = true

    tags = merge(var.common_tags, {
        type = "mysql"
        version = "5.7"
    })
}

output "o_db_endpoint" {
    value=aws_db_instance.app_db.endpoint
}
