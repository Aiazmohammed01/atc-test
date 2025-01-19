# Security Group for Launch Template
resource "aws_security_group" "eks_node_group_sg" {
  name        = "eks-node-group-sg"
  description = "Security group for EKS Node Group with public inbound access"
  vpc_id      = "vpc-0886c481c075e6936"

  # Inbound rules
  ingress {
    description = "Allow all inbound traffic (open to the public)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "eks-node-group-sg"
    Environment = "atc-test"
    Team        = "DevOps"
  }
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "ats-cluster"
  cluster_version = "1.31"

  bootstrap_self_managed_addons = false
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
  }


  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = "vpc-0886c481c075e6936"
  subnet_ids               = ["subnet-00dc9d84f40213196", "subnet-01f6f7b792dab4aaf", "subnet-0db8cef8d0f900455"]
  control_plane_subnet_ids = ["subnet-0d362ba445ce913a6", "subnet-0ff4692a31bfdf15a", "subnet-08bc2f076b0ef2392"]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.micro"]
  }

  eks_managed_node_groups = {
    atc = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 10
      desired_size = 1

      # Associate the security group with the node group
      additional_security_group_ids = [aws_security_group.eks_node_group_sg.id]
    }
  }

  tags = {
    Environment = "atc-test"
    Terraform   = "true"
  }
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}
