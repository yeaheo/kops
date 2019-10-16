## Addons Management

kops incorporates management of some addons; we _have_ to manage some addons which are needed before
the kubernetes API is functional.

In addition, kops offers end-user management of addons via the `channels` tool (which is still experimental,
but we are working on making it a recommended part of kubernetes addon management).  We ship some
curated addons in the [addons directory](/addons), more information in the [addons document](addons.md).


kops uses the `channels` tool for system addon management also.  Because kops uses the same tool
for *system* addon management as it does for *user* addon management, this means that
addons installed by kops as part of cluster bringup can be managed alongside additional addons.
(Though note that bootstrap addons are much more likely to be replaced during a kops upgrade).

The general kops philosophy is to try to make the set of bootstrap addons minimal, and
to make installation of subsequent addons easy.

Thus, `kube-dns` and the networking overlay (if any) are the canonical bootstrap addons.
But addons such as the dashboard or the EFK stack are easily installed after kops bootstrap,
with a `kubectl apply -f https://...` or with the channels tool.

In future, we may as a convenience make it easy to add optional addons to the kops manifest,
though this will just be a convenience wrapper around doing it manually.

## Update BootStrap Addons

If you want to update the bootstrap addons, you can run the following command to show you which addons need updating. Add `--yes` to actually apply the updates.

**channels apply channel s3://*KOPS_S3_BUCKET*/*CLUSTER_NAME*/addons/bootstrap-channel.yaml**


## Versioning

The channels tool adds a manifest-of-manifests file, of `Kind: Addons`, which allows for a description
of the various manifest versions that are available.  In this way kops can manage updates
as new versions of the addon are released.  For example,
the [dashboard addon](https://github.com/kubernetes/kops/blob/master/addons/kubernetes-dashboard/addon.yaml)
lists multiple versions.

For example, a typical addons declaration might looks like this:

```
  - version: 1.4.0
    selector:
      k8s-addon: kubernetes-dashboard.addons.k8s.io
    manifest: v1.4.0.yaml
 - version: 1.5.0
    selector:
      k8s-addon: kubernetes-dashboard.addons.k8s.io
    manifest: v1.5.0.yaml
```

That declares two versions of an addon, with manifests at `v1.4.0.yaml` and at `v1.5.0.yaml`.
These are evaluated as relative paths to the Addons file itself.  (The channels tool supports
a few more protocols than `kubectl` - for example `s3://...` for S3 hosted manifests).

The `version` field gives meaning to the alternative manifests.  This is interpreted as a
semver.  The channels tool keeps track of the current version installed (currently by means
of an annotation on the `kube-system` namespace).

The channel tool updates the installed version when any of the following conditions apply.
* The version declared in the addon manifest is greater then the currently installed version.
* The version number's match, but the ids are different
* The version number and ids match, but the hash of the addon's manifest has changed since it was installed.


This means that a user can edit a deployed addon, and changes will not be replaced, until a new version of the addon is installed. The long-term direction here is that addons will mostly be configured through a ConfigMap or Secret object, and that the addon manager will (TODO) not replace the ConfigMap.

The `selector` determines the objects which make up the addon.  This will be used
to construct a `--prune` argument (TODO), so that objects that existed in the
previous but not the new version will be removed as part of an upgrade.

## Kubernetes Version Selection

The addon manager now supports a `kubernetesVersion` field, which is a semver range specifier
on the kubernetes version.  If the targeted version of kubernetes does not match the semver
specified, the addon version will be ignored.

This allows you to have different versions of the manifest for significant changes to the
kubernetes API.  For example, 1.6 changed the taints & tolerations to a field, and RBAC moved
to beta.  As such it is easier to have two separate manifests.

For example:

```
  - version: 1.5.0
    selector:
      k8s-addon: kube-dashboard.addons.k8s.io
    manifest: v1.5.0.yaml
    kubernetesVersion: "<1.6.0"
    id: "pre-k8s-16"
 - version: 1.6.0
    selector:
      k8s-addon: kube-dashboard.addons.k8s.io
    manifest: v1.6.0.yaml
    kubernetesVersion: ">=1.6.0"
    id: "k8s-16"
```

On kubernetes versions before 1.6, we will install `v1.5.0.yaml`, whereas from kubernetes
versions 1.6 on we will install `v1.6.0.yaml`.

Note that we remove the `pre-release` field of the kubernetes semver, so that `1.6.0-beta.1`
will match `>=1.6.0`.  This matches the way kubernetes does pre-releases.

## Semver is not enough: `id`

However, semver is insufficient here with the kubernetes version selection.  The problem
arises in the following scenario:

* Install k8s 1.5, 1.5 version of manifest is installed
* Upgrade to k8s 1.6, 1.6 version of manifest is installed
* Downgrade to k8s 1.5; we want the 1.5 version of the manifest to be installed but the 1.6 version
  will have a semver that is greater than or equal to the 1.5 semver.

We need a way to break the ties between the semvers, and thus we introduce the `id` field.

Thus a manifest will actually look like this:

```
  - version: 1.6.0
    selector:
      k8s-addon: kube-dns.addons.k8s.io
    manifest: pre-k8s-16.yaml
    kubernetesVersion: "<1.6.0"
    id: "pre-k8s-16"
 - version: 1.6.0
    selector:
      k8s-addon: kube-dns.addons.k8s.io
    manifest: k8s-16.yaml
    kubernetesVersion: ">=1.6.0"
    id: "k8s-16"
```

Note that the two addons have the same version, but a different `kubernetesVersion` selector.
But they have different `id` values; addons with matching semvers but different `id`s will
be upgraded.  (We will never downgrade to an older semver though, regardless of `id`)

So now in the above scenario after the downgrade to 1.5, although the semver is the same,
the id will not match, and the `pre-k8s-16` will be installed.  (And when we upgrade back
to 1.6, the `k8s-16` version will be installed.

A few tips:

* The `version` can now more closely mirror the upstream version.
* The manifest names should probably incorporate the `id`, for maintainability.
