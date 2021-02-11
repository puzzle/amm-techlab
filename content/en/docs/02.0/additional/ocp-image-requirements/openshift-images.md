---
title: "2.3.1 OpenShift image requirements"
linkTitle: "2.3.1 OpenShift image requirements"
weight: 231
sectionnumber: 2.3.1
description: >
  This section is covering how to build a runnable image for OpenShift clusters.
---


## Task {{% param sectionnumber %}}.1: Additional requirements

OpenShift has additional security features enabled in comparison to Docker or a vanilla Kubernetes plattform.
The most relevant mechanism are prevention of root user, [SELinux](https://de.wikipedia.org/wiki/SELinux) enabled and arbitrary user ids.

This adds additional requirements to the container images that will be deployed to OpenShift. This lab shows how to deal with them.


## Task {{% param sectionnumber %}}.2: Demo application

We use a Go application running a HTTP server listening on port 8080. Every request is logged with the actual time and the client IP address. The log file is placed under `/home/golang/hello-go.log`.

This writing to a file helps us testing file access and write permissions inside a container.

{{% alert  color="primary" %}} Writing logs to a file is not a good thing in the container world. Logs have to be treated as streams and written to standard out. {{% /alert %}}


### Go source

``` golang
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
  "path/filepath"
  "time"
)

var logFile = "/home/golang/hello-go.log"

func main() {

  _, err := createFile(logFile)
  if err != nil {
    panic(err)
  }

  http.HandleFunc("/", HelloServer)
  http.ListenAndServe(":8080", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
  appendToFile(r.RemoteAddr)
}

func createFile(p string) (*os.File, error) {
  if err := os.MkdirAll(filepath.Dir(p), 0644); err != nil {
    return nil, err
  }
  return os.Create(p)
}

func appendToFile(remoteAddr string) {
  f, err := os.OpenFile(logFile, os.O_APPEND|os.O_WRONLY, 0644)
  if err != nil {
    log.Println(err)
  }
  defer f.Close()

  line := fmt.Sprintf("%s: Request from: %s\n", time.Now().String(), remoteAddr)

  if _, err := f.WriteString(line); err != nil {
    log.Println(err)
  }
}
```

[source](https://raw.githubusercontent.com/chrira/container-openshift-ifie/master/main.go)


### Dockerfile

The Dockerfile defines a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/). The build is done in several stages using different containers.

1. use a Go container to build the Go application
2. copy the go binary from the build to a minimal alpine image

``` dockerfile
FROM golang:1.14-alpine as builder
COPY main.go /opt/app-root/src
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM alpine
COPY --from=builder /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
ENTRYPOINT /home/golang/go-hello-world-app
```

[source](https://raw.githubusercontent.com/chrira/container-openshift-ifie/master/Dockerfile)


## Task {{% param sectionnumber %}}.3: Deploy application

The application is available on Docker Hub: [chrira/container-openshift-ifie](https://hub.docker.com/repository/docker/chrira/container-openshift-ifie)

This is a list with all needed OpenShift resources.

{{< highlight yaml >}}{{< readfile file="content/en/docs/02.0/additional/ocp-image-requirements/application-infrastructure.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/additional/ocp-image-requirements/application-infrastructure.yaml)


Now it is time to deploy the image in our OpenShift cluster.

```BASH
oc apply -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/additional/ocp-image-requirements/application-infrastructure.yaml
```

```
imagestream.image.openshift.io/container-openshift-ifie created
deploymentconfig.apps.openshift.io/container-openshift-ifie created
service/container-openshift-ifie created
```

Verify if all resources are created

```BASH
oc get all
```

```
{{< highlight text "hl_lines=2 6" >}}
NAME                                        READY   STATUS             RESTARTS   AGE
pod/container-openshift-ifie-1-d8rln        0/1     CrashLoopBackOff   6          9m19s
pod/container-openshift-ifie-1-deploy       1/1     Running            0          9m22s

NAME                                               DESIRED   CURRENT   READY   AGE
replicationcontroller/container-openshift-ifie-1   1         1         0       9m22s

NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/container-openshift-ifie   ClusterIP   172.30.40.136    <none>        8080/TCP            9m22s

NAME                                                          REVISION   DESIRED   CURRENT   TRIGGERED BY
deploymentconfig.apps.openshift.io/container-openshift-ifie   1          1         1         config
{{< / highlight >}}
```

You can see that your Deployment isn't ready and the corresponding Pod has the status `CrashLoopBackOff`


### Troubleshoot

Let' figure out what happened.
First let's examine the Pods log

```BASH
oc logs container-openshift-ifie-1-d8rln
```

```
panic: open /home/golang/hello-go.log: permission denied

goroutine 1 [running]:
main.main()
        /opt/app-root/src/main.go:18 +0x126
```

As we can see in the log, there is a permission denied error when we try to create our log file. The reason is because OpenShift will run by containers as non root user and we don't have permissions as non root user to write into the `/home/golang` directory.


## Task {{% param sectionnumber %}}.4: Add a user to the container

So let us extend the image with a specified user.

For that we add a BuildConfiguration with a new Dockerfile extending the used image.

{{< highlight yaml "hl_lines=47-49" >}}{{< readfile file="content/en/docs/02.0/additional/ocp-image-requirements/buildconfig.yaml" >}}{{< /highlight >}}

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/additional/ocp-image-requirements/buildconfig.yaml)

Create BuildConfiguration:

```BASH
oc apply -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/additional/ocp-image-requirements/buildconfig.yaml
```

```
imagestream.image.openshift.io/container-openshift-ifie-original created
buildconfig.build.openshift.io/container-openshift-ifie created
```

We do not have trigger, start the build manually:

```BASH
oc start-build container-openshift-ifie
```

```
build.build.openshift.io/container-openshift-ifie-1 started
```

We still get same error.

```
panic: open /home/golang/hello-go.log: permission denied

goroutine 1 [running]:
main.main()
  /opt/app-root/src/main.go:18 +0x126
```

So what is the reason for this? We already specified the `golang` user in the `Dockerfile`. So technically the user should have access to its own home directory. Even if we specify a user with the USER directive in a Dockerfile, OpenShift is going to ignore it. We need to fix the permissions for this particular user.


## Task {{% param sectionnumber %}}.5: Fix permissions

Even if we specify a user with the USER directive in a Dockerfile, OpenShift is going to ignore it. It starts the container with an arbitrary userID and group 0 (root group).
We need to extend the `Dockerfile` to give group 0 access.

```
{{< highlight dockerfile  "hl_lines=2-4" >}}
FROM chrira/container-openshift-ifie:latest
RUN chgrp -R 0 /home/golang && \
    chmod -R g+rwX /home/golang
USER golang
{{< / highlight >}}
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/additional/ocp-image-requirements/buildconfig-permissions.yaml)

We add additional commands before the USER directive. First we add the home directory to the group 0 (root group) with the `chgrp` command. Last step is adding read/write/execute permission to the group. We do this with the `chmod` command. Now the application should be able to access the home directory and write the log file.


Let's update the BuildConfiguration and build and deploy the app again.

```BASH
oc apply -f https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/02.0/additional/ocp-image-requirements/buildconfig-permissions.yaml
```

```BASH
oc start-build container-openshift-ifie
```

```BASH
oc get pods
```


## Create route

```BASH
oc create route edge --service=container-openshift-ifie
```

```BASH
oc get route
```
