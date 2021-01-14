---
title: "3.3.1 Debugging"
linkTitle: "3.3.1 Debugging"
weight: 331
sectionnumber: 3.3.1
description: >
  This lab shows how to debug applications and which tools are available.
---

## Task {{% param sectionnumber %}}.1: Prepare Test Application

First create a project called "debugbox-username".

```bash
oc new-project debugbox-username
```


### Deploy test application

A minimal container image is suitable for testing, e.g. a Go application in an empty file system (From scratch): [s3manager](https://quay.io/puzzle/s3manager:latest)

Create a new application from this image:

* Image: quay.io/puzzle/s3manager:latest
* Environment:
  * ACCESS_KEY_ID=something
  * SECRET_ACCESS_KEY=x

```bash
oc new-app -e ACCESS_KEY_ID=something -e SECRET_ACCESS_KEY=x quay.io/puzzle/s3manager:latest  --allow-missing-images
```

{{% alert  color="primary" %}} Since [OpenShift 4.5](https://docs.openshift.com/container-platform/4.5/release_notes/ocp-4-5-release-notes.html#ocp-4-5-developer-experience) `oc new-app` creates a Deployment not a DeploymentConfig. {{% /alert %}}


## Task {{% param sectionnumber %}}.2: Debugging with the oc tool

Try to open a remote shell in the container:

```bash
oc rsh deploy/s3manager
```

Error message:

```
ERRO[0000] exec failed: container_linux.go:349: starting container process caused "exec: \"/bin/sh\": stat /bin/sh: no such file or directory"
exec failed: container_linux.go:349: starting container process caused "exec: \"/bin/sh\": stat /bin/sh: no such file or directory"
command terminated with exit code 1
```

That didn't work because there is no shell in the container.

Can we at least spend the environment?

```bash
oc exec deploy/s3manager env
```

Error message:

```
time="2020-04-27T06:25:13Z" level=error msg="exec failed: container_linux.go:349: starting container process caused \"exec: \\\"env\\\": executable file not found in $PATH\""
exec failed: container_linux.go:349: starting container process caused "exec: \"env\": executable file not found in $PATH"
command terminated with exit code 1
```

This is also not possible, the env command is not available.

Even if we try to open the terminal in the web console, we get an error.

We cannot debug this container with the onboard equipment from OpenShift.
For this case, there is the [k8s-debugbox](https://github.com/puzzle/k8s-debugbox).
We use it in the next tasks to debug the application.


## Task {{% param sectionnumber %}}.3: Apply debug box

The [k8s-debugbox](https://github.com/puzzle/k8s-debugbox) has been developed for troubleshooting containers which are missing debugging tools.

The `k8s-debugbox` binary is available inside your ide.

Display the options using the help parameter.

```bash
k8s-debugbox -h
```

```
Debug pods based on minimal images.

Examples:
  # Open debugging shell for the first container of the specified pod,
  # install debugging tools into the container if they aren't installed yet.
  k8s-debugbox pod hello-42-dmj88

...

Options:
  -n, --namespace='': Namespace which contains the pod to debug, defaults to the namespace of the current kubectl context
  -c, --container='': Container name to open shell for, defaults to first container in pod
  -i, --image='puzzle/k8s-debugbox': Docker image for installation of debugging via controller. Must be built from 'puzzle/k8s-debugbox' repository.
  -h, --help: Show this help message
      --add: Install debugging tools into specified resource
      --remove: Remove debugging tools from specified resource

Usage:
  k8s-debugbox TYPE NAME [options]
```

We use the debug box on the s3manager Pod:

**Tip to get the pod:** `oc get pods`

```bash
k8s-debugbox pod s3manager-1-jw4sl
```

```
Uploading debugging tools into pod s3manager-1-hnb6x
time="2020-04-27T06:26:44Z" level=error msg="exec failed: container_linux.go:349: starting container process caused \"exec: \\\"tar\\\": executable file not found in $PATH\""
exec failed: container_linux.go:349: starting container process caused "exec: \"tar\": executable file not found in $PATH"
command terminated with exit code 1

Couldn't upload debugging tools!
Instead you can patch the controller (deployment, deploymentconfig, daemonset, ...) to use an init container with debugging tools, this requires a new deployment though!
```

This attempt also fails because the tools cannot be copied into the container without tar. However, we have received information from the debug box that we should do the installation via deployment.
The deployment is expanded with an init container. The init container copies the tools into a volume, which can then be used by the s3manager container.

Patching the deployment:

```bash
k8s-debugbox deploy s3manager
```

Here is the init container extract from the patched deployment:

```yaml
spec:
  template:
    spec:
      initContainers:
      - image: puzzle/k8s-debugbox
        name: k8s-debugbox
        volumeMounts:
        - mountPath: /tmp/box
          name: k8s-debugbox
```

After another deployment of the pod, we are in a shell in the container. We have a variety of tools at our disposal. Now we can do the debugging.

Where are the debugging tools located?

```bash
/tmp/box/bin/
```


**Tip** By entering `exit` we end the debug box.

How can we undo the changes to the Deployment?

```bash
k8s-debugbox deploy s3manager --remove
```
