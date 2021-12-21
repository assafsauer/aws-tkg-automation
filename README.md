*** PART 1: Automating TKG manager cluster on AWS with a click of a button

```diff
edit the main.tf (mandatory var is only the key)

variable "awsprops" {
    default = {
    region = "eu-west-1"
    itype = "t3.large"
    publicip = true
    keyname = "sauer-key"
    availability_zone = "eu-west-1a"
  }
}

edit the prep.sh (add aws temp access)  


###### aws temporary access #######

export AWS_ACCESS_KEY_ID=ASIAxxxxx
export AWS_SECRET_ACCESS_KEY=7lqB4jx47kEXkxxxxx
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjELbxxxLxxxxxxx
export AWS_REGION=eu-west-1
 

run: 
terraform init 
terraform plan 
terraform apply 

```
*** PART 1: Automating TAP installation 
