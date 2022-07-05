provider "aws" {
  region                   = "eu-north-1"
}


terraform {
  backend "s3" {
    bucket         = "pet-clinic-project"
    key            = "pet-clinic-tf.tfstate"
    encrypt        = true
    region         = "eu-north-1"
    dynamodb_table = "petclinic-tf-lock"
  }

}

resource "aws_instance" "App_PetClinic_TF" {
  ami                    = "ami-0bf2ce41790745811"
  instance_type          = "t3.micro"
  key_name               = "ATC"
  vpc_security_group_ids = [aws_security_group.sg_app.id]
  credit_specification {
    cpu_credits = "standard"
  }
  tags = {
    Name    = "App_TF"
    Owner   = "idanylyuk"
    Project = "Petclinic"
  }
}
resource "aws_instance" "DB_PetClinic_TF" {
  ami                    = "ami-04e8b0e36ed3403dc"
  instance_type          = "t3.micro"
  key_name               = "ATC"
  vpc_security_group_ids = [aws_security_group.sg_db.id]
  credit_specification {
    cpu_credits = "standard"
  }
  tags = {
    Name    = "DB_TF"
    Owner   = "idanylyuk"
    Project = "Petclinic"
  }
}

resource "aws_security_group" "sg_app" {
  name = "sg_app"
  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "App_TF"
  }
}
resource "aws_security_group" "sg_db" {
  name = "sg_db"
  ingress {
    from_port   = "5432"
    to_port     = "5432"
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.App_PetClinic_TF.public_ip}/32"]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "DB_TF"
  }
}

resource "aws_route53_record" "pet" {
  zone_id = "Z0118956EU069IAZHTCP"
  name    = "pet.xcoder.pp.ua"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.App_PetClinic_TF.public_ip]
}

#IP of aws instances copied to a file hosts file in local system
resource "local_file" "hosts_file" {
  content  = <<EOT
[app_server]
app_host ansible_host=${aws_instance.App_PetClinic_TF.public_ip}
[db_server]
db_host ansible_host=${aws_instance.DB_PetClinic_TF.public_ip}
EOT  
  filename = "../config/hosts"
}

#IP of aws instances copied to a file hosts file in local system
resource "local_file" "hosts_file_ip" {
  content  = <<EOT
#!/bin/bash

server_ip='${aws_instance.App_PetClinic_TF.public_ip}'
db_server_ip='${aws_instance.DB_PetClinic_TF.public_ip}'
EOT  
  filename = "../config/hosts_geo"
}


