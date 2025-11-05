provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "codedeploy_role" {
  name = var.codedeploy_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = var.ec2_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

# Attach policies to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_codedeploy_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2CodeDeployProfile"
  role = aws_iam_role.ec2_role.name
}

# Security group for EC2
resource "aws_security_group" "demo_sg" {
  name        = var.aws_security_group_name
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "demo_ec2" {
  ami                    = "ami-0bdd88bd06d16ba03"
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.demo_sg.id]

  key_name = "ec2-key-pair"

  tags = {
    Name = var.ec2_instance_name
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install ruby -y
              yum install wget -y
              cd /home/ec2-user
              wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
              chmod +x ./install
              ./install auto
              EOF
}

resource "aws_codedeploy_app" "demo_app" {
  name             = var.codedeploy_app_name
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "demo_group" {
  app_name              = aws_codedeploy_app.demo_app.name
  deployment_group_name = "DemoGroup"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.ec2_instance_name
    }
  }
}
