# deploy-aws-using-terraform

##Files
1. main.tf – contains all the AWS Components that will be deployed with Terraform.
2. output.tf – displays the AWS-generated public loadbalancer hostname.
3. vars.tf – This file contains all the variables that are used in the other tf files.
4. WebApp.yaml – ansible playbook that handles webserver and web application deployment into instances.
5. user_script.sh – contains the user inputs which to launch the instances. This ensures that the instance has all of the required prerequisites.

## Module Inputs:

Required:
    vpc_cidr_block: The CIDR block for the VPC (e.g., "10.0.0.0/16").
    public_subnet_cidr_blocks: A list of CIDR blocks for the public subnets (e.g., ["10.0.10.0/24", "10.0.20.0/24"]).
    private_subnet_cidr_blocks: A list of CIDR blocks for the private subnets (e.g., ["10.0.30.0/24", "10.0.40.0/24"]).
    availability_zones: A list of availability zones to use for the subnets (e.g., ["us-east-1a", "us-east-1b"]).
    instance_type: The instance type to use for the web servers (e.g., "t2.micro").
    ami_id: The AMI ID to use for the web servers.
    web_server_port: The port on which the web server will listen (e.g., 80).

Optional:
    kms_key_arn: The ARN of the KMS key to use for EBS encryption (for data encryption at rest).
    cloudwatch_alarm_threshold: The CPU utilization threshold for triggering a CloudWatch alarm (for optional autoscaling).

## Design Decisions:
    User Data Script for Configuration: Uses a user data script to execute Ansible on the instances for configuration management, promoting consistency and avoiding manual steps.
    Separate Volume for Logs: Attaches a secondary EBS volume specifically for storing application logs, aiding in log management and analysis.
    Security Groups for Controlled Access: Implements security groups to restrict traffic and enhance security.
    Encryption at Rest (Optional): Provides the option to enable encryption at rest for EBS volumes using a KMS key, protecting sensitive data.
    CloudWatch Alarms and Autoscaling (Optional): Allows for configuration of CloudWatch alarms to trigger autoscaling actions based on CPU utilization, ensuring application scalability and performance.
    The following policies are put into place to scale up and scale down. If the CPU utilization exceeds 80% in the autoscaling groups setups, the scale up will be triggered. The cooldown period is kept 3 minutes; if the CPU utilization is 50%, scale down will be triggered.

## Additional Considerations:
    BASTION HOST: Consider using a bastion host for secure access to instances within private subnets.
    ENCRYPTION ARN : Added a dummy ARN to the script; when deploying the solution, replace the ARN Value with the KMS Generated one.
    CIDR BLOCKS : Check the availability of the provided CIDR blocks in the target AWS account prior deploying this solution. If those are not available, consider updating the CIDR blocks based on availability in the vars.tf file.