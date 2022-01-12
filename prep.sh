#!/bin/sh

sleep 30


############################## vars ####################################

###### aws temporary access #######

 export AWS_ACCESS_KEY_ID=XXXX
 export AWS_SECRET_ACCESS_KEY=XXXX
 export AWS_SESSION_TOKEN=XXXX
export AWS_REGION=eu-west-1

######### Specify key , region , ami 

KEY_PAIR=sauer-key
REGION=eu-west-1
AWS_AMI=ami-08ca3fed11864d6bb


############################## action ####################################


######## will be created automaticly
VPC_ID=vpc-xxx
PRIVATE_SUBNET=subnet-xxx
PUBLIC_SUBNET=subnet-xxxx
NODE_AZ=${REGION}a

########  tkg mgmt configuration ########
cat > vpc-mgmt.yaml << EOF
AWS_AMI_ID: ami-0f210a57e0be8c9ef
AWS_NODE_AZ: ${NODE_AZ}
AWS_NODE_AZ_1: ""
AWS_NODE_AZ_2: ""
AWS_PRIVATE_NODE_CIDR: ""
AWS_PRIVATE_NODE_CIDR_1: ""
AWS_PRIVATE_NODE_CIDR_2: ""
AWS_PRIVATE_SUBNET_ID: ${PRIVATE_SUBNET}  
AWS_PRIVATE_SUBNET_ID_1: ""
AWS_PRIVATE_SUBNET_ID_2: ""
AWS_PUBLIC_NODE_CIDR: ""
AWS_PUBLIC_NODE_CIDR_1: ""
AWS_PUBLIC_NODE_CIDR_2: ""
AWS_PUBLIC_SUBNET_ID: ${PUBLIC_SUBNET} 
AWS_PUBLIC_SUBNET_ID_1: ""
AWS_PUBLIC_SUBNET_ID_2: ""
AWS_REGION: ${REGION}
AWS_SSH_KEY_NAME: ${KEY_PAIR} 
AWS_VPC_CIDR: ""
AWS_VPC_ID: ${VPC_ID} 
BASTION_HOST_ENABLED: "false"
CLUSTER_CIDR: 100.96.0.0/11
CLUSTER_NAME: mgmt
CLUSTER_PLAN: dev
CONTROL_PLANE_MACHINE_TYPE: t3.xlarge
ENABLE_AUDIT_LOGGING: ""
ENABLE_CEIP_PARTICIPATION: "false"
ENABLE_MHC: "true"
IDENTITY_MANAGEMENT_TYPE: none
INFRASTRUCTURE_PROVIDER: aws
LDAP_BIND_DN: ""
LDAP_BIND_PASSWORD: ""
LDAP_GROUP_SEARCH_BASE_DN: ""
LDAP_GROUP_SEARCH_FILTER: ""
LDAP_GROUP_SEARCH_GROUP_ATTRIBUTE: ""
LDAP_GROUP_SEARCH_NAME_ATTRIBUTE: cn
LDAP_GROUP_SEARCH_USER_ATTRIBUTE: DN
LDAP_HOST: ""
LDAP_ROOT_CA_DATA_B64: ""
LDAP_USER_SEARCH_BASE_DN: ""
LDAP_USER_SEARCH_FILTER: ""
LDAP_USER_SEARCH_NAME_ATTRIBUTE: ""
LDAP_USER_SEARCH_USERNAME: userPrincipalName
NODE_MACHINE_TYPE: t3.xlarge
OIDC_IDENTITY_PROVIDER_CLIENT_ID: ""
OIDC_IDENTITY_PROVIDER_CLIENT_SECRET: ""
OIDC_IDENTITY_PROVIDER_GROUPS_CLAIM: ""
OIDC_IDENTITY_PROVIDER_ISSUER_URL: ""
OIDC_IDENTITY_PROVIDER_NAME: ""
OIDC_IDENTITY_PROVIDER_SCOPES: ""
OIDC_IDENTITY_PROVIDER_USERNAME_CLAIM: ""
OS_ARCH: amd64
OS_NAME: ubuntu
OS_VERSION: "20.04"
SERVICE_CIDR: 100.64.0.0/13
TKG_HTTP_PROXY_ENABLED: "false"
EOF

######## install Tanzu CLI/Tools ########

apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws s3 sync s3://installation-kit  /home/ubuntu


tar -xvf tanzu-cli-bundle-linux-amd64-1.tar

gzip -d kubectl-linux-v1.21.2+vmware.1-1.gz
gzip -d velero-linux-v1.6.2_vmware.1-1.gz



cd cli
sudo install core/v1.4.0/tanzu-core-linux_amd64 /usr/local/bin/tanzu

cd ..

tanzu plugin clean

tanzu plugin install --local cli all

sudo install kubectl-linux-v1.21.2+vmware.1-1 /usr/local/bin/kubectl

cd cli

gunzip ytt-linux-amd64-v0.34.0+vmware.1.gz
chmod ugo+x ytt-linux-amd64-v0.34.0+vmware.1
mv ./ytt-linux-amd64-v0.34.0+vmware.1 /usr/local/bin/ytt


gunzip kapp-linux-amd64-v0.37.0+vmware.1.gz
chmod ugo+x kapp-linux-amd64-v0.37.0+vmware.1
mv ./kapp-linux-amd64-v0.37.0+vmware.1 /usr/local/bin/kapp

gunzip kbld-linux-amd64-v0.30.0+vmware.1.gz
chmod ugo+x kbld-linux-amd64-v0.30.0+vmware.1
mv ./kbld-linux-amd64-v0.30.0+vmware.1 /usr/local/bin/kbld

gunzip imgpkg-linux-amd64-v0.10.0+vmware.1.gz
chmod ugo+x imgpkg-linux-amd64-v0.10.0+vmware.1
mv ./imgpkg-linux-amd64-v0.10.0+vmware.1 /usr/local/bin/imgpkg


cd ..

sudo apt-get install jq -y

sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

apt install docker-ce -y

tanzu management-cluster permissions aws set

sleep 10

tanzu management-cluster create --file vpc-mgmt.yaml -v 6

#sleep 30

#tanzu management-cluster upgrade -y

echo "mgmt cluster is up2date"

cp tmc_cli /usr/local/bin/tmc
chmod +x /usr/local/bin/tmc

### create a cluster ###

tanzu cluster create tap-cluster  --controlplane-machine-count 1 --worker-machine-count 3 --size t3.2xlarge -f vpc-mgmt.yaml 

tanzu cluster kubeconfig get tap-cluster  --admin

