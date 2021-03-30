# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.213.0.0/16"
}

resource "aws_subnet" "main_1a" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.213.0.0/24"
  availability_zone = "us-west-1a"
}

resource "aws_subnet" "main_1c" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.213.1.0/24"
  availability_zone = "us-west-1c"
}

# Create IAM role for EKS
resource "aws_iam_role" "eks_iam_role" {
  name = "automation_calculator_eks_iam_role_${var.environment_name}"

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
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_iam_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name = "automation_calculator_eks_cluster_${var.environment_name}"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.main_1a.id, aws_subnet.main_1c.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
