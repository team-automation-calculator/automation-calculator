terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.34.0"
    }
  }
}

# Configure the AWS Provider
# Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables to authenticate
provider "aws" {
  region = "us-west-1"
}

# Declare vars
variable "project_tag" {
  type = string
  default = "automation-calculator"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.213.0.0/16"
  tags = {
    project_name = var.project_tag
  }
}

resource "aws_subnet" "main_1a" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.213.0.0/24"
  availability_zone = "us-west-1a"

  tags = {
    project_name = var.project_tag
  }
}

resource "aws_subnet" "main_1c" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.213.1.0/24"
  availability_zone = "us-west-1c"

  tags = {
    project_name = var.project_tag
  }
}

# Create IAM role for EKS
resource "aws_iam_role" "eks_iam_role" {
  name = "automation_calculator_eks_iam_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = {
    project_name = var.project_tag
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_iam_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name = "automation_calculator_eks_cluster"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.main_1a.id, aws_subnet.main_1c.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    project_name = var.project_tag
  }
}
