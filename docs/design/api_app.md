# Rancher Desktop Application API

The `App` object is part of the `app.rancherdesktop.io` API group.

## App Components

### Singleton

There can be only a single `App` object in an RDD instance.

Both the [rdd create](cmd_app.md#rdd-create) command and the [GUI](gui.md) app create the `App` object in the "app-namespace", which is a configuration setting stored in the `config` ConfigMap in the `rdd-system` namespace (`rancher-desktop` by default)[^hardcoded].

[^hardcoded]: The "app-namespace" is only configurable so that it can be tested that the namespace isn't hardcoded anywhere in the controller.

Multiple versions of "Rancher Desktop 2" can be run in parallel by using different RDD instances, e.g.

```shell
RDD_INSTANCE=test rdd start --kube-version=1.35.1
```

The GUI will still be a system-wide singleton and only communicate with the `App` in a single RDD instance at a time. It _may_ support a submenu in the notification icon to switch between RDD instances.

### Lima VM

The `App` will create a `LimaDisk` and have it automatically mounted on a `LimaVM`.

#### Instance name

The `LimaVM` instance name is **always** `rd`. That means the Lima instance directory will be `~/.rd2/lima/rd`.

#### Data Disk

All user data is stored on the `LimaDisk`. Which means all images and also all local-path-storage.

Lightweight app snapshots only copy this data disk, and not the full VM image.

### Docker and Kube Contexts

When the `App` is starting it creates the Docker context and sets up the kubeconfig in `~/.kube/config`.

It will only change the current context if it does not exist, or is not working at the time the app is starting.

The kube config is also written to `~/.rd2/kube.config` (mostly for the [`rdd run`](cmd_app.md#rdd-run) command).

Consider using `cliPluginsExtraDirs` in `~/.docker/config.json` instead of installing into `~/.docker/cli-plugins` and have a diagnostic if the plugins exist in `~/.docker/cli-plugins`? The mechanism should be compatible with whatever we do on Windows.

## App object

### Example

```yaml
apiVersion: app.rancherdesktop.io/v1alpha1
kind: App
metadata:
  name: rancher-desktop
  namespace: rancher-desktop
spec:
  containerEngine:
    name: moby
  kubernetes:
    version: 1.30.0
  status: running
  dryRun: false
status:
  appVersion: 2.0.0
  onlineStatus: true
  status: starting
  progress: "Downloading Kubernetes 1.30.0"
```

### `spec`

The `spec` has all the usual fields that are in `settings.json` in "Rancher Desktop 1.x".

The following fields have a special purpose:

#### `status`

The `status` field is set to the desired state of the VM: `running` or `stopped`. The controller will update the `spec.status` field of the `LimaVM` object to match.

#### `dryRun`

The `dryRun` field can be set to `true` to validate a proposed settings change without actually committing it (for the Preferences dialog). When `dryRun` is set, then the admission controller will always reject the change request, but the error will be "settings valid" when no actual error is detected.

## GUI

How the GUI uses the App object:

### Status Bar

The status bar is updated with the information from the `spec` (e.g. container engine, Kubernetes version) and `status` (e.g. online status, progress indicator) parts of the `App` object
