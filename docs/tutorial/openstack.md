# Getting Started with kops on OpenStack

**WARNING**: OpenStack support on kops is currently **alpha** meaning it is in the early stages of development and subject to change, please use with caution.

## Source your openstack RC
The Cloud Config used by the kubernetes API server and kubelet will be constructed from environment variables in the openstack RC file. The openrc.sh file is usually located under `API access`.

```bash
source openstack.rc
```

**--OR--**
## Create config file
The config file contains the OpenStack credentials required to create a cluster. The config file has the following format:

```ini
[Default]
identity=<OS_AUTH_URL>
user=mk8s=<OS_USERNAME>
password=<OS_PASSWORD>
domain_name=<OS_USER_DOMAIN_NAME>
tenant_id=<OS_PROJECT_ID>

[Swift]
service_type=object-store
region=<OS_REGION_NAME>

[Cinder]
service_type=volumev3
region=<OS_REGION_NAME>

[Neutron]
service_type=network
region=<OS_REGION_NAME>

[Nova]
service_type=compute
region=<OS_REGION_NAME>
```

## Environment Variables

It is important to set the following environment variables:

```bash
export OPENSTACK_CREDENTIAL_FILE=<config-file> # where <config-file> is the path of the config file
export KOPS_STATE_STORE=swift://<bucket-name> # where <bucket-name> is the name of the Swift container to use for kops state

# this is required since OpenStack support is currently in alpha so it is feature gated
export KOPS_FEATURE_FLAGS="AlphaAllowOpenStack"
```

If your OpenStack does not have Swift you can use any other VFS store, such as S3.

## Creating a Cluster

```bash
# to see your etcd storage type
openstack volume type list

# coreos (the default) + flannel overlay cluster in Default
kops create cluster \
  --cloud openstack \
  --name my-cluster.k8s.local \
  --state ${KOPS_STATE_STORE} \
  --zones nova \
  --network-cidr 10.0.0.0/24 \
  --image <imagename> \
  --master-count=3 \
  --node-count=1 \
  --node-size <flavorname> \
  --master-size <flavorname> \
  --etcd-storage-type <volumetype> \
  --api-loadbalancer-type public \
  --topology private \
  --bastion \
  --ssh-public-key ~/.ssh/id_rsa.pub \
  --networking weave \
  --os-ext-net <externalnetworkname>

# to update a cluster
kops update cluster my-cluster.k8s.local --state ${KOPS_STATE_STORE} --yes

# to delete a cluster
kops delete cluster my-cluster.k8s.local --yes
```

#### Optional flags
* `--os-kubelet-ignore-az=true` Nova and Cinder have different availability zones, more information [Kubernetes docs](https://kubernetes.io/docs/concepts/cluster-administration/cloud-providers/#block-storage)
