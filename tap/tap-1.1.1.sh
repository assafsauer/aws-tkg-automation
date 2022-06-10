# /bin/bash


################## vars ##################
##########################################

mgmt_cluster=mgmt
cluster=tap-cluster-4
tap_namespace=default


export HARBOR_USER=tanzu
export HARBOR_PWD=xxxx
export HARBOR_DOMAIN=harbor.source-lab.io

export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=xxxx
export INSTALL_REGISTRY_PASSWORD=xx

token=xxxxx 
domain=source-lab.io

###  TAP Version ####
VERSION=v0.11.4 #folder core version
tap_version=1.1.1
framework_linux_md64=1212839
gui_blank_Catalog=1099786
gui_Yelb_Catalog=1073911



### optional: TAP GUI ####
git_token=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
catalog_info=https://github.com/assafsauer/tap-catalog/blob/main/catalog-info.yaml




################## Templating tap values ##################
###########################################################


cat > tap-values.yml << EOF
profile: full
buildservice:
  kp_default_repository: $HARBOR_DOMAIN/tap/build-service
  kp_default_repository_username: $HARBOR_USER
  kp_default_repository_password: $HARBOR_PWD
  tanzunet_username: $INSTALL_REGISTRY_USERNAME
  tanzunet_password: $INSTALL_REGISTRY_PASSWORD
supply_chain: basic
ootb_supply_chain_basic:
  registry:
    server: $HARBOR_DOMAIN
    repository: "tap/supply-chain"
contour:
  infrastructure_provider: aws
  envoy:
    service:
      aws:
        LBType: nlb
cnrs:
  domain_name: apps.$domain
image_policy_webhook:
   allow_unmatched_images: true
learningcenter:
  ingressDomain: learn.apps.$domain
  storageClass: "default"
tap_gui:
  service_type: LoadBalancer
ceip_policy_disclosed: true
accelerator:
  service_type: "LoadBalancer"
appliveview:
  connector_namespaces: [default]
  service_type: LoadBalancer
metadata_store:
  app_service_type: LoadBalancer
EOF


################## Download TAP packeges ##################
###########################################################

### login to pivotal network ###

wget  https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1
chmod 777 pivnet-linux-amd64-3.0.1
cp pivnet-linux-amd64-3.0.1 /usr/local/bin/pivnet
pivnet login --api-token=$token

#### Download TAP 4.0 ####


### download tanzu-CLI -tanzu-framework-linux-amd64.tar
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version=$tap_version --product-file-id=$framework_linux_md64

### GUI catalog:  tap-gui-yelb-catalog.tgz , tap-gui-blank-catalog.tgz

pivnet download-product-files --product-slug='tanzu-application-platform' --release-version=$tap_version --product-file-id=$gui_blank_Catalog
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version=$tap_version --product-file-id=$gui_Yelb_Catalog



################## K8s Prep  ##################
###############################################


##### confirm K8s cluster requirements before execution ####

echo "Minimum requirements for tap: 4 CPUs , 16 GB RAM and at least 3 nodes"

node=$(kubectl get nodes | awk '{if(NR==2) print $1}')
kubectl describe nodes $node | grep -A 7 Capacity:


read -p "does your Kubernetes cluster meet the requirements? (enter: yes to continue)"
if [ "$REPLY" != "yes" ]; then
   exit
fi

echo "starting installation"

### patch mgmt cluster ###

kubectl config use-context $mgmt_cluster"-admin@"$mgmt_cluster

kubectl patch "app/"$cluster"-kapp-controller" -n default -p '{"spec":{"paused":true}}' --type=merge

kubectl config use-context $cluster"-admin@"$cluster

kubectl create clusterrolebinding default-tkg-admin-privileged-binding --clusterrole=psp:vmware-system-privileged



### create storageclass ###

cat > storage-class.yml << EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: default
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/aws-ebs
EOF

kubectl apply -f storage-class.yml



################## update tap plugins ##################
###########################################################


mkdir tanzu
tar -xvf tanzu-framework-linux-amd64.tar -C tanzu/
cd tanzu
export TANZU_CLI_NO_INIT=true
tanzu plugin delete imagepullsecret
#tanzu config set features.global.context-aware-cli-for-plugins false

install cli/core/$VERSION/tanzu-core-linux_amd64 /usr/local/bin/tanzu
tanzu plugin install --local cli all

#tanzu plugin install secret --local ./cli
#tanzu plugin install accelerator --local ./cli
#tanzu plugin install apps --local ./cli
#tanzu plugin install package --local ./cli
#tanzu plugin install services --local ./cli
cd ..




### cluster prep ###

kubectl create ns tap-install

kubectl delete deployment kapp-controller -n tkg-system
kubectl apply -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.29.0/release.yml

kubectl create ns secretgen-controller
kubectl apply -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/latest/download/release.yml

#kapp deploy -y -a sg -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.6.0/release.yml



#### RBAC ####

curl -LJO https://raw.githubusercontent.com/assafsauer/aws-tkg-automation/master/tap/tap-role.yml
kubectl apply -f tap-role.yml -n $tap_namespace



################## Secrets ##################
#############################################

#### validating access /exist script if login fail #####


echo "checking credentials for Tanzu Network and Regsitry"
if docker login -u ${HARBOR_USER} -p ${HARBOR_PWD} ${HARBOR_DOMAIN}; then
  echo "login successful to" ${HARBOR_DOMAIN}  >&2
