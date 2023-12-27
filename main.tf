provider "aws" {
  region = "us-east-1"
}

# VPC & subnets
resource "aws_vpc" "webapp-vpc" {
  cidr_block       = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "Web-App VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidr_block)
  cidr_block        = element(var.public_subnet_cidr_block, count.index)
  availability_zone = element(var.availability_zones, count.index)
  vpc_id            = aws_vpc.webapp-vpc.id

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidr_block)
  cidr_block        = element(var.private_subnet_cidr_block, count.index)
  availability_zone = element(var.availability_zones, count.index)
  vpc_id            = aws_vpc.webapp-vpc.id

  tags = {
    Name = "Private Subnet"
  }
}

# Security groups
resource "aws_security_group" "load_balancer_sg" {
  name        = "load_balancer_sg"
  vpc_id      = aws_vpc.webapp-vpc.id

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

resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  vpc_id      = aws_vpc.webapp-vpc.id

  ingress {
    from_port   = var.web_server_port
    to_port     = var.web_server_port
    protocol    = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.5/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load balancer
resource "aws_lb" "webapp_alb" {
  name               = "webapp-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public_subnet.*.id
  security_groups    = [aws_security_group.load_balancer_sg.id]
}

# Target group
resource "aws_lb_target_group" "webapp_target_group" {
  name     = "webapp-target-group"
  port     = var.web_server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp-vpc.id
}

# Attach the target group to the load balancer
resource "aws_lb_listener" "webapp_listener" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_target_group.arn
  }
}

# Autoscaling group
resource "aws_autoscaling_group" "webapp_asg" {
  name                 = "webapp_asg"
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  vpc_zone_identifier  = aws_subnet.private_subnet.*.id
  launch_configuration = aws_launch_configuration.webapp_launch_config.name

  target_group_arns = [aws_lb_target_group.webapp_target_group.arn]

  # Scaling policies

  # Scale-up policy
  scaling_policy {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 180  # 3 minutes in seconds
    metric_aggregation_type = "Average"

    policy_type = "StepScaling"
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  # Scale-down policy
  scaling_policy {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 180  # 3 minutes in seconds
    metric_aggregation_type = "Average"

    policy_type = "StepScaling"
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  # Target tracking policy for CPU utilization
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0  # Target 50% CPU utilization
  }
}


# Launch configuration
resource "aws_launch_configuration" "webapp_launch_config" {
  image_id        = var.ami_id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
    #!/bin/bash

    # Install Ansible
    yum install -y ansible

    # Mounting secondary volume for logs
    mkdir /var/log
    mount /dev/xvdb /var/log

    # Copy the ansible-playbook to instance
    aws s3 cp s3://aws-east-1-webapp-bucket/WebApp.yaml /etc/ansible/WebApp.yaml

    # Run the Ansible playbook
    ansible-playbook -i "localhost," -c local /etc/ansible/WebApp.yaml
    EOF
}

# Instance volumes
resource "aws_ebs_volume" "primary_volume" {
  count             = var.autoscaling_group_size
  availability_zone = element(var.availability_zones, count.index)
  size              = 8
  type              = "gp2"

  # Encryption at rest (optional)
  kms_key_id = var.kms_key_arn

  tags = {
    Name = "Primary EBS Volume"
  }
}

resource "aws_volume_attachment" "primary_volume_attachment" {
  count       = var.autoscaling_group_size
  device_name = "/dev/sda1"
  volume_id   = element(aws_ebs_volume.primary_volume.*.id, count.index)
  instance_id = element(aws_autoscaling_group.webapp_asg.instances, count.index)
}

resource "aws_ebs_volume" "secondary_volume" {
  count             = var.autoscaling_group_size
  availability_zone = element(var.availability_zones, count.index)
  size              = 8
  type              = "gp2"

  tags = {
    Name = "Secondary EBS Volume for Logs"
  }
}

resource "aws_volume_attachment" "secondary_volume_attachment" {
  count       = var.autoscaling_group_size
  device_name = "/dev/sdb"
  volume_id   = element(aws_ebs_volume.secondary_volume.*.id, count.index)
  instance_id = element(aws_autoscaling_group.webapp_asg.instances, count.index)
}
