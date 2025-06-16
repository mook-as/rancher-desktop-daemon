# Lima Commands

## `rdd lima`

This command is similar to `limactl`, but uses `rdd` to create/start/stop/delete VM instances. It is a convenience command to work with other VMs and not needed to operate the Rancher Desktop app.

```bash
rdd lima create --name my-vm --cpus 4 lima.yaml
rdd lima start my-vm
rdd lima stop my-vm
rdd lima delete my-vm
rdd lima shell my-vm
```