else
  ret=$?
  echo "########### exist installation , please change credentials for  ${HARBOR_DOMAIN} $ret" >&2
  exit $ret
fi


if docker login -u ${INSTALL_REGISTRY_USERNAME} -p ${INSTALL_REGISTRY_PASSWORD} ${INSTALL_REGISTRY_HOSTNAME}; then
  echo "login successful to" ${INSTALL_REGISTRY_HOSTNAME} >&2
else
  ret=$?
  echo "########### exist installation , please change credentials for ${INSTALL_REGISTRY_HOSTNAME} $ret" >&2
  exit $ret
fi


#### adding secrets #####

tanzu secret registry add tap-registry \
  --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} \
  --server ${INSTALL_REGISTRY_HOSTNAME} \
  --export-to-all-namespaces --yes --namespace tap-install

tanzu secret registry add tap-registry-2 \
  --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} \
  --server registry.pivotal.io  \
  --export-to-all-namespaces --yes --namespace tap-install

tanzu secret registry add harbor-registry -y \
--username ${HARBOR_USER} --password ${HARBOR_PWD} \
--server ${HARBOR_DOMAIN}  \
 --export-to-all-namespaces --yes --namespace tap-install


### temp workaround for the "ServiceAccountSecretError" issue
kubectl create secret docker-registry registry-credentials --docker-server=${HARBOR_DOMAIN} --docker-username=${HARBOR_USER} --docker-password=${HARBOR_PWD} -n default

echo "your harbor cred"
kubectl get secret registry-credentials --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode


tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:$tap_version \
  --namespace tap-install



##################  TAP installation ##################
#######################################################


echo "starting installtion in 10 sec (Please be patient as it might take few min to complete)"
sleep 10

tanzu package install tap -p tap.tanzu.vmware.com -v $tap_version --values-file tap-values.yml -n tap-install


echo "might take few min to complete"



#### install TAP GUI ####

read -p "would you like to setup TAP GUI ? (enter: yes to continue)"
if [ "$REPLY" != "yes" ]; then
   exit
fi


tap_domain=$(kubectl get svc -n tap-gui |awk 'NR=='2'{print $4}')

cat > tap-gui-values.yml << EOF
profile: full
buildservice:
  kp_default_repository: $domain/tap/build-service
  kp_default_repository_username: $HARBOR_USER
  kp_default_repository_password: $HARBOR_PWD
  tanzunet_username: $INSTALL_REGISTRY_USERNAME
  tanzunet_password: $INSTALL_REGISTRY_PASSWORD
supply_chain: basic
ootb_supply_chain_basic:
  registry:
    server: $HARBOR_DOMAIN
    repository: "tap/supply-chain"

ootb_supply_chain_testing:
 registry:
  server: $HARBOR_DOMAIN 
  repository: "tap/supply-chain"

ootb_supply_chain_testing_scanning:
 registry:
  server: $HARBOR_DOMAIN 
  repository: "tap/supply-chain"
grype:
  targetImagePullSecret: "supply-chain"
contour:
  infrastructure_provider: aws
  envoy:
    service:
      aws:
        LBType: nlb
tap_gui:
  service_type: LoadBalancer
  #ingressEnabled: "true"
  #ingressDomain: tap-gui.source-lab.io
  app_config:
    organization:
      name: asauer
    app:
      title: asauer
      baseUrl: http://$tap_domain:7000
    integrations:
      github:
      - host: github.com
        token: $git_token
    catalog:
      locations:
        - type: url
          target: $catalog_info
    backend:
        baseUrl: http://$tap_domain:7000
        cors:
            origin: http://$tap_domain:7000
cnrs:
  domain_name: apps.$domain
image_policy_webhook:
   allow_unmatched_images: true
learningcenter:
  ingressDomain: learn.apps.$domain
  storageClass: "default"
tap_gui:
  service_type: LoadBalancer
ceip_policy_disclosed: true
accelerator:
  service_type: "LoadBalancer"
appliveview:
  connector_namespaces: [default]
  service_type: LoadBalancer
metadata_store:
  app_service_type: LoadBalancer
EOF


tanzu package installed update --install tap -p tap.tanzu.vmware.com -v $tap_version -n tap-install --poll-timeout 30m -f tap-gui-values.yml

sleep 30

echo "done,  It might take few minutes to complete "




read -p "ready to test? (enter: yes to continue)"
if [ "$REPLY" != "yes" ]; then
   exit
fi





#### Test ####

echo "run test (Please be patient as it might take few min to complete) "

git clone https://github.com/assafsauer/spring-petclinic-accelerators.git

tanzu apps workload create petclinic --local-path spring-petclinic-accelerators  --type web --label app.kubernetes.io/part-of=spring-petclinic-accelerators --source-image harbor.source-lab.io/tap/app --yes


tanzu apps workload tail petclinic  & sleep 400 ; kill $!


url=$(tanzu apps workload get petclinic |grep http| awk 'NR=='1'{print $3}')
ingress=$( kubectl get svc -A |grep tanzu-system-ingress |grep LoadBalancer | awk 'NR=='1'{print $5}')
ip=$(nslookup $ingress |grep Address |grep -v 127 | awk '{print $2}')

echo "########## please update your DNS as follow: ###########"
echo *app.$domain "pointing to" $ip


read -p "ready to test again? (enter: yes to continue)"
if [ "$REPLY" != "yes" ]; then
   exit
fi

curl -k $url

echo "done"
#tanzu apps workload list
