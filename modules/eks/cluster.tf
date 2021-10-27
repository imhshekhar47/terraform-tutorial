# Reference: https://registry.terraform.io/providers/hashicorp/aws/2.34.0/docs/guides/eks-getting-started

variable "common_tags" {
    type = map(string)

    default = {
      component = "eks"
    }
}

variable "eks_dtl" {
    description = "VPC details for the eks"
    type = object({
        name = string
        vpc_id = string
        subnet_ids = list(string)
    })
}

data "aws_region" "eks_region" {}

# EKS Master IAM role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"  
    Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }
    ] 
    })

    tags = merge(var.common_tags, {
      node = "master"
    })
}

resource "aws_iam_role_policy_attachment" "cluster_iam_eksclusterpolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "cluster_iam_eksservicepolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    role = aws_iam_role.eks_cluster_role.name
}



# EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
    depends_on = [
      aws_iam_role_policy_attachment.cluster_iam_eksclusterpolicy,
      aws_iam_role_policy_attachment.cluster_iam_eksservicepolicy
    ]
    
    name = var.eks_dtl.name
    role_arn = aws_iam_role.eks_cluster_role.arn

    vpc_config {
      subnet_ids = var.eks_dtl.subnet_ids
      #security_group_ids = [ aws_security_group.master_sg.id ]
    }

    tags = merge(var.common_tags, {
      node = "master"
    })
}


# EKS Master kubeconfig
locals {
  eks_arn = aws_eks_cluster.eks_cluster.arn
  kubeconfig=<<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks_cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks_cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - --region
      - ${data.aws_region.eks_region.name}
      - eks
      - get-token
      - --cluster-name
      - "${var.eks_dtl.name}"
      command: aws
  KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

resource "local_file" "eks_kubeonfig" {
    content = "${local.kubeconfig}"
    filename = ".config/eks-kubeconfig.yaml"
}

output "eks_endpoint" {
    value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_kubeconfig_certauthdata" {
    value = aws_eks_cluster.eks_cluster.certificate_authority
}


# EKS Worker node
resource "aws_iam_role" "eks_worker_role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
          {
              Action = "sts:AssumeRole"
              Effect = "Allow"
              Principal = {
                  Service = "ec2.amazonaws.com"
              }
          }
      ]
  })

  tags = merge(var.common_tags, {
      node = "worker"
  })
}

resource "aws_iam_role_policy_attachment" "worker_iam_nodepolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks_worker_role.name
}

resource "aws_iam_role_policy_attachment" "worker_iam_cnipolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.eks_worker_role.name
  
}

resource "aws_iam_role_policy_attachment" "worker_iam_registrypolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks_worker_role.name
}

resource "aws_iam_instance_profile" "worker_node_profile" {
  name = "worker-node"
  role = aws_iam_role.eks_worker_role.name
}

resource "aws_eks_node_group" "eks_nodes" {
    depends_on = [
      aws_iam_role_policy_attachment.worker_iam_nodepolicy,
      aws_iam_role_policy_attachment.worker_iam_cnipolicy,
      aws_iam_role_policy_attachment.worker_iam_registrypolicy,
    ]
    
    cluster_name = aws_eks_cluster.eks_cluster.name
    node_group_name = "eks-nodes"
    node_role_arn = aws_iam_role.eks_worker_role.arn
    subnet_ids = var.eks_dtl.subnet_ids
    instance_types = ["t3.micro"]

    scaling_config {
      desired_size = 2
      min_size = 1
      max_size = 4
    }

    update_config {
      max_unavailable = 1
    }
}




