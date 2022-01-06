## PART 1: Automating TKG manager cluster on AWS with a click of a button

# The largest heading

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
