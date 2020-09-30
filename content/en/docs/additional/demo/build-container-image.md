---
title: "9.9.1 Build a container image"
linkTitle: "Build image"
weight: 991
sectionnumber: 9.9.1
description: >
  This setion covers building a container image using a `Dockerfile`.
---

> This is a demo lab because your WEB-IDE does not contain the needed tools. Ask the moderator for a demo or install the tools on your computer.


## Task {{% param sectionnumber %}}.1: Build a container image

The build can be done using any container building tool that supports `Dockerfile` builds.

The sample application is an HTTP server written in the [Go programming language](https://golang.org/).

The following files are needed inside your application repository:

* [Dockerfile](#image-build-instruction)
* [main.go](#sample-go-application)


### Sample go application

This Go code defines an HTTP server listening on port 8080. It has to be placed in the `main.go` file.

```go
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", HelloServer)
    http.ListenAndServe(":8080", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
}
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/demo/main.go)

Calling this app will return "Hello," followed by the given path.

Examples:

| url | response |
| --- | --- |
| localhost:8080/ | Hello, ! |
| localhost:8080/world | Hello, world! |
| localhost:8080/appuio | Hello, appuio! |


### Image build instruction

The `Dockerfile` defines the image build ([Dockerfile reference](https://docs.docker.com/engine/reference/builder/)).

```Dockerfile
FROM registry.access.redhat.com/ubi8/go-toolset:1.13.4
COPY main.go /opt/app-root/src
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM registry.access.redhat.com/ubi8/ubi:8.2
RUN useradd -ms /bin/bash golang
RUN chgrp -R 0 /home/golang && \
    chmod -R g+rwX /home/golang
USER golang
COPY --from=0 /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
CMD /home/golang/go-hello-world-app
```

[source](https://raw.githubusercontent.com/puzzle/amm-techlab/master/content/en/docs/additional/demo/Dockerfile)

It is a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/). The build is done in several stages using different containers.

1. use a Go container to build the Go application
2. copy the go binary from the build to a minimal ubi image [Universal Base Image](https://developers.redhat.com/products/rhel/ubi)

{{% alert title="Note" color="primary" %}}
Multi-stage builds have two major advantages; smaller image size and higher security. The resulting image does only contain the minimal set of required packages. This reduces the image size and increases security (smaller attack surface).
{{% /alert %}}


### Image build

The image build is shown using [Buildah](https://github.com/containers/buildah). [Buildah](https://github.com/containers/buildah) - a tool that facilitates building [OCI](https://opencontainers.org/) container images.

Find [Docker](https://www.docker.com/) instructions hint at the bottom of this page or [here](docker-instructions/).

Buildah build command:

```bash
buildah bud -f Dockerfile -t go-hello-world .
```

The image is available locally:

```bash
buildah images
```

```
REPOSITORY                                    TAG      IMAGE ID       CREATED         SIZE
localhost/go-hello-world                      latest   7f3ed9de1e49   3 seconds ago   219 MB
registry.access.redhat.com/ubi8/ubi           8.2      7923da9ba983   6 days ago      212 MB
registry.access.redhat.com/ubi8/go-toolset    1.13.4   4bf10ac637aa   5 weeks ago     990 MB
```


### Image test

Test the container image locally using [Podman](https://podman.io/). Use this command to run the container:

```bash
podman run -p 8088:8080 -ti localhost/go-hello-world
```

This makes the Go application accessible by the port 8088 of your device.

It can be tested with a browser (<http://localhost:8088/world>) or using curl:

```bash
curl localhost:8088/world
```


### Publish image to Docker Hub

To make the image accessible to OpenShift, it must be pushed to an image registry. We use Docker Hub as the registry.

```bash
podman login
```

```bash
podman push localhost/go-hello-world:latest docker://docker.io/appuio/go-hello-world:latest
```
