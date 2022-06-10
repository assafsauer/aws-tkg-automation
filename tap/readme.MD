
1) the script required access to Tanzu Registry, your registry, and a Pivotal token to download the packages automaticly with pivnet CLI:

<img width="786" alt="image" src="https://user-images.githubusercontent.com/22165556/173012432-3dab1ead-8245-4a88-bf75-b3ab262f2b7d.png">

```
mgmt_cluster=mgmt #mgmt cluster
cluster=tap-cluster-3  #target cluster
tap_namespace=default 


export HARBOR_USER=tanzu
export HARBOR_PWD=XX
export HARBOR_DOMAIN=harbor.source-lab.io

export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=XXXX
export INSTALL_REGISTRY_PASSWORD=XXX

token=XXX  # Pivotal Token
domain=source-lab.io #ingress domain
```


2) change the ID to the right version:

```
###  TAP Version ####
VERSION=v0.11.2
tap_version=1.1.0
framework_linux_md64=1212839
gui_blank_Catalog=1099786
gui_Yelb_Catalog=1073911
```

<img width="1145" alt="image" src="https://user-images.githubusercontent.com/22165556/173010531-43e8a3f4-f9e8-440b-9682-8dfec5f3983d.png">
