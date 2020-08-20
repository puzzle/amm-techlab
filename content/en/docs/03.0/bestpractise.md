---
title: "3.4 Best practices"
linkTitle: "Best practices"
weight: 34
sectionnumber: 3.4
description: >
  Best practices for creating OpenShift containers.
---

## Best practices for container in general

[Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)


### One process per container

It is recommended to start only one process per container .This simplifies several things.

* Docker can recognize if your container failed
* Reduce Image size and startup time
* Signal handling flows are clearer
* Reusable Images and looser coupling


### Instructions order


Bad:

```Dockerfile
FROM ubuntu
WORKDIR /home/me
COPY . src/
RUN apt get update && apt get install git openssh-client curl build-essential
```

In this case every time your source code changed and you build the Image, all the linux packages are installed again.

Good:

```Dockerfile
FROM ubuntu
WORKDIR /home/me
RUN apt get update && apt get install git openssh-client curl build-essential
COPY . src/

```

If you switch the RUN and COPY instructions, you only download the packages once. The layer is cached and will be reused for every further build.


### Use multistage build

To reduce the size of your Image, you can use [Multi-Stage Builds](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#use-multi-stage-builds). For example a multi stage build for a Go application look like follow:


```
{{< highlight dockerfile "hl_lines=1 5 6" >}}
FROM golang:1.14-alpine as builder
COPY main.go /opt/app-root/src
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM scratch
COPY --from=builder /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
CMD /home/golang/go-hello-world-app

{{< / highlight >}}
```

In this example you can see a two layer build. The first layer (called builder) uses a alpine base Image with the Golang tools / libs. It is responsible for building the golang application. The second layer is based on the Docker Scratch Image. Scratch image is used for super minimal Images that contain only a single binary.
At line 6 the compiled binary from the build stage is copied into the second stage. This ensures that we only copy the artifacts we need into the final Image.

It is also possible to make use of multi-stage builds in OpenShift.


## Best practices for creating OpenShift containers

[OpenShift Container Platform-specific guidelines](https://docs.openshift.com/container-platform/4.5/openshift_images/create-images.html#images-create-guide-openshift_create-images)

There are two options, how to deploy and run Docker images on OpenShift

1. Use an OpenShift capable Image
2. Extend your Docker Image for OpenShift


### Root Users

By default Docker containers run as `root` user. But container Images which running under root user, are not permitted in OpenShift clusters. (Except the Security Context Configuration is allowing it explicit)


### Random User IDs

Unlike Docker, OpenShift uses arbitrary assigned User IDs.  
For an image to support running as an arbitrary user, directories and files that may be written to by processes in the image should be owned by the root group and be read/writable by that group. Files to be executed should also have group execute permissions.

``` DOCKERFILE
RUN chgrp -R 0 /some/directory && \
    chmod -R g=u /some/directory
```

Find more information about this topic in the [OpenShift Guidelines](https://docs.openshift.com/container-platform/3.11/creating_images/guidelines.html#openshift-specific-guidelines).


### Logging

Always log to standard out. This makes it easier to collect the logs from the container and send it to an centralized logging service.