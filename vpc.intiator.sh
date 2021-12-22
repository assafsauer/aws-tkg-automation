sed -i -e "s/VPC_ID=.*/VPC_ID=VAR_VPC_ID/g" prep.sh
sed -i -e "s/PRIVATE_SUBNET=.*/PRIVATE_SUBNET=VAR_PRIVATE_SUB/g" prep.sh
sed -i -e "s/PUBLIC_SUBNET=.*/PUBLIC_SUBNET=VAR_PUBLIC_SUBNET/g" prep.sh


VAR_VPC_ID=$(cat terraform.tfstate |grep -i "vpc_id" |  awk '{if(NR==1) print $2}' | sed "s/\"//g") 
sed -i -e 's/VAR_VPC_ID/'"$VAR_VPC_ID"'/g' prep.sh

VAR_PRIVATE_SUB=$(cat terraform.tfstate |grep -i "subnet/subnet" |  awk '{if(NR==1) print $2}' | sed 's/\,//' | sed "s/^.*\///g" | sed "s/\"//g")
sed -i -e 's/VAR_PRIVATE_SUB/'"$VAR_PRIVATE_SUB"'/g' prep.sh

VAR_PUBLIC_SUBNET=$(cat terraform.tfstate |grep -i "subnet_id" |  awk '{if(NR==1) print $2}' | sed 's/\,//'  | sed "s/\"//g")
sed -i -e 's/VAR_PUBLIC_SUBNET/'"$VAR_PUBLIC_SUBNET"'/g' prep.sh

