# Terraform Tutorial


## Packer
Packer is another HashiCorp tool that help us in buildig AMIs.
```bash
cd "$(pwd)/ami"
packer init .
packer validate .
packer build app-ui.pkr.hcl
```

## Cheatsheet
```bash
terraform plan
terraform apply
terraform state list
terraform state show module.vpc.aws_vpc.hs_vpc
terraform destroy -target=module.vpc.aws_vpc.hs_vpc
```
