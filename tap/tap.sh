# /bin/bash

# tanzu cluster create tap-cluster --controlplane-machine-count 1 --worker-machine-count 3 -f mgmt.yaml
# tanzu cluster kubeconfig get tap-cluster --admin


### vars ###

### vars ###

mgmt_cluster=mgmt
cluster=tap-cluster
tap_namespace=default

export HARBOR_USER=xx
export HARBOR_PWD=xx
export HARBOR_DOMAIN=xxx

export INSTALL_REGISTRY_HOSTNAME=xx
export INSTALL_REGISTRY_USERNAME=xxx
export INSTALL_REGISTRY_PASSWORD=xx

token=xxxxx pivotal token xxxx

cat > tap-values.yml << EOF
profile: full
buildservice:
  kp_default_repository: "source-lab.io/tap/build-service"
  kp_default_repository_username: "xxx"
  kp_default_repository_password: "xxx"
  tanzunet_username: "xxx"
  tanzunet_password: "xxx"
supply_chain: basic
ootb_supply_chain_basic:
  registry:
    server: "source-lab.io"
    repository: "tap"
cnrs:
  provider: local
learningcenter:
  ingressDomain: "tap-learn.source-lab.io"
  storageClass: "default"
contour:
  infrastructure_provider: aws
  envoy:
    service:
      aws:
        LBType: nlb
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


### download tap packages ###

wget  https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1
chmod 777 pivnet-linux-amd64-3.0.1
cp pivnet-linux-amd64-3.0.1 /usr/local/bin/pivnet
pivnet login --api-token=$token



#### TAP 4.0

### download tanzu-CLI -tanzu-framework-linux-amd64.tar
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='0.4.0' --product-file-id=1100110
### insight insight-1.0.0-beta.2_linux_amd64
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='0.4.0' --product-file-id=1101070

### GUI catalog:  tap-gui-yelb-catalog.tgz , tap-gui-blank-catalog.tgz
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='0.4.0' --product-file-id=1073911
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='0.4.0' --product-file-id=1099786

pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='0.4.0' --product-file-id=1098740




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


#### install packages ###

mkdir tanzu
tar -xvf tanzu-framework-linux-amd64.tar -C tanzu/
cd tanzu
export TANZU_CLI_NO_INIT=true
tanzu plugin delete imagepullsecret
tanzu config set features.global.context-aware-cli-for-plugins false

tanzu plugin install secret --local ./cli
tanzu plugin install accelerator --local ./cli
tanzu plugin install apps --local ./cli
tanzu plugin install package --local ./cli
tanzu plugin install services --local ./cli
cd ..

### cluster prep ###

kubectl create ns tap-install

kubectl delete deployment kapp-controller -n tkg-system
kubectl apply -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.29.0/release.yml

kubectl create ns secretgen-controller
kubectl apply -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/latest/download/release.yml

#kapp deploy -y -a sg -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.6.0/release.yml




#### RBAC ####

cat > tap-rbac.yml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: tap-registry
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
secrets:
  - name: registry-credentials
imagePullSecrets:
  - name: registry-credentials
  - name: tap-registry
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: default
rules:
- apiGroups: [source.toolkit.fluxcd.io]
  resources: [gitrepositories]
  verbs: ['*']
- apiGroups: [source.apps.tanzu.vmware.com]
  resources: [imagerepositories]
  verbs: ['*']
- apiGroups: [carto.run]
  resources: [deliverables, runnables]
  verbs: ['*']
- apiGroups: [kpack.io]
  resources: [images]
  verbs: ['*']
- apiGroups: [conventions.apps.tanzu.vmware.com]
  resources: [podintents]
  verbs: ['*']
- apiGroups: [""]
  resources: ['configmaps']
  verbs: ['*']
- apiGroups: [""]
  resources: ['pods']
  verbs: ['list']
- apiGroups: [tekton.dev]
  resources: [taskruns, pipelineruns]
  verbs: ['*']
- apiGroups: [tekton.dev]
  resources: [pipelines]
  verbs: ['list']
- apiGroups: [kappctrl.k14s.io]
  resources: [apps]
  verbs: ['*']
- apiGroups: [serving.knative.dev]
  resources: ['services']
  verbs: ['*']
- apiGroups: [servicebinding.io]
  resources: ['servicebindings']
  verbs: ['*']
- apiGroups: [services.apps.tanzu.vmware.com]
  resources: ['resourceclaims']
  verbs: ['*']
- apiGroups: [scst-scan.apps.tanzu.vmware.com]
  resources: ['imagescans', 'sourcescans']
  verbs: ['*']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: default
subjects:
  - kind: ServiceAccount
    name: default
EOF


kubectl apply -f tap-rbac.yml -n $tap_namespace


#### access #####

docker login -u ${HARBOR_USER} -p ${HARBOR_PWD} ${HARBOR_DOMAIN}
docker login -u ${INSTALL_REGISTRY_USERNAME} -p ${INSTALL_REGISTRY_PASSWORD} ${INSTALL_REGISTRY_HOSTNAME}


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
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:0.4.0 \
  --namespace tap-install


#### install ####


tanzu package installed update --install tap -p tap.tanzu.vmware.com -v 0.4.0 -n tap-install --poll-timeout 30m -f tap-values.yml

echo "Cross your fingers and pray , or call Timo"


read -p "read to test? (enter: yes to continue)"
if [ "$REPLY" != "yes" ]; then
   exit
fi



#### test ####
echo "run test"

git clone https://github.com/assafsauer/spring-petclinic-accelerators.git

tanzu apps workload create petclinic --local-path spring-petclinic-accelerators  --type web --label app.kubernetes.io/part-of=spring-petclinic-accelerators --source-image source-lab.io/tap/app --yes

tanzu apps workload tail petclinic

echo "done"
#tanzu apps workload list
