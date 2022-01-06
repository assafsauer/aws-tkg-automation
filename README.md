# PART 1: Automating TKG manager cluster on AWS with a click of a button

## This repository contains automation code for TKG installtion on AWS and TAP (Tanzu application Platform) installation.

so what does it do ? 
1) it create jump server with all the Tanzu depencies/packages on a dedicated VPC/Subnets...
2) the script autoamte creation of mgmt cluster and guest cluster on the same VPC as the jump server.
3) automate AP (Tanzu application Platform) installation

```diff
1) edit the main.tf (mandatory var is only the key)

variable "awsprops" {
    default = {
    region = "eu-west-1"
    itype = "t3.large"
    publicip = true
    keyname = "sauer-key"
    availability_zone = "eu-west-1a"
  }
}

2) edit the prep.sh (add aws temp access)  


export AWS_ACCESS_KEY_ID=ASIAxxxxx
export AWS_SECRET_ACCESS_KEY=7lqB4jx47kEXkxxxxx
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjELbxxxLxxxxxxx
export AWS_REGION=eu-west-1

3) export your AWS access and run terraform 

run: 
terraform init 
terraform plan 
terraform apply 

```
## PART 2: Automating TAP installation 

```diff
1) ssh to the jump box and run: "wget https://raw.githubusercontent.com/assafsauer/aws-tkg-automation/master/tap/tap.sh"
2) edit the vars , chmod and execute the script (./tap.sh)

# /bin/bash

### vars ###

mgmt_cluster=mgmt
cluster=tap-cluster
tap_namespace=default


export HARBOR_USER=XXX
export HARBOR_PWD=XXX
export HARBOR_DOMAIN=harbor_my_domain.com

export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=XXX
export INSTALL_REGISTRY_PASSWORD=XXXX

token=XXXX
domain=my_domain.com

### optional: TAP GUI ####
git_token=XXXXXX
catalog_info=https://github.com/XXXXX/catalog-info.yaml
