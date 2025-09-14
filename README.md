# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
This project demonstrates how to use Packer and Terraform to deploy a customizable, scalable web server in Azure.  
- Packer is used to build a reusable managed image.  
- Terraform is used to provision infrastructure (networking, load balancer, VMs) that consumes the image.  

### Getting Started
To use this project, you will:
1. Clone this repository
powershell
   git clone <your-repo-url>
   cd <your-repo-folder>/C1 - Azure Infrastructure Operations/project/starter_files

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
How to Run
1. Set Azure credentials (replace with your values):
-Powershell
   $env:ARM_CLIENT_ID="xxxx"
   $env:ARM_CLIENT_SECRET="xxxx"
   $env:ARM_SUBSCRIPTION_ID="xxxx"
   $env:ARM_TENANT_ID="xxxx"
2. Build the Packer image:
packer build .\server.json
3. Deploy infrastructure with Terraform:
terraform init
terraform plan -out solution.plan
terraform apply "solution.plan"
4. Get the Load Balancer IP:
terraform output lb_public_ip

## Customization
You can modify the deployment by editing the variables.tf file. For example:

vm_count - Change the number of virtual machines deployed.

vm_size - Adjust the VM SKU.

location - Update the Azure region (e.g., eastus, westus).

tags - Apply custom metadata tags for cost tracking or environment separation.

After updating variables, re-run:
terraform plan -out solution.plan
terraform apply "solution.plan"

### Output
After running packer build and terraform apply "solution.plan"`, the following infrastructure gets created in the Azuredevops resource group:
- Virtual Network + Subnet  
- Network Security Group (with rules to allow Load Balancer + VNet traffic, deny Internet)  
- Public IP and Load Balancer 
- Availability Set  
- Two Linux Virtual Machines created from the custom Packer image (udacityWebImage)  

Terraform Output:
-Powershell
Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:

lb_public_ip = "x.x.x.x"


