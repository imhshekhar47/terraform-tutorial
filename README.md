# Terraform Tutorial


## Packer
Packer is another HashiCorp tool that help us in buildig AMIs.
```bash
cd "$(pwd)/ami"
packer init .
packer validate .
packer build app-ui.pkr.hcl # publishes AMI to AWS
```

## Cheatsheet
```bash
terraform plan
terraform apply
terraform state list
terraform state show module.vpc.aws_vpc.hs_vpc
terraform destroy -target=module.vpc.aws_vpc.hs_vpc
```

---

# Working with Kubernetes
To keep the the Kubernetes config separate from any of your local Kubernetes cluster you can define KUBECONFIG environment variables.

```bash
# Create a local kube config directory
mkdir .config
# Let kubectl know where to look for kube config 
export KUBECONFIG=./config/eks-kubeconfig.yaml
# Update the kubeconfig once EKS is ready
aws eks update-kubeconfig --name <cluster-name>
```
