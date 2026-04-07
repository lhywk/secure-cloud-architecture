locals {
  instance_type           = "t2.micro"
  database_instance_class = "db.t3.micro"
  ec2_key_pair_name       = "key_pair"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Secrets Manager에서 DB 비밀번호 참조 (security 모듈이 생성한 secret)
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_secret_id
}
