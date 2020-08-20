---
title: "3.3 OpenShift images"
linkTitle: "OpenShift images"
weight: 33
sectionnumber: 3.3
description: >
  This section is covering how to build a runnable image for OpenShift clusters.
---

## Application

We use the same Go application from Lab 2 and extend it with a log file. Every request is logged with the actual time and the client IP address. The log file is placed under `/home/golang/hello-go.log`

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

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/3.3/main.go)


## Dockerfile

The dockerfile is the same as in chapter 2.

``` dockerfile
FROM golang:1.14-alpine as builder
COPY main.go /opt/app-root/src
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM alpine
COPY --from=builder /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
ENTRYPOINT /home/golang/go-hello-world-app

```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/03.0/3.3/Dockerfile)


### Build

Let's build the image with following command:


```BASH
buildah bud -f Dockerfile -t go-hello-world-os .
```

Check if the image is available locally

```BASH
buildah images
```

```
REPOSITORY                                   TAG           IMAGE ID       CREATED         SIZE
localhost/go-hello-world-os                  latest        d51386c82b80   2 minutes ago   7.42 MB
localhost/go-hello-world                     latest        0493b6a22386   23 hours ago    218 MB
```


### Image test

Test the container image locally using Podman. Use this command to run the container:

```BASH
podman run -p 8082:8080 -ti go-hello-world-os
```

Be aware of the new allocated port! (8082)

```BASH
curl localhost:8082/world
```


### Publish image to Dockerhub


```BASH
podman push localhost/go-hello-world-os:latest docker://docker.io/appuio/go-hello-world.os:latest
```


## Deploy

Now it is time to deploy the image in our OpenShift cluster.

```BASH
oc new-app appuio/go-hello-world-os:latest
```

Verify if all resources are created

```BASH
oc get all
```

```
{{< highlight text "hl_lines=2 8" >}}
NAME                                     READY   STATUS             RESTARTS   AGE
pod/go-hello-world-os-576dcb6994-zjk58   0/1     CrashLoopBackOff   5          3m54s

NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/go-hello-world-os   ClusterIP   172.30.170.77   <none>        8080/TCP   3m55s

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/go-hello-world-os   0/1     1            0           3m55s

NAME                                           DESIRED   CURRENT   READY   AGE
replicaset.apps/go-hello-world-os-576dcb6994   1         1         0       3m54s
replicaset.apps/go-hello-world-os-5bc7bfc75d   1         0         0       3m55s

NAME                                               IMAGE REPOSITORY                                                                    TAGS     UPDATED
imagestream.image.openshift.io/go-hello-world-os   image-registry.openshift-image-registry.svc:5000/amm-cschlatter/go-hello-world-os   latest   3 minutes ago
{{< / highlight >}}
```

You can see that your Deployment isn't ready and the corresponding Pod has the status `CrashLoopBackOff`


## Troubleshoot

Let' figure out what happen.
First let's examine the Pods log

```BASH
oc logs go-hello-world-os-576dcb6994-zjk58
```

```
panic: open /home/golang/hello-go.log: permission denied

goroutine 1 [running]:
main.main()
  /opt/app-root/src/main.go:16 +0xdc

```

As we can see in the log, there is a permission denied error when we try to create our log file. The reason is because OpenShift will run by containers as non root user and we don't have permissions as non root user to write into the `/home/golang` directory.

So let us extend our `Dockerfile` with a specified user.


```
{{< highlight dockerfile  "hl_lines=6" >}}
FROM golang:1.14-alpine as builder
COPY main.go /opt/app-root/src
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM alpine
USER golang
COPY --from=builder /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
ENTRYPOINT /home/golang/go-hello-world-app
{{< / highlight >}}
```


```BASH
buildah bud -f Dockerfile -t go-hello-world-os .
```


```BASH
podman push localhost/go-hello-world-os docker://docker.io/appuio/go-hello-world.os:latest
```


```BASH
oc logs go-hello-world-os-576dcb6994-xwn6b
```


We still get same error.

```
panic: open /home/golang/hello-go.log: permission denied

goroutine 1 [running]:
main.main()
  /opt/app-root/src/main.go:16 +0xdc

```

So what is the reason for this? We already specified the `golang` user in the `Dockerfile`. So technically the user should have access to its own home directory. We need to fix the permissions for this particular user. Add following lines to your `Dockerfile`


```
{{< highlight dockerfile  "hl_lines=7-10" >}}
FROM golang:1.14-alpine
WORKDIR /opt/app-root/src
COPY main.go .
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM registry.access.redhat.com/ubi8/ubi:8.2
RUN useradd -ms /bin/bash golang
RUN chgrp -R 0 /home/golang && \
    chmod -R g+rwX /home/golang
USER golang
COPY --from=0 /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
ENTRYPOINT ["/home/golang/go-hello-world-app"]
{{< / highlight >}}
```

We add three additional command before the USER directive. First we run the `useradd` command to create a new user named golang. Next we add the home directory to the group 0 (root group) with the `chgrp` command. Last step is adding read/write/execute permission to the group. We do this with the `chmod` command. Now the application should be able to access the home directory and write the log file.

Let's build and deploy the app again.


```BASH
buildah bud -f Dockerfile -t go-hello-world-os .
```


```BASH
podman push localhost/go-hello-world-os docker://docker.io/appuio/go-hello-world.os:latest
```

```BASH
oc get pods
```


## Create route

```BASH
oc create route edge --service=go-hello
```

```BASH
oc get route
```
