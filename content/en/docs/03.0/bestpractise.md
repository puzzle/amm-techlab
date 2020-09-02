---
title: "3.4 Best practices"
linkTitle: "Best practices"
weight: 34
sectionnumber: 3.4
description: >
  Best practices for creating OpenShift containers.
---

## TODO

* [ ] Docker Befehle durch podman / buildah ersetzen


## Best practices for container in general

[Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)


### One process per container

It is recommended to start only one process per container. This simplifies the following things.

* Docker can recognize if your container failed and restart it if needed
* Reduce Image size and startup time
* Signal handling flows are clearer
* Reusable Images and looser coupling


### Instructions order

The order of the Docker instruction matters. When a single Layer becomes invalid, because of changing files or modifying lines in the Dockerfile, the subsequent layers become invalid too. As a rule of thumb: Order your steps from least to most frequently changing steps to optimize caching.

**Bad:**

```Dockerfile
FROM ubuntu
WORKDIR /home/me
COPY . src/
RUN apt get update && apt get install git openssh-client curl build-essential
```

In this case, every time your source code changed and you build the Image, all the Linux packages are installed again.

**Good:**

```Dockerfile
FROM ubuntu
WORKDIR /home/me
RUN apt get update && apt get install git openssh-client curl build-essential
COPY . src/
```

If you switch the RUN and COPY instructions, you only download the packages once. The layer is cached and will be reused for every further build.


### Use multistage build

To reduce the size of your image, you can use [Multi-Stage Builds](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#use-multi-stage-builds). As an example ew took the Go application from Chapter 2. Here is what a single stage Go build looks like:

```Dockerfile
FROM golang:1.14-alpine as builder
WORKDIR /opt/app-root/src
COPY main.go .
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .
```


In this example, you can see a two-layer build. The first layer (called builder) uses an alpine base Image with the Golang tools / libs. It is responsible for building the golang application. The second layer is based on the Docker Scratch Image. Scratch image is used for super minimal images that contain only a single binary.
At line 6 the compiled binary from the build stage is copied into the second stage. This ensures that we only copy the artifacts we need into the final image.

{{< highlight dockerfile "hl_lines=1 6 7" >}}
FROM golang:1.14-alpine as builder
WORKDIR /opt/app-root/src
COPY main.go .
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o go-hello-world-app .

FROM scratch
COPY --from=builder /opt/app-root/src/go-hello-world-app /home/golang/
EXPOSE 8080
CMD /home/golang/go-hello-world-app
{{< / highlight >}}


Let's check the difference. Enter the following command to list all local images.

```BASH
docker image ls
```


```
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
appuio/multi-stage      latest              3ac9ffdc7bcc        3 minutes ago       7.41MB
appuio/one-stage        latest              eaf0e3ea3a2a        4 minutes ago       404MB
```

Both images containing our sample Go application. But the difference in size is about 395MB!


It is also possible to make use of multi-stage builds in OpenShift.


## Best practices for creating OpenShift containers

[OpenShift Container Platform-specific guidelines](https://docs.openshift.com/container-platform/4.5/openshift_images/create-images.html#images-create-guide-openshift_create-images)

There are two options, on how to deploy and run Docker images on OpenShift

1. Use an OpenShift capable image
2. Extend your Docker image for OpenShift


### Root Users

By default, Docker containers run as `root` user. But container images which running under the root user, are not permitted in OpenShift clusters. (Except the Security Context Configuration allows it explicit)


### Random User IDs

Unlike Docker, OpenShift uses arbitrary assigned User IDs.
This requires the image to have set root group permissions on directories and files that may be written.
The directories and files must be owned by the root group and be read/writable by that group.
Files to be executed must also have root group execute permissions.

``` DOCKERFILE
RUN chgrp -R 0 /some/directory && \
    chmod -R g=u /some/directory
```

Find more information about this topic in the [OpenShift Guidelines](https://docs.openshift.com/container-platform/4.5/openshift_images/create-images.html#images-create-guide-openshift_create-images).


### Logging

Always log to standard out. This makes it easier to collect the logs from the container and send it to a centralized logging service.
