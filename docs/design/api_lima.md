# Lima API

The `lima.rancherdesktop.io` API group includes resources managed by Lima, including `LimaVM`, `LimaDisk`, and `LimaNetwork`.

## LimaVM

A `LimaVM` resource represents a VM managed by this `rdd` instance.

`LimaVM` resources can be created in different namespaces, but the VM names must be unique across the whole `rdd` instance.

Grouping VMs in namespace is useful for creating snapshots of related VMs, and for managing the lifecycle to stop pr delete all VMs inside a namespace.

### Example `LimaVM` object

```yaml
apiVersion: lima.rancherdesktop.io/v1alpha1
kind: LimaVM
metadata:
  name: alpine
  namespace: default
spec:
  template: alpine
  status: running
status:
  status: stopped
```

The `template` specifies a ConfigMap that contains the `lima.yaml` template for the machine. It must be "fully embedded"; it cannot reference external base templates or scripts.

## LimaDisk

While a `LimaVM` object is specific to an OS, a `LimaDisk` object is just an `ext4` filesystem that can be copied between host operating systems. (Needs verification!)

## LimaNetwork

TBD
