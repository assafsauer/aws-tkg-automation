
# Tanzu TKG/TAP Automation 


This repository contains automation code for TKG installtion on AWS and automated TAP (Tanzu application Platform) installation.

![image](https://user-images.githubusercontent.com/22165556/148382955-88662ea3-0e7c-4af1-8e6f-413bde98b69c.png)



## PART 1: Automating TKG on AWS 

so what does it do ? 
1) it create jump server with all the Tanzu depencies/packages on a dedicated VPC/Subnets... (Terraform) 
2) create mgmt cluster and guest cluster on the same VPC as the jump server.
3) automation script for TAP (Tanzu application Platform) installation

```diff
1) edit the main.tf (mandatory var is only the keyname)

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

If you change the region then also change the AWS_AMI to map to an ubuntu image available in the region.

3) Edit the host.tf (Put in AMI if changed region from eu-west-1 and path to private key used for VM access)

resource "aws_instance" "tkg" {
  ami           = "**ami-0015a39e4b7c0966f**"
  instance_type = lookup(var.awsprops, "itype")
  associate_public_ip_address = true
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = ["${aws_security_group.mywebsecurity.id}"]
  key_name = lookup(var.awsprops, "keyname")
  availability_zone = lookup(var.awsprops, "availability_zone")


  connection {
      host        = aws_instance.tkg.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = "**${file("/path/to/your/private-key-pair.pem")}**"

...

4) export your AWS access and run terraform 

run: 
terraform init 
terraform plan 
terraform apply 

```
## PART 2: Automating TAP installation 

```diff
1) ssh to the jump box and run: "wget https://raw.githubusercontent.com/assafsauer/aws-tkg-automation/master/tap/tap.sh"
2) edit the vars , chmod and execute the script as root user (./tap.sh)

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
