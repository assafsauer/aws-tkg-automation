
#!/bin/sh

sleep 30

 export AWS_ACCESS_KEY_ID=ASIAxxxxx
 export AWS_SECRET_ACCESS_KEY=7lqB4jx47kEXkxxxxx
 export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjELb//////////wEaCXVzLxxxxxxx
 
 export AWS_REGION=eu-west-1
 
 
 
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

#tanzu management-cluster create -b 192.168.1.76:80 --ui 6
