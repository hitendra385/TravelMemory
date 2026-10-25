# TravelMemory AWS Infrastructure

This Terraform project creates one VPC with a public web subnet and a private database subnet, an Internet Gateway, a NAT Gateway, route tables, security groups, IAM roles, and two Amazon Linux 2023 EC2 instances.

## Prerequisites

- Terraform 1.5 or later
- AWS CLI v2
- An AWS account with permissions to create the listed VPC, EC2, IAM, and networking resources
- An EC2 key pair already created in the target region
- Your current public IPv4 address in CIDR form (usually `/32`)

Authenticate with AWS IAM Identity Center (recommended):

```sh
aws configure sso --profile travelmemory
aws sso login --profile travelmemory
export AWS_PROFILE=travelmemory
aws sts get-caller-identity
```

Terraform uses the standard AWS credential chain. It does not store credentials in Terraform files. If your account uses another authentication method, configure the AWS CLI/profile accordingly before running Terraform.

## Configure and deploy

From this directory, copy `terraform.tfvars.example` to `terraform.tfvars`. Set `ssh_allowed_cidr` to your public IP with a `/32` mask and `ec2_key_pair_name` to the existing key pair name in the selected region. The example CIDR is reserved for documentation and must be replaced.

```sh
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Inspect the plan before applying. Terraform will create billable resources, especially the NAT Gateway and its Elastic IP, as well as two EC2 instances. Costs vary by region and usage. To remove the resources created by this project when finished:

```sh
terraform destroy
```

Terraform state can contain infrastructure details. Keep local state and `terraform.tfvars` out of version control; use an encrypted, access-controlled remote backend before collaborating or using this beyond a short-lived assignment.

## Access

The web instance accepts SSH only from `ssh_allowed_cidr`, and HTTP/HTTPS from the internet. The database instance has no public IP. MongoDB port `27017` is reachable only from the web instance's security group. SSH to the database through the web instance:

```sh
ssh -i /path/to/private-key.pem ec2-user@$(terraform output -raw web_public_ip)
```

From that session, connect to the private host using its private IP:

```sh
ssh -i /path/to/private-key.pem ec2-user@$(terraform output -raw database_private_ip)
```

Alternatively, use `ProxyJump` from your workstation, with the same key pair available locally:

```sh
ssh -i /path/to/private-key.pem \
  -o ProxyJump=ec2-user@$(terraform output -raw web_public_ip) \
  ec2-user@$(terraform output -raw database_private_ip)
```

Each EC2 instance has a separate IAM role with `AmazonSSMManagedInstanceCore` for Systems Manager Session Manager. No application-specific AWS permissions are granted. The private subnet routes outbound traffic through the NAT Gateway; it does not accept unsolicited internet connections.

After a successful apply, retrieve the assignment's required public IP with:

```sh
terraform output -raw web_public_ip
```