## Upgrading Kubernetes

Upgrading Kubernetes is easy with kops. The cluster spec contains a `kubernetesVersion`, so you can simply edit it with `kops edit`, and apply the updated configuration to your cluster.

The `kops upgrade` command also automates checking for and applying updates.

It is recommended to run the latest version of Kops to ensure compatibility with the target kubernetesVersion. When applying a Kubernetes minor version upgrade (e.g. `v1.5.3` to `v1.6.0`), you should confirm that the target kubernetesVersion is compatible with the [current Kops release](https://github.com/kubernetes/kops/releases).

Note: if you want to upgrade from a `kube-up` installation, please see the instructions for [how to upgrade kubernetes installed with kube-up](cluster_upgrades_and_migrations.md).

### Manual update

* `kops edit cluster $NAME`
* set the kubernetesVersion to the target version (e.g. `v1.3.5`)
* `kops update cluster $NAME` to preview, then `kops update cluster $NAME --yes`
* `kops rolling-update cluster $NAME` to preview, then `kops rolling-update cluster $NAME --yes`

### Automated update

* `kops upgrade cluster $NAME` to preview, then `kops upgrade cluster $NAME --yes`

In future the upgrade step will likely perform the update immediately (and possibly even without a
node restart), but currently you must:

* `kops update cluster $NAME` to preview, then `kops update cluster $NAME --yes`
* `kops rolling-update cluster $NAME` to preview, then `kops rolling-update cluster $NAME --yes`

Upgrade uses the latest Kubernetes version considered stable by kops, defined in `https://github.com/kubernetes/kops/blob/master/channels/stable`.


### Terraform Users

* `kops edit cluster $NAME`
* set the kubernetesVersion to the target version (e.g. `v1.3.5`)
* NOTE: The next 3 steps must all be run in the same directory
* `kops update cluster $NAME --target=terraform`
* `terraform plan`
* `terraform apply`
* `kops rolling-update cluster $NAME` to preview, then `kops rolling-update cluster $NAME --yes`

### Other Notes:
* In general, we recommend that you upgrade your cluster one minor release at a time (1.7 --> 1.8 --> 1.9).  Although jumping minor versions may work if you have not enabled alpha features, you run a greater risk of running into problems due to version deprecation. 

