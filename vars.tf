variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24" ]
}

variable "private_subnet_cidr_block" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.40.0/24"]
}

variable "availability_zones" {
  description = "The availability zones to use for the subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "The instance type to use for the web servers"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "The AMI ID to use for the web servers"
  type        = string
  default     = "ami-0c55b159cbfa5e48f"  # Latest Amazon Linux 2 AMI
}

variable "web_server_port" {
  description = "The port on which the web server will listen"
  type        = number
  default     = 80
}

variable "ansible_playbook_path" {
  description = "The path to the Ansible playbook to run on the instances"
  type        = string
  default     = "/etc/ansible/WebApp.yaml"
}

variable "autoscaling_group_size" {
  description = "The initial number of instances in the autoscaling group"
  type        = number
  default     = 2
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for EBS encryption"
  type        = string
  default     = "arn:aws:kms:us-east-1:98765432123:key/my-key"  #Added Dummy ARN
}

variable "cloudwatch_alarm_threshold" {
  description = "The CPU utilization threshold for triggering a CloudWatch alarm"
  type        = number
  default     = 80
}
